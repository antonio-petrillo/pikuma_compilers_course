package interpreter

import "pinky:ast"

Interpreter_Error :: enum {
    
}

interpret_expr :: proc(expr_node: ast.Expr) -> (result: f64) {
    switch expr in expr_node {
    case ast.Integer:
        result = f64(expr)
    case ast.Float:
        result = f64(expr)
    case ^ast.UnaryOp:
        result = interpret(expr.operand)
        switch expr.kind {
        case ast.UnaryOpKind.Not: 
            // noop
        case ast.UnaryOpKind.Pos:
            // noop
        case ast.UnaryOpKind.Negate:
            result *= -1.0
        }
    case ^ast.BinOp:
        left := interpret(expr.left)
        right := interpret(expr.right)
        switch expr.kind {
        case ast.BinaryOpKind.Add:
            result = left + right
        case ast.BinaryOpKind.Sub:
            result = left - right
        case ast.BinaryOpKind.Mul:
            result = left * right
        case ast.BinaryOpKind.Div:
            result = left / right
        }
    case ^ast.Grouping:
        result = interpret(expr.expr)
    }
    return
}

interpret :: proc(node: ast.AstNode) -> (result: f64) {
    switch node_kind in node {
    case ast.Expr:
        return interpret_expr(node_kind)
    case ast.Stmt:
        panic("Not implemented yet!")
    }
    
    return
}
