package lexer

import "../token"

import "core:fmt"

Lexer :: struct {
    source: []u8,
    line: int,
    start: int,
    current: int,
}

new_lexer :: proc(source: []u8) -> Lexer {
    return {
        source = source,
        line = 1,
        start = 0,
        current = 0,
    }
}

peek :: proc(lexer: ^Lexer) -> u8 {
    using lexer
    return source[current]
}

is_eof :: proc(lexer: ^Lexer) -> bool {
    using lexer
    return current >= len(source)
}

match :: proc(lexer: ^Lexer, expected: u8) -> bool {
    using lexer
    if source[current] != expected {
        return false
    }
    current += 1
    return true
}

advance :: proc(lexer: ^Lexer) -> u8 {
    using lexer
    ch := source[current]
    current += 1
    return ch
}

advance_until :: proc(lexer: ^Lexer, predicate: proc(ch: u8) -> bool) {
    using lexer
    for current < len(source) && predicate(source[current]) {
        current += 1
    }
} 

lookahead :: proc(lexer: ^Lexer, n: int = 1) -> Maybe(u8) {
    using lexer
    if current + n >= len(source) {
        return nil
    }
    return source[current + n]
}

is_digit :: proc(ch: u8) -> bool {
    return ch >= '0' && ch <= '9'
}

tokenize :: proc(lexer: ^Lexer) -> [dynamic]token.Token {
    tokens := make([dynamic]token.Token) 
    encountered_error := false
    column_index := 0
    defer {
        lexer.line = 1
        lexer.start = 0
        lexer.current = 0
    }

    if encountered_error {
        clear(&tokens)
    }

    loop: for !is_eof(lexer) {
        column_index += 1
        lexer.start = lexer.current
        ch := advance(lexer) 
        token_type: token.Token_Type
        last: Maybe(int) = nil

        switch ch {
        case '(': token_type = .LeftParen
        case ')': token_type = .RightParen
        case '{': token_type = .LeftCurly
        case '}': token_type = .RightCurly
        case '[': token_type = .LeftSquare
        case ']': token_type = .RightSquare
        case ',': token_type = .Comma
        case '.': token_type = .Dot
        case '+': token_type = .Plus
        case '-': token_type = .Minus
        case '*': token_type = .Star
        case '/': token_type = .Slash
        case '^': token_type = .Caret
        case '%': token_type = .Mod
        case '?': token_type = .Question
        case ';': token_type = .Semicolon
        case ':': token_type = match(lexer, '=') ? .Assign : .Colon
        case '~': token_type = match(lexer, '=') ? .Ne : .Not
        case '=': 
            if !match(lexer, '=') {
                fmt.eprintf("Expected '=' after '='.") 
                encountered_error = true
                break loop
            }
        case '>':
            if match(lexer, '=') do token_type = .Ge
            else if match(lexer, '>') do token_type = .GtGt
            else do token_type = .Gt
        case '<':
            if match(lexer, '=') do token_type = .Le
            else if match(lexer, '<') do token_type = .LtLt
            else do token_type = .Lt

        case '\n':
            column_index = 0
            lexer.line += 1
            fallthrough
        case '\t', ' ':
            continue loop

        case '0'..='9':
            token_type = .Integer
            advance_until(lexer, is_digit)

            if match(lexer, '.') {
                if is_digit(lookahead(lexer).? or_else 0) {
                    token_type = .Float
                    lexer.current += 1 
                    advance_until(lexer, is_digit)
                } else {
                    fmt.eprintf("Error parsing a Float, expected <numbers> after '.'")
                    encountered_error = true
                    break loop
                }
            }

            /* last = lexer.current */

        case 34: // bug in odin-mode, '"' break all the higlighting
            token_type = .String
            not_is_closing_double_quote :: proc(ch: u8) -> bool { return ch != 34 }
            advance_until(lexer, not_is_closing_double_quote)
            lexer.current += 1
        }

        tok := token.Token{
            token_type = token_type,
            lexeme = lexer.source[lexer.start:last.? or_else lexer.current],
        }

        append(&tokens, tok)
    }

    if encountered_error {
        fmt.eprintf("Encountered an error while lexing\n")
        fmt.eprintf("At line <%d>, column <%d>\n", lexer.line, column_index)
        fmt.eprintf("At byte offset in source := <%d>\n", lexer.current)
        if lexer.current < len(lexer.source) {
            fmt.eprintf("At the character := <%c>\n", lexer.source[lexer.current])
        } else {
            fmt.eprintf("At the EOF\n")
        }
        clear(&tokens)
    }

    return tokens
}
