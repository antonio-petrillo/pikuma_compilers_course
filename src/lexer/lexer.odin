package lexer

import "core:slice"

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
    return lexer.source[lexer.current]
}

is_eof :: proc(lexer: ^Lexer) -> bool {
    return lexer.current >= len(lexer.source)
}

match :: proc(lexer: ^Lexer, expected: u8) -> bool {
    if is_eof(lexer) || lexer.source[lexer.current] != expected {
        return false
    }
    lexer.current += 1
    return true
}

advance :: proc(lexer: ^Lexer) -> u8 {
    ch := lexer.source[lexer.current]
    lexer.current += 1
    return ch
}

advance_until :: proc(lexer: ^Lexer, predicate: proc(ch: u8) -> bool) {
    for lexer.current < len(lexer.source) && predicate(lexer.source[lexer.current]) {
        lexer.current += 1
    }
} 

lookahead :: proc(lexer: ^Lexer, n: int = 1) -> Maybe(u8) {
    if lexer.current + n >= len(lexer.source) {
        return nil
    }
    return lexer.source[lexer.current + n]
}

is_digit :: proc(ch: u8) -> bool {
    return ch >= '0' && ch <= '9'
}

Tokenize_Error :: enum {
    None,
    MalformedEqual,
    UnclosedString,
    MalformedFloat,
    UnexpectedEOF,
    
}

tokenize_error_to_string :: proc(te: Tokenize_Error) -> (s: string) {
    switch te {
    case .None: s = "None"
    case .MalformedEqual: s = "Missing '=' after '=' (malformed '==')"
    case .MalformedFloat: s = "Missing digits '[0-9]+' after '[0-9]\\.'"
    case .UnclosedString: s = "Missing ''' while lexing string (unclosed string)"
    case .UnexpectedEOF: s = "Hit unexpectedly End Of File while lexing"
    }
    return 
}

tokenize :: proc(lexer: ^Lexer) -> ([dynamic]Token, Tokenize_Error) {
    tokens := make([dynamic]Token) 
    err: Tokenize_Error = .None
    encountered_error := false
    defer {
        lexer.line = 1
        lexer.start = 0
        lexer.current = 0
    }

    if encountered_error {
        clear(&tokens)
    }

    loop: for !is_eof(lexer) {
        lexer.start = lexer.current
        ch := advance(lexer) 
        token_type: Token_Type

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
        case '=': 
            if !match(lexer, '=') {
                encountered_error = true
                err = .MalformedEqual
                break loop
            }
            token_type = .Eq
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

        tok := Token{
            token_type = token_type,
            lexeme = lexer.source[lexer.start:lexer.current],
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

trasform_in_keyword_if_needed :: proc(tok: ^Token) {
    size := len(tok.lexeme)
    switch tok.lexeme[0] {
    case 'i':  
        if size == 2 && tok.lexeme[1] == 'f' {
            tok.token_type = .If
        }
    case 't':
        if size == 4 && slice.simple_equal(tok.lexeme, []u8{'t', 'r', 'u', 'e'}) {
            tok.token_type = .True
        }
        if size == 4 && slice.simple_equal(tok.lexeme, []u8{'t', 'h', 'e', 'n'}) {
            tok.token_type = .Then
        }
    case 'e':
        if size == 4 && slice.simple_equal(tok.lexeme, []u8{'e', 'l', 's', 'e'}) {
            tok.token_type = .Else
        }
        if size == 3 && slice.simple_equal(tok.lexeme, []u8{'e', 'n', 'd'}) {
            tok.token_type = .End
        }
    case 'f':
        if size == 5 && slice.simple_equal(tok.lexeme, []u8{'f', 'a', 'l', 's', 'e'}) {
           tok.token_type = .False 
        }
        if size == 4 && slice.simple_equal(tok.lexeme, []u8{'f', 'u', 'n', 'c'}) {
           tok.token_type = .Func
        }
        if size == 3 && slice.simple_equal(tok.lexeme, []u8{'f', 'o', 'r'}) {
           tok.token_type = .For
        }
    case 'a':
        if size == 3 && slice.simple_equal(tok.lexeme, []u8{'a', 'n', 'd'}) {
            tok.token_type = .And
        }
    case 'o':
        if size == 2 && tok.lexeme[1] == 'r' {
            tok.token_type = .Or
        }
    case 'w':
        if size == 5 && slice.simple_equal(tok.lexeme, []u8{'w', 'h', 'i', 'l', 'e'}) {
            tok.token_type = .While
        }
    case 'd':
        if size == 2 && tok.lexeme[1] == 'o' {
            tok.token_type = .Do
        }
    case 'n':
        if size == 4 && slice.simple_equal(tok.lexeme, []u8{'n', 'u', 'l', 'l'}) {
            tok.token_type = .Null
        }
    case 'p':
        if size == 5 && slice.simple_equal(tok.lexeme, []u8{'p', 'r', 'i', 'n', 't'}) {
            tok.token_type = .Print
        }
        if size == 7 && slice.simple_equal(tok.lexeme, []u8{'p', 'r', 'i', 'n', 't', 'l', 'n'}) {
            tok.token_type = .Println
        }
    case 'r':
        if size == 3 && slice.simple_equal(tok.lexeme, []u8{'r', 'e', 't'}) {
            tok.token_type = .Ret
        }
    }
}
