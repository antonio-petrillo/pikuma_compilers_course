package parser

import "core:mem/virtual"
import "core:strconv"
import "core:strings"

import "pinky:token"

Parser :: struct {
    tokens: []token.Token,
    start: int,
    current: int,
}


Integer :: i64

Float :: f64

BinaryOpKind :: enum {
    Addition,
    Subtraction,
    Multiplicaiton,
    Division,
}

binary_op_kind_to_string :: proc(kind: BinaryOpKind) -> (s: string) {
    switch kind {
    case .Addition: s = "+"
    case .Subtraction: s = "-"
    case .Multiplicaiton: s = "*"
    case .Division: s = "/"
    }
    return
}

BinOp :: struct {
    left: Expr,
    right: Expr,
    kind: BinaryOpKind,
}

UnaryOpKind :: enum {
    Positive,
    Negate,
    LogicalNegate,
}

unary_op_kind_to_string :: proc(kind: UnaryOpKind) -> (s: string) {
    switch kind {
    case .Positive: s = "+"
    case .Negate: s = "-"
    case .LogicalNegate: s = "~"
    }
    return
}

UnaryOp :: struct {
    operand: Expr,
    kind: UnaryOpKind,
}


Grouping :: struct {
    expr: Expr 
}

Expr :: union #no_nil {
    Integer, 
    Float,
    ^BinOp,
    ^UnaryOp,
    ^Grouping,
}

WhileStmt :: struct {
    
}

IfStmt :: struct {
    
}

Stmt :: union #no_nil {
    ^WhileStmt,
    ^IfStmt
}

AstNode :: union #no_nil {
    Expr,
    Stmt,
}

ast_to_string :: proc(ast: AstNode) -> (s: string) {
    sb := strings.builder_make()
    ast_to_string_with_builder(ast, &sb)
    return strings.to_string(sb)
}

pad_builder :: proc(sb: ^strings.Builder, pad: int) {
    for _ in 0..<pad {
        strings.write_bytes(sb, []byte{' ', ' '})
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
                strings.write_string(sb, "}")
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
                strings.write_string(sb, " }")
            }
            strings.write_string(sb, "UnaryOp := '")
            strings.write_string(sb, unary_op_kind_to_string(expr.kind))
            strings.write_string(sb, "': { ")
            ast_to_string_with_builder(expr.operand, sb, indentation + 1)
        case ^Grouping:
            strings.write_string(sb, "Grouping {")
            defer {
                pad_builder(sb, indentation)
                strings.write_string(sb, "}\n")
            }
            ast_to_string_with_builder(expr.expr, sb, indentation + 1)
        }
    case Stmt:
        switch stmt in node {
        case ^WhileStmt:
            strings.write_string(sb, "WhileStmt{ ")
            defer strings.write_string(sb, " }")
        case ^IfStmt:
            strings.write_string(sb, "IfStmt{ ")
            defer strings.write_string(sb, " }")
        }
    }
}

parse_expr :: proc(parser: ^Parser) -> (Expr, Parser_Error) {
    term, err := parse_term(parser)
    if err != .None {
        return term, err
    }
    for  !is_eof(parser) {
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

parse_term :: proc(parser: ^Parser) -> (Expr, Parser_Error) {
    factor, err := parse_factor(parser) 
    if err != .None {
        return factor, err
    }

    for !is_eof(parser) {
        tok := peek(parser)
        if tok.token_type != token.Token_Type.Star && tok.token_type != token.Token_Type.Slash {
            break
        }
        consume(parser) // discard * or /
        bin_op := new(BinOp) 
        bin_op.left = factor
        bin_op.kind = tok.token_type == token.Token_Type.Star ? .Multiplicaiton : .Division
        bin_op.right, err = parse_term(parser)
        if err != .None {
            return bin_op, err
        }
        factor = bin_op
    }
    return factor, .None
}

parse_factor :: proc(parser: ^Parser) -> (Expr, Parser_Error) {
    return parse_unary(parser) 
}

parse_unary :: proc(parser: ^Parser) -> (Expr, Parser_Error) {
    kind: Maybe(UnaryOpKind) = nil
    switch {
    case match(parser, token.Token_Type.Plus): 
        kind = .Positive
    case match(parser, token.Token_Type.Minus): 
        kind = .Negate
    case match(parser, token.Token_Type.Not): 
        kind = .LogicalNegate
    }

    if kind != nil {
        unary, err := parse_unary(parser)
        if err != .None  {
            return unary, err 
        }

        unary_node := new(UnaryOp)
        unary_node.kind = kind.?
        unary_node.operand = unary

        return unary_node, .None
    }

    return parse_primary(parser)
}

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

Parser_Error :: enum {
    None,
    InvalidInteger,
    InvalidFloat,
    InvalidPrimaryExpression,
    UnclosedParen,
}

parser_error_to_string :: proc(pe: Parser_Error) -> (s: string) {
    switch pe {
    case .None: s = "None" 
    case .InvalidInteger: s = "Can't parse Integer lexeme"
    case .InvalidFloat: s = "Can't parse Float lexeme"
    case .InvalidPrimaryExpression: s = "Can't parse primary expression"
    case .UnclosedParen: s = "Missing closing parenthesis ')'"
    }
    return
}

parse :: proc(tokens: []token.Token, parser_arena: ^virtual.Arena) -> ([dynamic]AstNode, Parser_Error) {
    arena_allocator := virtual.arena_allocator(parser_arena)
    context.allocator = arena_allocator

    ast_nodes := make([dynamic]AstNode)
    parser_error: Parser_Error = .None
    encountered_error := false

    parser := &Parser{
        tokens = tokens,
        current = 0,
    }

    loop: for !is_eof(parser) {
        node, err := parse_expr(parser)
        if err != .None {
            parser_error = err
            encountered_error = true
            break loop
        }
        append(&ast_nodes, node) 
    }

    if encountered_error {
        clear(&ast_nodes)
    }

    return ast_nodes, parser_error
}
