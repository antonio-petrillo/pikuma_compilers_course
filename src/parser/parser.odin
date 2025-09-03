package parser

import "core:mem/virtual"
import "core:strings"

import "pinky:token"

Integer :: i64

Float :: f64

BinaryOpKind :: enum {
    Addition,
    Subtraction,
    Multiplication,
    Division,
}

binary_op_kind_to_string :: proc(kind: BinaryOpKind) -> (s: string) {
    switch kind {
    case .Addition: s = "+"
    case .Subtraction: s = "-"
    case .Multiplication: s = "*"
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
