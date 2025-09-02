package lexer

import "core:fmt"
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
}

// Note: the caller own the memory is it's job to free it
token_to_string :: proc(tok: Token) -> string {
    builder := strings.builder_make()

    return fmt.sbprintf(&builder,
                 "Token(TokenType: '%s', Lexeme: '%s')",
                 token_type_to_string(tok.token_type),
                 tok.lexeme)
}
