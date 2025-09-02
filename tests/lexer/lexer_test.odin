package lexer_test

import "core:fmt"
import "core:log"
import "core:slice"
import "core:strings"
import "core:testing"
import "core:mem/virtual"

import lexer_pkg "../../src/lexer"

@(rodata)
all_token_source_data := #load("./lexer_test_data.pinky")

@(test)
test_all_tokens_are_lexed_correctly :: proc(t: ^testing.T) {
    lexer := lexer_pkg.new_lexer(all_token_source_data) 
    tokens := lexer_pkg.tokenize(&lexer)
    defer delete(tokens)

    msgs_arena: virtual.Arena
    msgs_arena_allocator := virtual.arena_allocator(&msgs_arena)
    defer virtual.arena_destroy(&msgs_arena)

    expecteds := []lexer_pkg.Token {
        lexer_pkg.Token{.LeftParen, transmute([]u8)string("(")},
        lexer_pkg.Token{.RightParen, transmute([]u8)string(")")}, 
        lexer_pkg.Token{.LeftSquare, transmute([]u8)string("[")},
        lexer_pkg.Token{.RightSquare, transmute([]u8)string("]")},
        lexer_pkg.Token{.LeftCurly, transmute([]u8)string("{")},
        lexer_pkg.Token{.RightCurly, transmute([]u8)string("}")},
        lexer_pkg.Token{.Comma, transmute([]u8)string(",")},
        lexer_pkg.Token{.Dot, transmute([]u8)string(".")},
        lexer_pkg.Token{.Plus, transmute([]u8)string("+")},
        lexer_pkg.Token{.Minus, transmute([]u8)string("-")},
        lexer_pkg.Token{.Star, transmute([]u8)string("*")},
        lexer_pkg.Token{.Slash, transmute([]u8)string("/")},
        lexer_pkg.Token{.Caret, transmute([]u8)string("^")},
        lexer_pkg.Token{.Mod, transmute([]u8)string("%")},
        lexer_pkg.Token{.Semicolon, transmute([]u8)string(";")},
        lexer_pkg.Token{.Question, transmute([]u8)string("?")},
        lexer_pkg.Token{.Colon, transmute([]u8)string(":")},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":=")},
        lexer_pkg.Token{.Not, transmute([]u8)string("~")},
        lexer_pkg.Token{.Ne, transmute([]u8)string("~=")},
        lexer_pkg.Token{.Eq, transmute([]u8)string("==")},
        lexer_pkg.Token{.Gt, transmute([]u8)string(">")},
        lexer_pkg.Token{.Ge, transmute([]u8)string(">=")},
        lexer_pkg.Token{.GtGt, transmute([]u8)string(">>")},
        lexer_pkg.Token{.Lt, transmute([]u8)string("<")},
        lexer_pkg.Token{.Le, transmute([]u8)string("<=")},
        lexer_pkg.Token{.LtLt, transmute([]u8)string("<<")},
        lexer_pkg.Token{.String, transmute([]u8)string("\"a string literal\"")},
        lexer_pkg.Token{.Integer, transmute([]u8)string("1234567890")},
        lexer_pkg.Token{.Float, transmute([]u8)string("12345.6789")},
        lexer_pkg.Token{.If, transmute([]u8)string("if")},
        lexer_pkg.Token{.Then, transmute([]u8)string("then")},
        lexer_pkg.Token{.Else, transmute([]u8)string("else")},
        lexer_pkg.Token{.True, transmute([]u8)string("true")},
        lexer_pkg.Token{.False, transmute([]u8)string("false")},
        lexer_pkg.Token{.And, transmute([]u8)string("and")},
        lexer_pkg.Token{.Or, transmute([]u8)string("or")},
        lexer_pkg.Token{.While, transmute([]u8)string("while")},
        lexer_pkg.Token{.Do, transmute([]u8)string("do")},
        lexer_pkg.Token{.For, transmute([]u8)string("for")},
        lexer_pkg.Token{.Func, transmute([]u8)string("func")},
        lexer_pkg.Token{.Null, transmute([]u8)string("null")},
        lexer_pkg.Token{.End, transmute([]u8)string("end")},
        lexer_pkg.Token{.Print, transmute([]u8)string("print")},
        lexer_pkg.Token{.Println, transmute([]u8)string("println")},
        lexer_pkg.Token{.Ret, transmute([]u8)string("ret")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("varname")}, 
        lexer_pkg.Token{.Identifier, transmute([]u8)string("another_var")}, 
    }
    expecteds_size := len(expecteds)

    for tok, index in tokens {
        sb := strings.builder_make(allocator = msgs_arena_allocator)
        if index >= expecteds_size {
            testing.fail_now(t,
                             fmt.sbprintf(&sb, "Lexed to many tokens, expected %d, got %d",
                                          expecteds_size,
                                          len(tokens)))
        }

        strings.builder_reset(&sb)
        testing.expect(t, tok.token_type == expecteds[index].token_type,
                       fmt.sbprintf(&sb, "Expected token type %q, got %q",
                                    lexer_pkg.token_type_to_string(expecteds[index].token_type),
                                    lexer_pkg.token_type_to_string(tok.token_type)))
        strings.builder_reset(&sb)
        testing.expect(t, slice.simple_equal(tok.lexeme, expecteds[index].lexeme),
                       fmt.sbprintf(&sb, "Expected lexeme to be %q, got %q",
                                    expecteds[index].lexeme,
                                    tok.lexeme))
    }

}


@(rodata)
simple_pinky_program_data := #load("mandelbrot.pinky")

@(test)
test_lex_a_simple_proper_program :: proc(t: ^testing.T) {
    lexer := lexer_pkg.new_lexer(simple_pinky_program_data) 
    tokens := lexer_pkg.tokenize(&lexer)
    defer delete(tokens)

    msgs_arena: virtual.Arena
    msgs_arena_allocator := virtual.arena_allocator(&msgs_arena)
    defer virtual.arena_destroy(&msgs_arena)

    expecteds := []lexer_pkg.Token {
        // func definition
        lexer_pkg.Token{.Func, transmute([]u8)string("func")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("mandelbrot")}, 
        lexer_pkg.Token{.LeftParen, transmute([]u8)string("(")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("cx")}, 
        lexer_pkg.Token{.Comma, transmute([]u8)string(",")}, 
        lexer_pkg.Token{.Identifier, transmute([]u8)string("cy")}, 
        lexer_pkg.Token{.RightParen, transmute([]u8)string(")")},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("x")},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":=")},
        lexer_pkg.Token{.Integer, transmute([]u8)string("0")},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("y")},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":=")},
        lexer_pkg.Token{.Integer, transmute([]u8)string("0")},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("iter")},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":=")},
        lexer_pkg.Token{.Integer, transmute([]u8)string("0")},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("max")},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":=")},
        lexer_pkg.Token{.Integer, transmute([]u8)string("16")},

        lexer_pkg.Token{.While, transmute([]u8)string("while")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("x")},
        lexer_pkg.Token{.Star, transmute([]u8)string("*")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("x")},
        lexer_pkg.Token{.Plus, transmute([]u8)string("+")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("y")},
        lexer_pkg.Token{.Star, transmute([]u8)string("*")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("y")},
        lexer_pkg.Token{.Le, transmute([]u8)string("<=")},
        lexer_pkg.Token{.Integer, transmute([]u8)string("4")},
        lexer_pkg.Token{.And, transmute([]u8)string("and")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("iter")},
        lexer_pkg.Token{.Lt, transmute([]u8)string("<")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("max")},
        lexer_pkg.Token{.Do, transmute([]u8)string("do")},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("xtemp")},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":=")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("x")},
        lexer_pkg.Token{.Star, transmute([]u8)string("*")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("x")},
        lexer_pkg.Token{.Minus, transmute([]u8)string("-")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("y")},
        lexer_pkg.Token{.Star, transmute([]u8)string("*")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("y")},
        lexer_pkg.Token{.Plus, transmute([]u8)string("+")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("cx")},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("y")},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":=")},
        lexer_pkg.Token{.Integer, transmute([]u8)string("2")},
        lexer_pkg.Token{.Star, transmute([]u8)string("*")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("x")},
        lexer_pkg.Token{.Star, transmute([]u8)string("*")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("y")},
        lexer_pkg.Token{.Plus, transmute([]u8)string("+")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("cy")},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("x")},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":=")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("xtemp")},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("iter")},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":=")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("iter")},
        lexer_pkg.Token{.Plus, transmute([]u8)string("+")},
        lexer_pkg.Token{.Integer, transmute([]u8)string("1")},

        lexer_pkg.Token{.End, transmute([]u8)string("end")},

        lexer_pkg.Token{.Ret, transmute([]u8)string("ret")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("iter")},

        lexer_pkg.Token{.End, transmute([]u8)string("end")},

        // script main body
        lexer_pkg.Token{.Identifier, transmute([]u8)string("height")},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":=")},
        lexer_pkg.Token{.Integer, transmute([]u8)string("16")},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("width")},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":=")},
        lexer_pkg.Token{.Integer, transmute([]u8)string("22")},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("yi")},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":=")},
        lexer_pkg.Token{.Integer, transmute([]u8)string("0")},

        lexer_pkg.Token{.While, transmute([]u8)string("while")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("yi")},
        lexer_pkg.Token{.Lt, transmute([]u8)string("<")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("height")},
        lexer_pkg.Token{.Do, transmute([]u8)string("do")},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("y0")},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":=")},
        lexer_pkg.Token{.LeftParen, transmute([]u8)string("(")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("yi")},
        lexer_pkg.Token{.Slash, transmute([]u8)string("/")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("height")},
        lexer_pkg.Token{.RightParen, transmute([]u8)string(")")},
        lexer_pkg.Token{.Star, transmute([]u8)string("*")},
        lexer_pkg.Token{.Float, transmute([]u8)string("2.0")},
        lexer_pkg.Token{.Minus, transmute([]u8)string("-")},
        lexer_pkg.Token{.Float, transmute([]u8)string("1.0")},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("xi")},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":=")},
        lexer_pkg.Token{.Integer, transmute([]u8)string("0")},

        lexer_pkg.Token{.While, transmute([]u8)string("while")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("xi")},
        lexer_pkg.Token{.Lt, transmute([]u8)string("<")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("width")},
        lexer_pkg.Token{.Do, transmute([]u8)string("do")},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("x0")},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":=")},
        lexer_pkg.Token{.LeftParen, transmute([]u8)string("(")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("xi")},
        lexer_pkg.Token{.Slash, transmute([]u8)string("/")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("width")},
        lexer_pkg.Token{.RightParen, transmute([]u8)string(")")},
        lexer_pkg.Token{.Star, transmute([]u8)string("*")},
        lexer_pkg.Token{.Float, transmute([]u8)string("3.5")},
        lexer_pkg.Token{.Minus, transmute([]u8)string("-")},
        lexer_pkg.Token{.Float, transmute([]u8)string("2.5")},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("m")},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":=")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("mandelbrot")},
        lexer_pkg.Token{.LeftParen, transmute([]u8)string("(")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("x0")},
        lexer_pkg.Token{.Comma, transmute([]u8)string(",")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("y0")},
        lexer_pkg.Token{.RightParen, transmute([]u8)string(")")},

        lexer_pkg.Token{.If, transmute([]u8)string("if")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("m")},
        lexer_pkg.Token{.Eq, transmute([]u8)string("==")},
        lexer_pkg.Token{.Integer, transmute([]u8)string("16")},
        lexer_pkg.Token{.Then, transmute([]u8)string("then")},

        lexer_pkg.Token{.Print, transmute([]u8)string("print")},
        lexer_pkg.Token{.String, transmute([]u8)string("\"⚡\"")},

        lexer_pkg.Token{.Else, transmute([]u8)string("else")},

        lexer_pkg.Token{.Print, transmute([]u8)string("print")},
        lexer_pkg.Token{.String, transmute([]u8)string("\" \"")},

        lexer_pkg.Token{.End, transmute([]u8)string("end")},
        
        lexer_pkg.Token{.Identifier, transmute([]u8)string("xi")},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":=")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("xi")},
        lexer_pkg.Token{.Plus, transmute([]u8)string("+")},
        lexer_pkg.Token{.Integer, transmute([]u8)string("1")},

        lexer_pkg.Token{.End, transmute([]u8)string("end")},

        lexer_pkg.Token{.Println, transmute([]u8)string("println")},
        lexer_pkg.Token{.String, transmute([]u8)string("\"\"")},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("yi")},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":=")},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("yi")},
        lexer_pkg.Token{.Plus, transmute([]u8)string("+")},
        lexer_pkg.Token{.Integer, transmute([]u8)string("1")},

        lexer_pkg.Token{.End, transmute([]u8)string("end")},
    }
    expecteds_size := len(expecteds)

    for tok, index in tokens {
        sb := strings.builder_make(allocator = msgs_arena_allocator)
        if index >= expecteds_size {
            testing.fail_now(t,
                             fmt.sbprintf(&sb, "Lexed to many tokens, expected %d, got %d",
                                          expecteds_size,
                                          len(tokens)))
        }

        strings.builder_reset(&sb)
        testing.expect(t, tok.token_type == expecteds[index].token_type,
                       fmt.sbprintf(&sb, "<%d-th> Expected token type %q, got %q", index,
                                    lexer_pkg.token_type_to_string(expecteds[index].token_type),
                                    lexer_pkg.token_type_to_string(tok.token_type)))
        strings.builder_reset(&sb)
        testing.expect(t, slice.simple_equal(tok.lexeme, expecteds[index].lexeme),
                       fmt.sbprintf(&sb, "<%d-th> Expected lexeme to be %q, got %q", index,
                                    expecteds[index].lexeme,
                                    tok.lexeme))
    }
}
