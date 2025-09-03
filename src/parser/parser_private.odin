#+private
package parser

import "core:strconv"
import "core:strings"

import "pinky:token"

Parser :: struct {
    tokens: []token.Token,
    start: int,
    current: int,
}

pad_builder :: proc(sb: ^strings.Builder, pad: int, pad_str: string = "  ") {
    for _ in 0..<pad {
        strings.write_string(sb, pad_str) // two space indentation
    }
}

ast_to_string_with_builder :: proc(ast: AstNode, sb: ^strings.Builder, indentation: int = 0) {
    pad_builder(sb, indentation)
    switch node in ast {
    case Expr:
        switch expr in node {
        case Integer:
            strings.write_string(sb, "Integer := <")
            strings.write_i64(sb, expr)
            strings.write_byte(sb, '>')
        case Float:
            strings.write_string(sb, "Float := <")
            strings.write_f64(sb, expr, 'f')
            strings.write_byte(sb, '>')
        case ^BinOp:
            defer {
                pad_builder(sb, indentation)
                strings.write_byte(sb, '}')
            }
            strings.write_string(sb, "BinOp := '")
            strings.write_string(sb, binary_op_kind_to_string(expr.kind))
            strings.write_string(sb, "': {\n")
            ast_to_string_with_builder(expr.left, sb, indentation + 1)
            strings.write_string(sb, ",\n")
            ast_to_string_with_builder(expr.right, sb, indentation + 1)
            strings.write_byte(sb, '\n')

        case ^UnaryOp:
            defer {
                pad_builder(sb, indentation)
                strings.write_byte(sb, '}')
            }
            strings.write_string(sb, "UnaryOp := '")
            strings.write_string(sb, unary_op_kind_to_string(expr.kind))
            strings.write_string(sb, "': {\n")
            ast_to_string_with_builder(expr.operand, sb, indentation + 1)
            strings.write_string(sb, "\n")
        case ^Grouping:
            defer {
                pad_builder(sb, indentation)
                strings.write_byte(sb, '}')
            }
            strings.write_string(sb, "Grouping {\n")
            ast_to_string_with_builder(expr.expr, sb, indentation + 1)
            strings.write_byte(sb, '\n')
        }
    case Stmt:
        switch stmt in node {
        case ^WhileStmt:
            strings.write_string(sb, "WhileStmt{ ")
            defer {
                pad_builder(sb, indentation)
                strings.write_byte(sb, '}')
            }
        case ^IfStmt:
            strings.write_string(sb, "IfStmt{ ")
            defer {
                pad_builder(sb, indentation)
                strings.write_byte(sb, '}')
            }
        }
    }
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

/* Parse Rule for Expr
 * <expr> :: = <term> (<addop> <term>)* */
parse_expr :: proc(parser: ^Parser) -> (Expr, Parser_Error) {
    // match the first <term>
    term, err := parse_term(parser)
    if err != .None {
        return term, err
    }
    // continue to match until is <addop>
    // (<addop> <term>)*
    for !is_eof(parser) {
        tok := peek(parser)
        if tok.token_type != token.Token_Type.Plus && tok.token_type != token.Token_Type.Minus {
            break
        }
        consume(parser) // discard + or -
        bin_op := new(BinOp) 
        bin_op.left = term
        bin_op.kind = tok.token_type == token.Token_Type.Plus ? .Addition : .Subtraction
        bin_op.right, err = parse_term(parser)
        if err != .None {
            return bin_op, err
        }
        term = bin_op
    }
    return term, .None
}

/* Parse Rule for Term
 * <expr> :: = <factor> (<mulop> <factor>)* */
parse_term :: proc(parser: ^Parser) -> (Expr, Parser_Error) {
    // match the first <factor>
    factor, err := parse_factor(parser) 
    if err != .None {
        return factor, err
    }

    // continue to match until is <mulop>
    // (<mulop> <factor>)*
    for !is_eof(parser) {
        tok := peek(parser)
        if tok.token_type != token.Token_Type.Star && tok.token_type != token.Token_Type.Slash {
            break
        }
        consume(parser) // discard * or /
        bin_op := new(BinOp) 
        bin_op.left = factor
        bin_op.kind = tok.token_type == token.Token_Type.Star ? .Multiplication : .Division
        bin_op.right, err = parse_term(parser)
        if err != .None {
            return bin_op, err
        }
        factor = bin_op
    }
    return factor, .None
}

/* Parse Rule for Factor
 * <factor> ::= <unary> */
parse_factor :: proc(parser: ^Parser) -> (Expr, Parser_Error) {
    return parse_unary(parser) 
}

/* Parse Rule for unary
 * <unary> ::= <unaryop> <unary> | <primary> */
parse_unary :: proc(parser: ^Parser) -> (Expr, Parser_Error) {
    kind: Maybe(UnaryOpKind) = nil
    // try to match the first case: <unaryop> <unary>
    switch {
    case match(parser, token.Token_Type.Plus): 
        kind = .Positive
    case match(parser, token.Token_Type.Minus): 
        kind = .Negate
    case match(parser, token.Token_Type.Not): 
        kind = .LogicalNegate
    }

    if kind != nil {
        // match effectively the case: <unaryop> <unary>
        unary, err := parse_unary(parser)
        if err != .None  {
            return unary, err 
        }

        // match <unary> recursively
        unary_node := new(UnaryOp)
        unary_node.kind = kind.?
        unary_node.operand = unary

        return unary_node, .None
    }

    // match other rule: <primary>
    return parse_primary(parser)
}

/* Parse Rule for Primary
 * <primary> ::= <number> | '(' <expr> ')' */
parse_primary :: proc(parser: ^Parser) -> (Expr, Parser_Error) {
    expr: Expr
    parser_err: Parser_Error = .None
    if match(parser, token.Token_Type.LeftParen) {
        expr, parser_err = parse_expr(parser)
        if parser_err != .None {
            return expr, parser_err
        }
        if !match(parser, token.Token_Type.RightParen) {
            return expr, .UnclosedParen
        }

        grouping := new(Grouping)
        grouping.expr = expr
        return grouping, .None
    }

    tok := advance(parser) 
    #partial switch tok.token_type {
        case token.Token_Type.Integer:
        num, ok := strconv.parse_i64_of_base(tok.lexeme, 10)
        if !ok {
            return expr, .InvalidFloat
        }
        return Integer(num), .None

        case token.Token_Type.Float:
        num, ok := strconv.parse_f64(tok.lexeme)
        if !ok {
            return expr, .InvalidFloat
        }
        return Float(num), .None
        case: 
        return expr, .InvalidPrimaryExpression
    }
}

