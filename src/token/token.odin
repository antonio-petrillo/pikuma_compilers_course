package token

import "core:fmt"
import "core:slice"
import "core:strings"

Token_Type :: enum {
    LeftParen, RightParen, // '(', ')'
    LeftCurly, RightCurly, // '{', '}'
    LeftSquare, RightSquare, // '[', ']'

    Comma, Dot, // ',', '.'
    Plus, Minus, Star, Slash, Caret, Mod, // '+', '-', '*', '/', '^', '%'
    Colon, Semicolon, // ':', ';'

    Question, // '?'
    Not, Gt, Lt, // '~', '>', '<'

    Ne, Ge, Le, // '~=', '>=', '<='
    Eq, Assign, // '==', ':='
    GtGt, LtLt, // '>>', '<<'

    Identifier,
    String,
    Integer,
    Float,

    If, Then, Else,
    True, False,
    And, Or,
    While,
    Do,
    For,
    Func,
    Null,
    End,
    Print,
    Println,
    Ret,
}


token_type_to_string :: proc(tt: Token_Type) -> (s: string) {
    switch tt {
    case .LeftParen: s = "TOK_LEFTPAREN"
    case .RightParen: s = "TOK_RIGHTPAREN"
    case .LeftCurly: s = "TOK_LEFTCURLY"
    case .RightCurly: s = "TOK_RIGHTCURLY"
    case .LeftSquare: s = "TOK_LEFTSQUARE"
    case .RightSquare: s = "TOK_RIGHTSQUARE"
    case .Comma: s = "TOK_COMMA"
    case .Dot: s = "TOK_DOT,"
    case .Plus: s = "TOK_PLUS"
    case .Minus: s = "TOK_MINUS"
    case .Star: s = "TOK_STAR"
    case .Slash: s = "TOK_SLASH"
    case .Caret: s = "TOK_CARET"
    case .Mod: s = "TOK_MOD"
    case .Colon: s = "TOK_COLON"
    case .Semicolon: s = "TOK_SEMICOLON"
    case .Question: s = "TOK_QUESTION"
    case .Not: s = "TOK_NOT"
    case .Gt: s = "TOK_GT"
    case .Lt: s = "TOK_LT"
    case .Ne: s = "TOK_NE"
    case .Ge: s = "TOK_GE"
    case .Le: s = "TOK_LE"
    case .Eq: s = "TOK_EQ"
    case .Assign: s = "TOK_ASSIGN"
    case .GtGt: s = "TOK_GTGT"
    case .LtLt: s = "TOK_LTLT"
    case .Identifier: s = "TOK_IDENTIFIER"
    case .String: s = "TOK_STRING"
    case .Integer: s = "TOK_INTEGER"
    case .Float: s = "TOK_FLOAT"
    case .If: s = "TOK_IF"
    case .Then: s = "TOK_THEN"
    case .Else: s = "TOK_ELSE"
    case .True: s = "TOK_TRUE"
    case .False: s = "TOK_FALSE"
    case .And: s = "TOK_AND"
    case .Or: s = "TOK_OR"
    case .While: s = "TOK_WHILE"
    case .Do: s = "TOK_DO"
    case .For: s = "TOK_FOR"
    case .Func: s = "TOK_FUNC"
    case .Null: s = "TOK_NULL"
    case .End: s = "TOK_END"
    case .Print: s = "TOK_PRINT"
    case .Println: s = "TOK_PRINTLN"
    case .Ret: s = "TOK_RET"
    }
    return s
}

Token :: struct {
    token_type: Token_Type,
    lexeme: []u8,
    line: int,
}

// Note: the caller own the memory is it's job to free it
token_to_string :: proc(tok: Token) -> string {
    builder := strings.builder_make()

    return fmt.sbprintf(&builder,
                        "Token(TokenType: '%s', Lexeme: '%s', Line: %d)",
                        token_type_to_string(tok.token_type),
                        tok.lexeme,
                        tok.line)
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
