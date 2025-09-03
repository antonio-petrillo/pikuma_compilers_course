#+private
package lexer

import "pinky:token"

Lexer :: struct {
    source: []u8,
    line: int,
    start: int,
    current: int,
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


trasform_in_keyword_if_needed :: proc(tok: ^token.Token) {
    size := len(tok.lexeme)
    switch tok.lexeme[0] {
    case 'i':  
        if size == 2 && tok.lexeme[1] == 'f' {
            tok.token_type = .If
        }
    case 't':
        if size != 4 {
            return
        }
        if tok.lexeme == "true" {
            tok.token_type = .True
        } else if tok.lexeme == "then" {
            tok.token_type = .Then
        }
    case 'e':
        if size == 4 && tok.lexeme == "else" {
            tok.token_type = .Else
        }
        if size == 3 && tok.lexeme == "end" {
            tok.token_type = .End
        }
    case 'f':
        if size == 5 && tok.lexeme == "false" {
           tok.token_type = .False 
        }
        if size == 4 && tok.lexeme == "func" {
           tok.token_type = .Func
        }
        if size == 3 && tok.lexeme == "for" {
           tok.token_type = .For
        }
    case 'a':
        if size == 3 && tok.lexeme == "and" {
            tok.token_type = .And
        }
    case 'o':
        if size == 2 && tok.lexeme == "or"  {
            tok.token_type = .Or
        }
    case 'w':
        if size == 5 && tok.lexeme == "while" {
            tok.token_type = .While
        }
    case 'd':
        if size == 2 && tok.lexeme == "do" {
            tok.token_type = .Do
        }
    case 'n':
        if size == 4 && tok.lexeme == "null" {
            tok.token_type = .Null
        }
    case 'p':
        if size == 5 && tok.lexeme == "print" {
            tok.token_type = .Print
        }
        if size == 7 && tok.lexeme == "println" {
            tok.token_type = .Println
        }
    case 'r':
        if size == 3 && tok.lexeme == "ret" {
            tok.token_type = .Ret
        }
    }
}
