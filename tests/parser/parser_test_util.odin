#+private
package parser_test

import "core:fmt"
import "core:mem/virtual"
import "core:strings"
import "core:testing"

import "pinky:ast"

compare_expr :: proc(a, b: ast.Expr) -> bool {
    result := true 
    switch expr in a {
    case ast.Integer:
        num, ok := b.(ast.Integer)
        if !ok do return false
        result = expr == num

    case ast.Float:
        num, ok := b.(ast.Float)
        if !ok do return false
        result = expr == num

    case ast.Bool:
        bool_val, ok := b.(ast.Bool)
        if !ok do return false
        result = expr == bool_val

    case ast.String:
        str, ok := b.(ast.String)
        if !ok do return false
        result = expr == str

    case ^ast.BinOp:
        other_expr, ok := b.(^ast.BinOp)
        if !ok do return false
        result = expr.kind == other_expr.kind &&
            compare_expr(expr.left, other_expr.left) &&
            compare_expr(expr.right, other_expr.right)

    case ^ast.UnaryOp:
        other_expr, ok := b.(^ast.UnaryOp)
        if !ok do return false
        result = expr.kind == other_expr.kind && compare_expr(expr.operand, other_expr.operand)

    case ^ast.Grouping:
        other_expr, ok := b.(^ast.Grouping)
        if !ok do return false
        result = compare_expr(expr.expr, other_expr.expr)
    }
    return result
}

compare_stmt :: proc(a, b: ast.Stmt) -> bool {
    result := true
    switch kind in a {
    case ^ast.Print:
        print, ok := b.(^ast.Print)
        if !ok do return false
        return compare_expr(kind.expr, print.expr)
    case ^ast.Println:
        println, ok := b.(^ast.Println)
        if !ok do return false
        return compare_expr(kind.expr, println.expr)
    case ^ast.WrapExpr:
        wrapped, ok := b.(^ast.WrapExpr)
        if !ok do return false
        return compare_expr(kind.expr, wrapped.expr)
    case ^ast.If:
        if_stmt, ok := b.(^ast.If)
        if !ok do return false
        if !compare_expr(kind.cond, if_stmt.cond) do return false
        if len(kind.then_branch) != len(if_stmt.then_branch) do return false

        for node, index in kind.then_branch {
            if !compare_stmt(node, if_stmt.then_branch[index]) do return false
        }

        if len(kind.else_branch) != len(if_stmt.else_branch) do return false

        for node, index in kind.else_branch {
            if !compare_stmt(node, if_stmt.else_branch[index]) do return false
        }

    }
    return result
}
