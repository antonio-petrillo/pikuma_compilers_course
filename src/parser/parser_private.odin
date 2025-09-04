#+private
package parser

import "core:strconv"
import "core:strings"

import "pinky:token"
import "pinky:ast"

Parser :: struct {
    tokens: []token.Token,
    start: int,
    current: int,
}

advance :: proc(parser: ^Parser) -> token.Token {
    tok := parser.tokens[parser.current] 
    parser.current += 1
    return tok
}

lookahead :: proc(parser: ^Parser, n: int = 1) -> Maybe(token.Token) {
    if n + parser.current >= len(parser.tokens) {
        return nil
    }
    return parser.tokens[parser.current + n]
}

peek :: proc(parser: ^Parser) -> token.Token {
    return parser.tokens[parser.current]
}

consume :: proc(parser: ^Parser) {
    parser.current += 1
}

match :: proc(parser: ^Parser, token_type: token.Token_Type) -> bool {
    if is_eof(parser) || parser.tokens[parser.current].token_type != token_type {
        return false
    }
    parser.current += 1
    return true
}

is_eof :: proc(parser: ^Parser) -> bool {
    return parser.current >= len(parser.tokens)
}

parse_expr :: proc(parser: ^Parser) -> (ast.Expr, Parser_Error) {
    return parse_addition(parser)
}

parse_addition :: proc(parser: ^Parser) -> (ast.Expr, Parser_Error) {
    multiplication, err := parse_multiplication(parser)
    if err != .None {
        return multiplication, err
    }
    for !is_eof(parser) {
        tok := peek(parser)
        if tok.token_type != token.Token_Type.Plus && tok.token_type != token.Token_Type.Minus {
            break
        }
        consume(parser) // discard + or -
        bin_op := new(ast.BinOp) 
        bin_op.left = multiplication
        bin_op.kind = tok.token_type == token.Token_Type.Plus ? ast.BinaryOpKind.Add : ast.BinaryOpKind.Sub
        bin_op.right, err = parse_multiplication(parser)
        if err != .None {
            return bin_op, err
        }
        multiplication = bin_op
    }
    return multiplication, .None
}

parse_multiplication :: proc(parser: ^Parser) -> (ast.Expr, Parser_Error) {
    unary, err := parse_unary(parser) 
    if err != .None {
        return unary, err
    }

    for !is_eof(parser) {
        tok := peek(parser)
        if tok.token_type != token.Token_Type.Star && tok.token_type != token.Token_Type.Slash {
            break
        }
        consume(parser) // discard * or /
        bin_op := new(ast.BinOp) 
        bin_op.left = unary
        bin_op.kind = tok.token_type == token.Token_Type.Star ? ast.BinaryOpKind.Mul : ast.BinaryOpKind.Div
        bin_op.right, err = parse_multiplication(parser)
        if err != .None {
            return bin_op, err
        }
        unary = bin_op
    }
    return unary, .None
}

parse_unary :: proc(parser: ^Parser) -> (ast.Expr, Parser_Error) {
    kind: Maybe(ast.UnaryOpKind) = nil
    switch {
    case match(parser, token.Token_Type.Plus): 
        kind = ast.UnaryOpKind.Pos
    case match(parser, token.Token_Type.Minus): 
        kind = ast.UnaryOpKind.Negate
    case match(parser, token.Token_Type.Not): 
        kind = ast.UnaryOpKind.Not
    }

    if kind != nil {
        unary, err := parse_unary(parser)
        if err != .None  {
            return unary, err 
        }

        unary_node := new(ast.UnaryOp)
        unary_node.kind = kind.?
        unary_node.operand = unary

        return unary_node, .None
    }

    return parse_primary(parser)
}

parse_primary :: proc(parser: ^Parser) -> (ast.Expr, Parser_Error) {
    expr: ast.Expr
    parser_err: Parser_Error = .None
    if match(parser, token.Token_Type.LeftParen) {
        expr, parser_err = parse_addition(parser)
        if parser_err != .None {
            return expr, parser_err
        }
        if !match(parser, token.Token_Type.RightParen) {
            return expr, .UnclosedParen
        }

        grouping := new(ast.Grouping)
        grouping.expr = expr
        return grouping, .None
    }

    tok := advance(parser) 
    #partial switch tok.token_type {
        case token.Token_Type.Integer:
        num, ok := strconv.parse_i64_of_base(tok.lexeme, 10)
        if !ok {
            return expr, .InvalidInteger
        }
        return ast.Integer(num), .None

        case token.Token_Type.Float:
        num, ok := strconv.parse_f64(tok.lexeme)
        if !ok {
            return expr, .InvalidFloat
        }
        return ast.Float(num), .None

        case token.Token_Type.True, token.Token_Type.False:
        return ast.Bool(tok.lexeme == "true"), .None

        case token.Token_Type.String:
        str := strings.trim(tok.lexeme, "\"")
        return ast.String(str), .None

        case: 
        return expr, .InvalidPrimaryExpression
    }
}

