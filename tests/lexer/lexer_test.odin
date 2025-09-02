package lexer_test

import "core:fmt"
import "core:log"
import "core:slice"
import "core:strings"
import "core:testing"
import "core:mem/virtual"

import lexer_pkg "../../src/lexer"

check_tokens_match_expected :: proc(t: ^testing.T, actual: [dynamic]lexer_pkg.Token, expected: []lexer_pkg.Token) {
    msgs_arena: virtual.Arena
    msgs_arena_allocator := virtual.arena_allocator(&msgs_arena)
    defer virtual.arena_destroy(&msgs_arena)

    sb := strings.builder_make(allocator = msgs_arena_allocator)
    if len(actual) != len(expected) {
        testing.fail_now(t, fmt.sbprintf(&sb, "Lexed to wrong number of tokens, expected %d, got %d", len(expected), len(actual)))
    }

    for tok, index in actual {
        strings.builder_reset(&sb)
        testing.expect(t, tok.token_type == expected[index].token_type,
                       fmt.sbprintf(&sb, "Expected token type %q, got %q",
                                    lexer_pkg.token_type_to_string(expected[index].token_type),
                                    lexer_pkg.token_type_to_string(tok.token_type)))
        strings.builder_reset(&sb)
        testing.expect(t, slice.simple_equal(tok.lexeme, expected[index].lexeme),
                       fmt.sbprintf(&sb, "Expected lexeme to be %q, got %q",
                                    expected[index].lexeme,
                                    tok.lexeme))
        strings.builder_reset(&sb)
        testing.expect(t, tok.line == expected[index].line, 
                       fmt.sbprintf(&sb, "Expected line to be %d, got %d",
                                    expected[index].line,
                                    tok.line))
    }
}

@(rodata)
all_token_source_data := #load("./lexer_test_data.pinky")

@(test)
test_all_tokens_are_lexed_correctly :: proc(t: ^testing.T) {
    lexer := lexer_pkg.new_lexer(all_token_source_data) 
    tokens, err := lexer_pkg.tokenize(&lexer)
    defer delete(tokens)

    msgs_arena: virtual.Arena
    msgs_arena_allocator := virtual.arena_allocator(&msgs_arena)
    defer virtual.arena_destroy(&msgs_arena)

    expected := []lexer_pkg.Token {
        lexer_pkg.Token{.LeftParen, transmute([]u8)string("("), 1},
        lexer_pkg.Token{.RightParen, transmute([]u8)string(")"), 1}, 
        lexer_pkg.Token{.LeftSquare, transmute([]u8)string("["), 1},
        lexer_pkg.Token{.RightSquare, transmute([]u8)string("]"), 1},
        lexer_pkg.Token{.LeftCurly, transmute([]u8)string("{"), 1},
        lexer_pkg.Token{.RightCurly, transmute([]u8)string("}"), 1},
        lexer_pkg.Token{.Comma, transmute([]u8)string(","), 2},
        lexer_pkg.Token{.Dot, transmute([]u8)string("."), 2},
        lexer_pkg.Token{.Plus, transmute([]u8)string("+"), 2},
        lexer_pkg.Token{.Minus, transmute([]u8)string("-"), 2},
        lexer_pkg.Token{.Star, transmute([]u8)string("*"), 2},
        lexer_pkg.Token{.Slash, transmute([]u8)string("/"), 2},
        lexer_pkg.Token{.Caret, transmute([]u8)string("^"), 2},
        lexer_pkg.Token{.Mod, transmute([]u8)string("%"), 2},
        lexer_pkg.Token{.Semicolon, transmute([]u8)string(";"), 2},
        lexer_pkg.Token{.Question, transmute([]u8)string("?"), 2},
        lexer_pkg.Token{.Colon, transmute([]u8)string(":"), 3},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":="), 3},
        lexer_pkg.Token{.Not, transmute([]u8)string("~"), 4},
        lexer_pkg.Token{.Ne, transmute([]u8)string("~="), 4},
        lexer_pkg.Token{.Eq, transmute([]u8)string("=="), 4},
        lexer_pkg.Token{.Gt, transmute([]u8)string(">"), 5},
        lexer_pkg.Token{.Ge, transmute([]u8)string(">="), 5},
        lexer_pkg.Token{.GtGt, transmute([]u8)string(">>"), 5},
        lexer_pkg.Token{.Lt, transmute([]u8)string("<"), 6},
        lexer_pkg.Token{.Le, transmute([]u8)string("<="), 6},
        lexer_pkg.Token{.LtLt, transmute([]u8)string("<<"), 6},
        lexer_pkg.Token{.String, transmute([]u8)string("\"a string literal\""), 7},
        lexer_pkg.Token{.Integer, transmute([]u8)string("1234567890"), 8},
        lexer_pkg.Token{.Float, transmute([]u8)string("12345.6789"), 9},
        lexer_pkg.Token{.If, transmute([]u8)string("if"), 10},
        lexer_pkg.Token{.Then, transmute([]u8)string("then"), 10},
        lexer_pkg.Token{.Else, transmute([]u8)string("else"), 10},
        lexer_pkg.Token{.True, transmute([]u8)string("true"), 11},
        lexer_pkg.Token{.False, transmute([]u8)string("false"), 11},
        lexer_pkg.Token{.And, transmute([]u8)string("and"), 12},
        lexer_pkg.Token{.Or, transmute([]u8)string("or"), 12},
        lexer_pkg.Token{.While, transmute([]u8)string("while"), 13},
        lexer_pkg.Token{.Do, transmute([]u8)string("do"), 13},
        lexer_pkg.Token{.For, transmute([]u8)string("for"), 13},
        lexer_pkg.Token{.Func, transmute([]u8)string("func"), 14},
        lexer_pkg.Token{.Null, transmute([]u8)string("null"), 15},
        lexer_pkg.Token{.End, transmute([]u8)string("end"), 15},
        lexer_pkg.Token{.Print, transmute([]u8)string("print"), 16},
        lexer_pkg.Token{.Println, transmute([]u8)string("println"), 16},
        lexer_pkg.Token{.Ret, transmute([]u8)string("ret"), 17},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("varname"), 18}, 
        lexer_pkg.Token{.Identifier, transmute([]u8)string("another_var"), 19}, 
    }

    if err != lexer_pkg.Tokenize_Error.None {
        log.infof("Expected error := %s", lexer_pkg.tokenize_error_to_string(err))
        testing.fail(t)
    }

    check_tokens_match_expected(t, tokens, expected)
}

@(rodata)
simple_pinky_program_data := #load("mandelbrot.pinky")

@(test)
test_lex_a_simple_proper_program :: proc(t: ^testing.T) {
    lexer := lexer_pkg.new_lexer(simple_pinky_program_data) 
    tokens, err := lexer_pkg.tokenize(&lexer)
    defer delete(tokens)

    msgs_arena: virtual.Arena
    msgs_arena_allocator := virtual.arena_allocator(&msgs_arena)
    defer virtual.arena_destroy(&msgs_arena)

    expected := []lexer_pkg.Token {
        // func definition
        lexer_pkg.Token{.Func, transmute([]u8)string("func"), 1},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("mandelbrot"), 1}, 
        lexer_pkg.Token{.LeftParen, transmute([]u8)string("("), 1},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("cx"), 1}, 
        lexer_pkg.Token{.Comma, transmute([]u8)string(","), 1}, 
        lexer_pkg.Token{.Identifier, transmute([]u8)string("cy"), 1}, 
        lexer_pkg.Token{.RightParen, transmute([]u8)string(")"), 1},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("x"), 2},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":="), 2},
        lexer_pkg.Token{.Integer, transmute([]u8)string("0"), 2},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("y"), 3},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":="), 3},
        lexer_pkg.Token{.Integer, transmute([]u8)string("0"), 3},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("iter"), 4},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":="), 4},
        lexer_pkg.Token{.Integer, transmute([]u8)string("0"), 4},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("max"), 5},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":="), 5},
        lexer_pkg.Token{.Integer, transmute([]u8)string("16"), 5},

        lexer_pkg.Token{.While, transmute([]u8)string("while"), 6},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("x"), 6},
        lexer_pkg.Token{.Star, transmute([]u8)string("*"), 6},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("x"), 6},
        lexer_pkg.Token{.Plus, transmute([]u8)string("+"), 6},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("y"), 6},
        lexer_pkg.Token{.Star, transmute([]u8)string("*"), 6},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("y"), 6},
        lexer_pkg.Token{.Le, transmute([]u8)string("<="), 6},
        lexer_pkg.Token{.Integer, transmute([]u8)string("4"), 6},
        lexer_pkg.Token{.And, transmute([]u8)string("and"), 6},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("iter"), 6},
        lexer_pkg.Token{.Lt, transmute([]u8)string("<"), 6},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("max"), 6},
        lexer_pkg.Token{.Do, transmute([]u8)string("do"), 6},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("xtemp"), 7},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":="), 7},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("x"), 7},
        lexer_pkg.Token{.Star, transmute([]u8)string("*"), 7},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("x"), 7},
        lexer_pkg.Token{.Minus, transmute([]u8)string("-"), 7},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("y"), 7},
        lexer_pkg.Token{.Star, transmute([]u8)string("*"), 7},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("y"), 7},
        lexer_pkg.Token{.Plus, transmute([]u8)string("+"), 7},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("cx"), 7},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("y"), 8},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":="), 8},
        lexer_pkg.Token{.Integer, transmute([]u8)string("2"), 8},
        lexer_pkg.Token{.Star, transmute([]u8)string("*"), 8},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("x"), 8},
        lexer_pkg.Token{.Star, transmute([]u8)string("*"), 8},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("y"), 8},
        lexer_pkg.Token{.Plus, transmute([]u8)string("+"), 8},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("cy"), 8},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("x"), 9},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":="), 9},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("xtemp"), 9},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("iter"), 10},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":="), 10},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("iter"), 10},
        lexer_pkg.Token{.Plus, transmute([]u8)string("+"), 10},
        lexer_pkg.Token{.Integer, transmute([]u8)string("1"), 10},

        lexer_pkg.Token{.End, transmute([]u8)string("end"), 11},

        lexer_pkg.Token{.Ret, transmute([]u8)string("ret"), 12},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("iter"), 12},

        lexer_pkg.Token{.End, transmute([]u8)string("end"), 13},

        // script main body
        lexer_pkg.Token{.Identifier, transmute([]u8)string("height"), 17},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":="), 17},
        lexer_pkg.Token{.Integer, transmute([]u8)string("16"), 17},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("width"), 18},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":="), 18},
        lexer_pkg.Token{.Integer, transmute([]u8)string("22"), 18},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("yi"), 19},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":="), 19},
        lexer_pkg.Token{.Integer, transmute([]u8)string("0"), 19},

        lexer_pkg.Token{.While, transmute([]u8)string("while"), 20},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("yi"), 20},
        lexer_pkg.Token{.Lt, transmute([]u8)string("<"), 20},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("height"), 20},
        lexer_pkg.Token{.Do, transmute([]u8)string("do"), 20},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("y0"), 21},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":="), 21},
        lexer_pkg.Token{.LeftParen, transmute([]u8)string("("), 21},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("yi"), 21},
        lexer_pkg.Token{.Slash, transmute([]u8)string("/"), 21},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("height"), 21},
        lexer_pkg.Token{.RightParen, transmute([]u8)string(")"), 21},
        lexer_pkg.Token{.Star, transmute([]u8)string("*"), 21},
        lexer_pkg.Token{.Float, transmute([]u8)string("2.0"), 21},
        lexer_pkg.Token{.Minus, transmute([]u8)string("-"), 21},
        lexer_pkg.Token{.Float, transmute([]u8)string("1.0"), 21},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("xi"), 22},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":="), 22},
        lexer_pkg.Token{.Integer, transmute([]u8)string("0"), 22},

        lexer_pkg.Token{.While, transmute([]u8)string("while"), 23},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("xi"), 23},
        lexer_pkg.Token{.Lt, transmute([]u8)string("<"), 23},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("width"), 23},
        lexer_pkg.Token{.Do, transmute([]u8)string("do"), 23},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("x0"), 24},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":="), 24},
        lexer_pkg.Token{.LeftParen, transmute([]u8)string("("), 24},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("xi"), 24},
        lexer_pkg.Token{.Slash, transmute([]u8)string("/"), 24},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("width"), 24},
        lexer_pkg.Token{.RightParen, transmute([]u8)string(")"), 24},
        lexer_pkg.Token{.Star, transmute([]u8)string("*"), 24},
        lexer_pkg.Token{.Float, transmute([]u8)string("3.5"), 24},
        lexer_pkg.Token{.Minus, transmute([]u8)string("-"), 24},
        lexer_pkg.Token{.Float, transmute([]u8)string("2.5"), 24},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("m"), 25},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":="), 25},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("mandelbrot"), 25},
        lexer_pkg.Token{.LeftParen, transmute([]u8)string("("), 25},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("x0"), 25},
        lexer_pkg.Token{.Comma, transmute([]u8)string(","), 25},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("y0"), 25},
        lexer_pkg.Token{.RightParen, transmute([]u8)string(")"), 25},

        lexer_pkg.Token{.If, transmute([]u8)string("if"), 26},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("m"), 26},
        lexer_pkg.Token{.Eq, transmute([]u8)string("=="), 26},
        lexer_pkg.Token{.Integer, transmute([]u8)string("16"), 26},
        lexer_pkg.Token{.Then, transmute([]u8)string("then"), 26},

        lexer_pkg.Token{.Print, transmute([]u8)string("print"), 27},
        lexer_pkg.Token{.String, transmute([]u8)string("\"⚡\""), 27},

        lexer_pkg.Token{.Else, transmute([]u8)string("else"), 28},

        lexer_pkg.Token{.Print, transmute([]u8)string("print"), 29},
        lexer_pkg.Token{.String, transmute([]u8)string("\" \""), 29},

        lexer_pkg.Token{.End, transmute([]u8)string("end"), 30},
        
        lexer_pkg.Token{.Identifier, transmute([]u8)string("xi"), 31},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":="), 31},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("xi"), 31},
        lexer_pkg.Token{.Plus, transmute([]u8)string("+"), 31},
        lexer_pkg.Token{.Integer, transmute([]u8)string("1"), 31},

        lexer_pkg.Token{.End, transmute([]u8)string("end"), 32},

        lexer_pkg.Token{.Println, transmute([]u8)string("println"), 33},
        lexer_pkg.Token{.String, transmute([]u8)string("\"\""), 33},

        lexer_pkg.Token{.Identifier, transmute([]u8)string("yi"), 34},
        lexer_pkg.Token{.Assign, transmute([]u8)string(":="), 34},
        lexer_pkg.Token{.Identifier, transmute([]u8)string("yi"), 34},
        lexer_pkg.Token{.Plus, transmute([]u8)string("+"), 34},
        lexer_pkg.Token{.Integer, transmute([]u8)string("1"), 34},

        lexer_pkg.Token{.End, transmute([]u8)string("end"), 35},
    }

    if err != lexer_pkg.Tokenize_Error.None {
        log.infof("Expected error := %s", lexer_pkg.tokenize_error_to_string(err))
        testing.fail(t)
    }

    check_tokens_match_expected(t, tokens, expected)
}
