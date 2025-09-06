package parser_test

import "core:fmt"
import "core:mem/virtual"
import "core:strings"
import "core:testing"

import "pinky:ast"
import "pinky:lexer"
import "pinky:parser"

setup_parser :: proc(t: ^testing.T, source: []u8, arena: ^virtual.Arena) -> [dynamic]ast.AstNode {
    tokens, lexer_err := lexer.tokenize(source, arena) 
    assert(lexer_err == lexer.Tokenize_Error.None)

    nodes, err := parser.parse(tokens[:], arena)
    if err != parser.Parser_Error.None {
        sb := strings.builder_make(allocator = context.temp_allocator)
        str := fmt.sbprintf(&sb, "Unexpected error while parsing := %s", parser.parser_error_to_string(err))
        testing.fail_now(t, str)
    }

    return nodes
}

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
    case ^ast.WhileStmt:
        _, result = b.(^ast.WhileStmt)
    case ^ast.IfStmt:
        _, result = b.(^ast.WhileStmt)
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

compare_actual_and_expected :: proc(t: ^testing.T, called_from_prefix: string, actual: [dynamic]ast.AstNode, expected: []ast.AstNode) {
    msgs_arena: virtual.Arena
    msgs_arena_allocator := virtual.arena_allocator(&msgs_arena)
    defer virtual.arena_destroy(&msgs_arena)

    sb := strings.builder_make(allocator = msgs_arena_allocator)
    if len(actual) != len(expected) {
        testing.fail_now(t, fmt.sbprintf(&sb, "[%s] Wrong number of Ast Node parsed: expected %d, got %d", called_from_prefix, len(expected), len(actual)))
    }


    for node, index in actual {
        strings.builder_reset(&sb)

        str := fmt.sbprintf(&sb,
                            "[%s] Mismatch at Node %d",
                            called_from_prefix,
                            index + 1) // 1 base index, my brain prefer that way
        testing.expect(t, compare_ast_node(node, expected[index]), str) 
    }
}

@(rodata)
only_math_expressions := #load("../test_data/expressions.pinky")

@(test)
test_math_expression_are_parsed_correctly :: proc(t: ^testing.T) {
    parser_arena: virtual.Arena
    defer virtual.arena_destroy(&parser_arena)

    defer free_all(context.temp_allocator)

    using ast

    expected := []AstNode{
        // -> 1
        ast.Expr(&BinOp{
            kind = .Add,
            left = &UnaryOp{
                kind = .Negate,
                operand = Integer(12),
            },
            right = &ast.BinOp{
                kind = .Mul,
                left = Integer(42),
                right = Integer(2),
            },
        }),

        // -> 2
        ast.Expr(&Grouping{
            expr = &BinOp {
                kind = .Add,
                left = &BinOp{
                    kind = .Add,
                    left = &UnaryOp{
                        kind = .Negate,
                        operand = Integer(1),
                    },
                    right = &UnaryOp{
                        kind = .Pos,
                        operand = Integer(1),
                    },
                },
                right = &UnaryOp{
                    kind = .Not,
                    operand = Integer(1),
                },
            }
        }),

        // -> 3
        Expr(&BinOp{
            kind = .Add,
            left = &BinOp{
                kind = .Add,
                left = &BinOp{
                    kind = .Add,
                    left = Integer(2), right = Integer(2),},
                right = Integer(2),
            },
            right = Integer(2),
        }),

        // -> 4
        Expr(&BinOp{
            kind = .Mul,
            left = &BinOp{
                kind = .Mul,
                left = &BinOp{
                    kind = .Mul,
                    left = Integer(2),
                    right = Integer(2),
                },
                right = Integer(2),
            },
            right = Integer(2),
        }),

        // -> 5
        Expr(&BinOp{
            kind = .Add,
            left = &BinOp{
                kind = .Add,
                left = Integer(1),
                right = &BinOp{
                    kind = .Mul,
                    left = Integer(2),
                    right = Integer(2),
                }
            },
            right = Integer(1),
        }),

        // -> 6
        Expr(&BinOp{
            kind = .Mul,
            left = &Grouping{
                expr = &BinOp{
                    kind = .Add,
                    left = Integer(1),
                    right = Integer(2),
                }
            },
            right = &Grouping{
                expr = &BinOp{
                    kind = .Add,
                    left = Integer(2),
                    right = Integer(1),
                }
            },
        }),

        // -> 7
        Expr(&BinOp{
            kind = .Sub,
            left = &BinOp{
                kind = .Add,
                left = Integer(1),
                right = Integer(2),
            },
            right = &BinOp{
                kind = .Div,
                left = &BinOp{
                    kind = .Mul,
                    left = Integer(3),
                    right = Integer(4),
                },
                right = Integer(5),
            },
        }),

        // -> 8
        Expr(&BinOp{
            kind = .Sub,
            left = &BinOp{
                kind = .Add,
                left = Float(1.0),
                right = Float(2.1),
            },
            right = &BinOp{
                kind = .Div,
                left = &BinOp{
                    kind = .Mul,
                    left = Float(3.2),
                    right = Float(4.3),
                },
                right = Float(5.4),
            },
        }),

        // -> 9
        Expr(String("asdf")),

        // -> 10
        Expr(&BinOp{
            kind = .Add,
            left = &BinOp{
                kind = .Add,
                left = String("Hello"),
                right = String(" ,")
            },
            right = String("World!"),
        }),

        // -> 11
        Expr(&BinOp{
            kind = .Exp,
            left = Integer(2),
            right = &BinOp{
                kind = .Exp,
                left = Integer(3),
                right = Integer(2),
            },
        }),
    }
        
    nodes := setup_parser(t, only_math_expressions, &parser_arena)
    compare_actual_and_expected(t, "test math expression", nodes, expected)
}
