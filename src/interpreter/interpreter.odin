package interpreter

import "core:mem/virtual"
import "core:strings"

import "pinky:ast"

Interpreter_Error :: enum {
    None,
    UnaryOpTypeMismatch,
    BinaryOpTypeMismatch,
    BinaryOpUnapplicableToType,
}

interpreter_error_to_string :: proc(ie: Interpreter_Error) -> (s: string) {
    switch ie {
    case .None: s = "None"
    case .UnaryOpTypeMismatch: s = "Unary operation type mismatch"
    case .BinaryOpTypeMismatch: s = "Binary operation type mismatch between the two operands"
    case .BinaryOpUnapplicableToType: s = "Binary operation unapplicable to the first operand"
    }
    return
}

interpret_expr :: proc(expr_node: ast.Expr) -> (result: ast.Expr, err: Interpreter_Error) {
    switch expr in expr_node {
    case ast.Integer, ast.Float, ast.String, ast.Bool:
        result = expr
    case ^ast.UnaryOp:
        result = interpret_expr(expr.operand) or_return
        switch expr.kind {
        case ast.UnaryOpKind.Not: 
            bool_res, ok := result.(ast.Bool)
            if !ok do return result, .UnaryOpTypeMismatch
            result = ast.Bool(!bool_res)
        case ast.UnaryOpKind.Pos:
            #partial switch num in result {
                case ast.Integer, ast.Float:
                // noop
                
                case:
                return result, .UnaryOpTypeMismatch
            }

        case ast.UnaryOpKind.Negate:
            #partial switch num in result {
                case ast.Integer:
                result = ast.Integer(num * -1)

                case ast.Float:
                result = ast.Float(num * -1.0)
                
                case:
                return result, .UnaryOpTypeMismatch
            }
        }
    case ^ast.BinOp:
        left := interpret_expr(expr.left) or_return
        right := interpret_expr(expr.right) or_return
        switch expr.kind {
        case ast.BinaryOpKind.Add:
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(ast.Integer)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand + right_operand
            case ast.Float:
                right_operand, ok := right.(ast.Float)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand + right_operand
            case ast.String:
                right_operand, ok := right.(ast.String)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = strings.concatenate({left_operand, right_operand})
            case:
                return expr, .BinaryOpUnapplicableToType
            }
        case ast.BinaryOpKind.Sub:
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(ast.Integer)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand - right_operand
            case ast.Float:
                right_operand, ok := right.(ast.Float)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand - right_operand
            case:
                return expr, .BinaryOpUnapplicableToType
            }
        case ast.BinaryOpKind.Mul:
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(ast.Integer)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand * right_operand
            case ast.Float:
                right_operand, ok := right.(ast.Float)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand * right_operand
            case:
                return expr, .BinaryOpUnapplicableToType
            }
        case ast.BinaryOpKind.Div:
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(ast.Integer)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand / right_operand
            case ast.Float:
                right_operand, ok := right.(ast.Float)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand / right_operand
            case:
                return expr, .BinaryOpUnapplicableToType
            }
        }
    case ^ast.Grouping:
        return interpret_expr(expr.expr)
    }
    return result, .None
}

interpret :: proc(node: ast.AstNode, interpret_arena: ^virtual.Arena) -> (a: ast.Expr, err: Interpreter_Error) {
    arena_allocator := virtual.arena_allocator(interpret_arena)
    context.allocator = arena_allocator

    switch node_kind in node {
    case ast.Expr:
        a = interpret_expr(node_kind) or_return
    case ast.Stmt:
        panic("Not implemented Yet!")
    }
    return a, .None
}
