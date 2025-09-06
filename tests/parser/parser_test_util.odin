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
        _, result = b.(^ast.Print)
    case ^ast.Println:
        _, result = b.(^ast.Println)
    }
    return result
}

compare_ast_node :: proc(a, b: ast.AstNode) -> bool {
    context.allocator = context.temp_allocator
    defer free_all(context.temp_allocator)

    result := true
    switch kind in a {
    case ast.Expr:
        expr, ok := b.(ast.Expr)
        if !ok do return false
        result = compare_expr(kind, expr)
    case ast.Stmt:
        expr, ok := b.(ast.Stmt)
        if !ok do return false
        result = compare_stmt(kind, expr)
    }
    
    return result
}

compare_actual_and_expected :: proc(t: ^testing.T, prefix_called_from: string, actual: [dynamic]ast.AstNode, expected: []ast.AstNode) {
    msgs_arena: virtual.Arena
    msgs_arena_allocator := virtual.arena_allocator(&msgs_arena)
    defer virtual.arena_destroy(&msgs_arena)

    sb := strings.builder_make(allocator = msgs_arena_allocator)
    if len(actual) != len(expected) {
        testing.fail_now(t, fmt.sbprintf(&sb, "[%s] Wrong number of Ast Node parsed: expected %d, got %d", prefix_called_from, len(expected), len(actual)))
    }


    for node, index in actual {
        strings.builder_reset(&sb)

        str := fmt.sbprintf(&sb,
                            "[%s] Mismatch at Node %d",
                            prefix_called_from,
                            index + 1) // 1 base index, my brain prefer that way
        testing.expect(t, compare_ast_node(node, expected[index]), str) 
    }
}
