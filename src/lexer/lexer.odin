package lexer

import "core:mem/virtual"
import "core:strings"

import "pinky:token"

Tokenize_Error :: enum {
    None,
    UnclosedString,
    MalformedFloat,
    UnexpectedEOF,
}

// The returned string is static and should be deallocated
tokenize_error_to_string :: proc(te: Tokenize_Error) -> (s: string) {
    switch te {
    case .None: s = "None"
    case .MalformedFloat: s = "Missing digits '[0-9]+' after '[0-9]\\.'"
    case .UnclosedString: s = "Missing ''' while lexing string (unclosed string)"
    case .UnexpectedEOF: s = "Hit unexpectedly End Of File while lexing"
    }
    return 
}



tokenize :: proc(source: []u8, lexer_arena: ^virtual.Arena) -> ([dynamic]token.Token, Tokenize_Error) {
    arena_allocator := virtual.arena_allocator(lexer_arena)
    context.allocator = arena_allocator

    lexer := &Lexer{
        source = source,
        line = 1,
        start = 0,
        current = 0,
    }
    
    tokens := make([dynamic]token.Token) 
    err: Tokenize_Error = .None
    encountered_error := false

    if encountered_error {
        clear(&tokens)
    }

    loop: for !is_eof(lexer) {
        lexer.start = lexer.current
        ch := advance(lexer) 
        token_type: token.Token_Type

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
        case '*': token_type = .Star
        case '/': token_type = .Slash
        case '^': token_type = .Caret
        case '%': token_type = .Mod
        case '?': token_type = .Question
        case ';': token_type = .Semicolon
        case '-':
            if match(lexer, '-') {
                is_not_newline :: proc(ch: u8) -> bool { return ch != '\n' }
                advance_until(lexer, is_not_newline)
                continue loop
            }
            token_type = .Minus
        case ':': token_type = match(lexer, '=') ? .Assign : .Colon
        case '~': token_type = match(lexer, '=') ? .Ne : .Not
        case '=': token_type = match(lexer, '=') ? .EqEq : .Eq
        case '>':
            if match(lexer, '=') do token_type = .Ge
            else if match(lexer, '>') do token_type = .GtGt
            else do token_type = .Gt
        case '<':
            if match(lexer, '=') do token_type = .Le
            else if match(lexer, '<') do token_type = .LtLt
            else do token_type = .Lt

        case '\n':
            lexer.line += 1
            fallthrough
        case '\t', ' ':
            continue loop

        case '0'..='9':
            token_type = .Integer
            advance_until(lexer, is_digit)

            if match(lexer, '.') {
                if is_digit(peek(lexer)) {
                    token_type = .Float
                    advance_until(lexer, is_digit)
                } else {
                    encountered_error = true
                    err = .MalformedFloat
                    break loop
                }
            }

        case 34: // bug in odin-mode, '"' break all the higlighting
            token_type = .String
            is_not_closing_double_quote :: proc(ch: u8) -> bool { return ch != 34 }
            advance_until(lexer, is_not_closing_double_quote)
            lexer.current += 1
            if is_eof(lexer) && lexer.source[lexer.current - 1] != 34 { // '"'
                encountered_error = true
                err = .UnclosedString
                break loop
            }

        case:
            token_type = .Identifier
            is_valid_character_for_identifier :: proc(ch: u8) -> bool {
               return ch >= 'a' && ch <= 'z' || ch >= 'A' && ch <= 'Z' || ch >= '0' && ch <= '9' || ch == '_' 
            }
            advance_until(lexer, is_valid_character_for_identifier)
        }

        tok := token.Token{
            token_type = token_type,
            lexeme = strings.clone_from_bytes(lexer.source[lexer.start:lexer.current]),
            line = lexer.line,
        }

        if token_type == .Identifier {
            trasform_in_keyword_if_needed(&tok)
        }

        append(&tokens, tok)
    }

    if encountered_error {
        clear(&tokens)
    }

    return tokens, err
}
