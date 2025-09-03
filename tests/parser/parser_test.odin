package parser_test

import "core:fmt"
import "core:mem/virtual"
import "core:strings"
import "core:testing"

import "pinky:lexer"
import "pinky:parser"

setup_parser :: proc(t: ^testing.T, source: []u8, arena: ^virtual.Arena) -> [dynamic]parser.AstNode {
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

compare_expr :: proc(a, b: parser.Expr) -> bool {
    result := true 
    switch expr in a {
    case parser.Integer:
        num, ok := b.(parser.Integer)
        if !ok do return false
        result = expr == num

    case parser.Float:
        num, ok := b.(parser.Float)
        if !ok do return false
        result = expr == num

    case ^parser.BinOp:
        other_expr, ok := b.(^parser.BinOp)
        if !ok do return false
        result = expr.kind == other_expr.kind &&
            compare_expr(expr.left, other_expr.left) &&
            compare_expr(expr.right, other_expr.right)

    case ^parser.UnaryOp:
        other_expr, ok := b.(^parser.UnaryOp)
        if !ok do return false
        result = expr.kind == other_expr.kind && compare_expr(expr.operand, other_expr.operand)

    case ^parser.Grouping:
        other_expr, ok := b.(^parser.Grouping)
        if !ok do return false
        result = compare_expr(expr.expr, other_expr.expr)
    }
    return result
}

compare_stmt :: proc(a, b: parser.Stmt) -> bool {
    result := true
    switch kind in a {
    case ^parser.WhileStmt:
        _, result = b.(^parser.WhileStmt)
    case ^parser.IfStmt:
        _, result = b.(^parser.WhileStmt)
    }
    return result
}

compare_ast_node :: proc(a, b: parser.AstNode) -> bool {
    result := true
    switch kind in a {
    case parser.Expr:
        expr, ok := b.(parser.Expr)
        if !ok do return false
        result = compare_expr(kind, expr)
    case parser.Stmt:
        expr, ok := b.(parser.Stmt)
        if !ok do return false
        result = compare_stmt(kind, expr)
    }
    
    return result
}

compare_actual_and_expected :: proc(t: ^testing.T, actual: [dynamic]parser.AstNode, expected: []parser.AstNode) {
    msgs_arena: virtual.Arena
    msgs_arena_allocator := virtual.arena_allocator(&msgs_arena)
    defer virtual.arena_destroy(&msgs_arena)

    sb := strings.builder_make(allocator = msgs_arena_allocator)
    if len(actual) != len(expected) {
        testing.fail_now(t, fmt.sbprintf(&sb, "Wrong number of Ast Node parsed: expected %d, got %d", len(expected), len(actual)))
    }

    for node, index in actual {
        strings.builder_reset(&sb)
        testing.expect(t, compare_ast_node(node, expected[index]),
                       fmt.sbprintf(&sb, "Mismatch at Node %d", index + 1)) // 1 base index, my brain prefer that way
    }
}

@(rodata)
only_math_expressions := #load("../test_data/math_expressions.pinky")

@(test)
test_math_expression_are_parsed_correctly :: proc(t: ^testing.T) {
    parser_arena: virtual.Arena
    defer virtual.arena_destroy(&parser_arena)

    defer free_all(context.temp_allocator)

    using parser

    expected := []AstNode{
        parser.Expr(&BinOp{
            kind = .Addition,
            left = &UnaryOp{
                kind = .Negate,
                operand = Integer(2),
            },
            right = &parser.BinOp{
                kind = .Multiplication,
                left = Integer(42),
                right = Integer(2),
            },
        }),

        parser.Expr(&Grouping{
            expr = &BinOp {
                kind = .Addition,
                left = &BinOp{
                    kind = .Addition,
                    left = &UnaryOp{
                        kind = .Negate,
                        operand = Integer(1),
                    },
                    right = &UnaryOp{
                        kind = .Positive,
                        operand = Integer(1),
                    },
                },
                right = &UnaryOp{
                    kind = .LogicalNegate,
                    operand = Integer(1),
                },
            }
        }),
        Expr(&BinOp{
            kind = BinaryOpKind.Addition,
            left = &BinOp{
                kind = .Addition,
                left = &BinOp{
                    kind = .Addition,
                    left = Integer(2),
                    right = Integer(2),
                },
                right = Integer(2),
            },
            right = Integer(2),
        }),
        Expr(&BinOp{
            kind = .Multiplication,
            left = Integer(2),
            right = &BinOp{
                kind = .Multiplication,
                left = Integer(2),
                right = &BinOp{
                    kind = .Multiplication,
                    left = Integer(2),
                    right = Integer(2),
                }
            }
        }),
        Expr(&BinOp{
            kind = .Addition,
            left = &BinOp{
                kind = .Addition,
                left = Integer(1),
                right = &BinOp{
                    kind = .Multiplication,
                    left = Integer(2),
                    right = Integer(2),
                }
            },
            right = Integer(1),
        }),
        Expr(&BinOp{
            kind = .Multiplication,
            left = &Grouping{
                expr = &BinOp{
                    kind = .Addition,
                    left = Integer(1),
                    right = Integer(2),
                }
            },
            right = &Grouping{
                expr = &BinOp{
                    kind = .Addition,
                    left = Integer(2),
                    right = Integer(1),
                }
            },
        }),
        Expr(&BinOp{
            kind = .Subtraction,
            left = &BinOp{
                kind = .Addition,
                left = Integer(1),
                right = Integer(2),
            },
            right = &BinOp{
                kind = .Multiplication,
                left = Integer(3),
                right = &BinOp{
                    kind = .Division,
                    left = Integer(4),
                    right = Integer(5),
                }
            },
        }),
        Expr(&BinOp{
            kind = .Subtraction,
            left = &BinOp{
                kind = .Addition,
                left = Float(1.0),
                right = Float(2.1),
            },
            right = &BinOp{
                kind = .Multiplication,
                left = Float(3.2),
                right = &BinOp{
                    kind = .Division,
                    left = Float(4.3),
                    right = Float(5.4),
                }
            },
        }),
    }
        
    nodes := setup_parser(t, only_math_expressions, &parser_arena)
    compare_actual_and_expected(t, nodes, expected)
}
