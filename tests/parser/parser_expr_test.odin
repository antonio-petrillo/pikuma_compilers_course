package parser_test

import "core:fmt"
import "core:mem/virtual"
import "core:strings"
import "core:testing"

import "pinky:ast"
import "pinky:lexer"
import "pinky:parser"

setup_parser_expr :: proc(t: ^testing.T, source: []u8, arena: ^virtual.Arena) -> [dynamic]ast.AstNode {
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
        
    nodes := setup_parser_expr(t, only_math_expressions, &parser_arena)
    compare_actual_and_expected(t, "test math expression", nodes, expected)
}
