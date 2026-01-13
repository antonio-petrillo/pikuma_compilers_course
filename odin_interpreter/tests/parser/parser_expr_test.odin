package parser_test

import "core:fmt"
import "core:mem/virtual"
import "core:strings"
import "core:testing"

import "pinky:ast"
import "pinky:lexer"
import "pinky:parser"

setup_parser_expr :: proc(t: ^testing.T, source: []u8, arena: ^virtual.Arena) -> [dynamic]ast.Stmt {
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

@(rodata)
only_math_expressions := #load("../test_data/expressions.pinky")

@(test)
test_math_expression_are_parsed_correctly :: proc(t: ^testing.T) {
    parser_arena: virtual.Arena
    defer virtual.arena_destroy(&parser_arena)

    defer free_all(context.temp_allocator)

    using ast

    expected := []Stmt{
        // -> 1
            &WrapExpr{ expr = Expr(&BinOp{
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
            })},

        // -> 2
            &WrapExpr{ expr = Expr(&Grouping{
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
            })},

        // -> 3
            &WrapExpr{expr = Expr(&BinOp{
                kind = .Add,
                left = &BinOp{
                    kind = .Add,
                    left = &BinOp{
                        kind = .Add,
                        left = Integer(2), right = Integer(2),},
                    right = Integer(2),
                },
                right = Integer(2),
            })},

        // -> 4
            &WrapExpr{ expr = Expr(&BinOp{
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
            })},

        // -> 5
            &WrapExpr{ expr = Expr(&BinOp{
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
            })},

        // -> 6
            &WrapExpr{ expr = Expr(&BinOp{
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
            })},

        // -> 7
            &WrapExpr{expr = Expr(&BinOp{
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
            })},

        // -> 8
            &WrapExpr{expr = Expr(&BinOp{
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
            })},

        // -> 9
            &WrapExpr{ expr = Expr(String("asdf"))},

        // -> 10
            &WrapExpr{ expr = Expr(&BinOp{
                kind = .Add,
                left = &BinOp{
                    kind = .Add,
                    left = String("Hello"),
                    right = String(" ,")
                },
                right = String("World!"),
            })},

        // -> 11
            &WrapExpr{ expr = Expr(&BinOp{
                kind = .Exp,
                left = Integer(2),
                right = &BinOp{
                    kind = .Exp,
                    left = Integer(3),
                    right = Integer(2),
                },
            })},
    }
        
    nodes := setup_parser_expr(t, only_math_expressions, &parser_arena)
    expr_compare_actual_and_expected(t, "test math expression", nodes, expected)
}

expr_compare_actual_and_expected :: proc(t: ^testing.T, prefix_called_from: string, actual: [dynamic]ast.Stmt, expected: []ast.Stmt) {
    msgs_arena: virtual.Arena
    msgs_arena_allocator := virtual.arena_allocator(&msgs_arena)
    defer virtual.arena_destroy(&msgs_arena)

    sb := strings.builder_make(allocator = msgs_arena_allocator)
    if len(actual) != len(expected) {
        testing.fail_now(t, fmt.sbprintf(&sb, "[%s] Wrong number of Ast Node parsed: expected %d, got %d", prefix_called_from, len(expected), len(actual)))
    }

    for &node, index in actual {
        strings.builder_reset(&sb)

        wrapped, ok := node.(^ast.WrapExpr)
        if !ok {
            str := fmt.sbprintf(&sb,
                                "[%s] Wrong Statement at %d index, parsed ast is not an ^ast.WrapExpr",
                                prefix_called_from,
                                index + 1) // 1 base index, my brain prefer that way in this case
            testing.expect(t, false, str) 
        }

        str := fmt.sbprintf(&sb,
                            "[%s] Mismatch at Node %d",
                            prefix_called_from,
                            index + 1) // 1 base index, my brain prefer that way
        testing.expect(t, compare_stmt(wrapped, expected[index]), str) 
    }
}
