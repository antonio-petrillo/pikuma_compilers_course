package ast

import "core:strings"

Integer :: i64

Float :: f64

String :: string

Bool :: bool

BinaryOpKind :: enum {
    Add,
    Sub,
    Mul,
    Div,
}

binary_op_kind_to_string :: proc(kind: BinaryOpKind) -> (s: string) {
    switch kind {
    case .Add: s = "+"
    case .Sub: s = "-"
    case .Mul: s = "*"
    case .Div: s = "/"
    }
    return
}

BinOp :: struct {
    left: Expr,
    right: Expr,
    kind: BinaryOpKind,
}

UnaryOpKind :: enum {
    Pos,
    Negate,
    Not,
}

unary_op_kind_to_string :: proc(kind: UnaryOpKind) -> (s: string) {
    switch kind {
    case .Pos: s = "+"
    case .Negate: s = "-"
    case .Not: s = "~"
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
    String,
    Bool,
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

ast_to_string_summary :: proc(ast: AstNode) -> (s: string) {
    sb := strings.builder_make()
    ast_to_string_summary_with_builder(ast, &sb)
    return strings.to_string(sb)
}

@(private)
ast_to_string_summary_with_builder :: proc(ast: AstNode, sb: ^strings.Builder) {
    switch node in ast {
    case Expr:
        switch expr in node {
        case Integer:
            strings.write_i64(sb, expr)
        case Float:
            strings.write_f64(sb, expr, 'f')
        case String:
            strings.write_string(sb, expr)
        case Bool:
            bool_str := expr ? "true" : "false"
            strings.write_string(sb, bool_str)
        case ^BinOp:
            ast_to_string_summary_with_builder(expr.left, sb)
            strings.write_byte(sb, ' ')
            strings.write_string(sb, binary_op_kind_to_string(expr.kind))
            strings.write_byte(sb, ' ')
            ast_to_string_summary_with_builder(expr.right, sb)
        case ^UnaryOp:
            strings.write_string(sb, unary_op_kind_to_string(expr.kind))
            ast_to_string_summary_with_builder(expr.operand, sb)
        case ^Grouping:
            strings.write_string(sb, "(")
            ast_to_string_summary_with_builder(expr.expr, sb)
            strings.write_string(sb, ")")
        }
    case Stmt:
        switch stmt in node {
        case ^WhileStmt:
        case ^IfStmt:
        }
    }
}

pad_builder :: proc(sb: ^strings.Builder, pad: int, pad_str: string = "  ") {
    for _ in 0..<pad {
        strings.write_string(sb, pad_str) // two space indentation
    }
}

@(private)
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
        case String:
            strings.write_string(sb, "String := ")
            strings.write_string(sb, expr)
        case Bool:
            strings.write_string(sb, "Bool := <")
            bool_str := expr ? "true" : "false"
            strings.write_string(sb, bool_str)
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
