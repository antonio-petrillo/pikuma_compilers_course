package lexer_test

import "core:fmt"
import "core:log"
import "core:slice"
import "core:strings"
import "core:testing"
import "core:mem/virtual"

import lexer_pkg "pinky:lexer"
import "pinky:token"

check_tokens_match_expected :: proc(t: ^testing.T, actual: [dynamic]token.Token, expected: []token.Token) {
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
                                    token.token_type_to_string(expected[index].token_type),
                                    token.token_type_to_string(tok.token_type)))
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

    expected := []token.Token {
        token.Token{.LeftParen, transmute([]u8)string("("), 1},
        token.Token{.RightParen, transmute([]u8)string(")"), 1}, 
        token.Token{.LeftSquare, transmute([]u8)string("["), 1},
        token.Token{.RightSquare, transmute([]u8)string("]"), 1},
        token.Token{.LeftCurly, transmute([]u8)string("{"), 1},
        token.Token{.RightCurly, transmute([]u8)string("}"), 1},
        token.Token{.Comma, transmute([]u8)string(","), 2},
        token.Token{.Dot, transmute([]u8)string("."), 2},
        token.Token{.Plus, transmute([]u8)string("+"), 2},
        token.Token{.Minus, transmute([]u8)string("-"), 2},
        token.Token{.Star, transmute([]u8)string("*"), 2},
        token.Token{.Slash, transmute([]u8)string("/"), 2},
        token.Token{.Caret, transmute([]u8)string("^"), 2},
        token.Token{.Mod, transmute([]u8)string("%"), 2},
        token.Token{.Semicolon, transmute([]u8)string(";"), 2},
        token.Token{.Question, transmute([]u8)string("?"), 2},
        token.Token{.Colon, transmute([]u8)string(":"), 3},
        token.Token{.Assign, transmute([]u8)string(":="), 3},
        token.Token{.Not, transmute([]u8)string("~"), 4},
        token.Token{.Ne, transmute([]u8)string("~="), 4},
        token.Token{.Eq, transmute([]u8)string("=="), 4},
        token.Token{.Gt, transmute([]u8)string(">"), 5},
        token.Token{.Ge, transmute([]u8)string(">="), 5},
        token.Token{.GtGt, transmute([]u8)string(">>"), 5},
        token.Token{.Lt, transmute([]u8)string("<"), 6},
        token.Token{.Le, transmute([]u8)string("<="), 6},
        token.Token{.LtLt, transmute([]u8)string("<<"), 6},
        token.Token{.String, transmute([]u8)string("\"a string literal\""), 7},
        token.Token{.Integer, transmute([]u8)string("1234567890"), 8},
        token.Token{.Float, transmute([]u8)string("12345.6789"), 9},
        token.Token{.If, transmute([]u8)string("if"), 10},
        token.Token{.Then, transmute([]u8)string("then"), 10},
        token.Token{.Else, transmute([]u8)string("else"), 10},
        token.Token{.True, transmute([]u8)string("true"), 11},
        token.Token{.False, transmute([]u8)string("false"), 11},
        token.Token{.And, transmute([]u8)string("and"), 12},
        token.Token{.Or, transmute([]u8)string("or"), 12},
        token.Token{.While, transmute([]u8)string("while"), 13},
        token.Token{.Do, transmute([]u8)string("do"), 13},
        token.Token{.For, transmute([]u8)string("for"), 13},
        token.Token{.Func, transmute([]u8)string("func"), 14},
        token.Token{.Null, transmute([]u8)string("null"), 15},
        token.Token{.End, transmute([]u8)string("end"), 15},
        token.Token{.Print, transmute([]u8)string("print"), 16},
        token.Token{.Println, transmute([]u8)string("println"), 16},
        token.Token{.Ret, transmute([]u8)string("ret"), 17},
        token.Token{.Identifier, transmute([]u8)string("varname"), 18}, 
        token.Token{.Identifier, transmute([]u8)string("another_var"), 19}, 
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

    expected := []token.Token {
        // func definition
        token.Token{.Func, transmute([]u8)string("func"), 1},
        token.Token{.Identifier, transmute([]u8)string("mandelbrot"), 1}, 
        token.Token{.LeftParen, transmute([]u8)string("("), 1},
        token.Token{.Identifier, transmute([]u8)string("cx"), 1}, 
        token.Token{.Comma, transmute([]u8)string(","), 1}, 
        token.Token{.Identifier, transmute([]u8)string("cy"), 1}, 
        token.Token{.RightParen, transmute([]u8)string(")"), 1},

        token.Token{.Identifier, transmute([]u8)string("x"), 2},
        token.Token{.Assign, transmute([]u8)string(":="), 2},
        token.Token{.Integer, transmute([]u8)string("0"), 2},

        token.Token{.Identifier, transmute([]u8)string("y"), 3},
        token.Token{.Assign, transmute([]u8)string(":="), 3},
        token.Token{.Integer, transmute([]u8)string("0"), 3},

        token.Token{.Identifier, transmute([]u8)string("iter"), 4},
        token.Token{.Assign, transmute([]u8)string(":="), 4},
        token.Token{.Integer, transmute([]u8)string("0"), 4},

        token.Token{.Identifier, transmute([]u8)string("max"), 5},
        token.Token{.Assign, transmute([]u8)string(":="), 5},
        token.Token{.Integer, transmute([]u8)string("16"), 5},

        token.Token{.While, transmute([]u8)string("while"), 6},
        token.Token{.Identifier, transmute([]u8)string("x"), 6},
        token.Token{.Star, transmute([]u8)string("*"), 6},
        token.Token{.Identifier, transmute([]u8)string("x"), 6},
        token.Token{.Plus, transmute([]u8)string("+"), 6},
        token.Token{.Identifier, transmute([]u8)string("y"), 6},
        token.Token{.Star, transmute([]u8)string("*"), 6},
        token.Token{.Identifier, transmute([]u8)string("y"), 6},
        token.Token{.Le, transmute([]u8)string("<="), 6},
        token.Token{.Integer, transmute([]u8)string("4"), 6},
        token.Token{.And, transmute([]u8)string("and"), 6},
        token.Token{.Identifier, transmute([]u8)string("iter"), 6},
        token.Token{.Lt, transmute([]u8)string("<"), 6},
        token.Token{.Identifier, transmute([]u8)string("max"), 6},
        token.Token{.Do, transmute([]u8)string("do"), 6},

        token.Token{.Identifier, transmute([]u8)string("xtemp"), 7},
        token.Token{.Assign, transmute([]u8)string(":="), 7},
        token.Token{.Identifier, transmute([]u8)string("x"), 7},
        token.Token{.Star, transmute([]u8)string("*"), 7},
        token.Token{.Identifier, transmute([]u8)string("x"), 7},
        token.Token{.Minus, transmute([]u8)string("-"), 7},
        token.Token{.Identifier, transmute([]u8)string("y"), 7},
        token.Token{.Star, transmute([]u8)string("*"), 7},
        token.Token{.Identifier, transmute([]u8)string("y"), 7},
        token.Token{.Plus, transmute([]u8)string("+"), 7},
        token.Token{.Identifier, transmute([]u8)string("cx"), 7},

        token.Token{.Identifier, transmute([]u8)string("y"), 8},
        token.Token{.Assign, transmute([]u8)string(":="), 8},
        token.Token{.Integer, transmute([]u8)string("2"), 8},
        token.Token{.Star, transmute([]u8)string("*"), 8},
        token.Token{.Identifier, transmute([]u8)string("x"), 8},
        token.Token{.Star, transmute([]u8)string("*"), 8},
        token.Token{.Identifier, transmute([]u8)string("y"), 8},
        token.Token{.Plus, transmute([]u8)string("+"), 8},
        token.Token{.Identifier, transmute([]u8)string("cy"), 8},

        token.Token{.Identifier, transmute([]u8)string("x"), 9},
        token.Token{.Assign, transmute([]u8)string(":="), 9},
        token.Token{.Identifier, transmute([]u8)string("xtemp"), 9},

        token.Token{.Identifier, transmute([]u8)string("iter"), 10},
        token.Token{.Assign, transmute([]u8)string(":="), 10},
        token.Token{.Identifier, transmute([]u8)string("iter"), 10},
        token.Token{.Plus, transmute([]u8)string("+"), 10},
        token.Token{.Integer, transmute([]u8)string("1"), 10},

        token.Token{.End, transmute([]u8)string("end"), 11},

        token.Token{.Ret, transmute([]u8)string("ret"), 12},
        token.Token{.Identifier, transmute([]u8)string("iter"), 12},

        token.Token{.End, transmute([]u8)string("end"), 13},

        // script main body
        token.Token{.Identifier, transmute([]u8)string("height"), 17},
        token.Token{.Assign, transmute([]u8)string(":="), 17},
        token.Token{.Integer, transmute([]u8)string("16"), 17},

        token.Token{.Identifier, transmute([]u8)string("width"), 18},
        token.Token{.Assign, transmute([]u8)string(":="), 18},
        token.Token{.Integer, transmute([]u8)string("22"), 18},

        token.Token{.Identifier, transmute([]u8)string("yi"), 19},
        token.Token{.Assign, transmute([]u8)string(":="), 19},
        token.Token{.Integer, transmute([]u8)string("0"), 19},

        token.Token{.While, transmute([]u8)string("while"), 20},
        token.Token{.Identifier, transmute([]u8)string("yi"), 20},
        token.Token{.Lt, transmute([]u8)string("<"), 20},
        token.Token{.Identifier, transmute([]u8)string("height"), 20},
        token.Token{.Do, transmute([]u8)string("do"), 20},

        token.Token{.Identifier, transmute([]u8)string("y0"), 21},
        token.Token{.Assign, transmute([]u8)string(":="), 21},
        token.Token{.LeftParen, transmute([]u8)string("("), 21},
        token.Token{.Identifier, transmute([]u8)string("yi"), 21},
        token.Token{.Slash, transmute([]u8)string("/"), 21},
        token.Token{.Identifier, transmute([]u8)string("height"), 21},
        token.Token{.RightParen, transmute([]u8)string(")"), 21},
        token.Token{.Star, transmute([]u8)string("*"), 21},
        token.Token{.Float, transmute([]u8)string("2.0"), 21},
        token.Token{.Minus, transmute([]u8)string("-"), 21},
        token.Token{.Float, transmute([]u8)string("1.0"), 21},

        token.Token{.Identifier, transmute([]u8)string("xi"), 22},
        token.Token{.Assign, transmute([]u8)string(":="), 22},
        token.Token{.Integer, transmute([]u8)string("0"), 22},

        token.Token{.While, transmute([]u8)string("while"), 23},
        token.Token{.Identifier, transmute([]u8)string("xi"), 23},
        token.Token{.Lt, transmute([]u8)string("<"), 23},
        token.Token{.Identifier, transmute([]u8)string("width"), 23},
        token.Token{.Do, transmute([]u8)string("do"), 23},

        token.Token{.Identifier, transmute([]u8)string("x0"), 24},
        token.Token{.Assign, transmute([]u8)string(":="), 24},
        token.Token{.LeftParen, transmute([]u8)string("("), 24},
        token.Token{.Identifier, transmute([]u8)string("xi"), 24},
        token.Token{.Slash, transmute([]u8)string("/"), 24},
        token.Token{.Identifier, transmute([]u8)string("width"), 24},
        token.Token{.RightParen, transmute([]u8)string(")"), 24},
        token.Token{.Star, transmute([]u8)string("*"), 24},
        token.Token{.Float, transmute([]u8)string("3.5"), 24},
        token.Token{.Minus, transmute([]u8)string("-"), 24},
        token.Token{.Float, transmute([]u8)string("2.5"), 24},

        token.Token{.Identifier, transmute([]u8)string("m"), 25},
        token.Token{.Assign, transmute([]u8)string(":="), 25},
        token.Token{.Identifier, transmute([]u8)string("mandelbrot"), 25},
        token.Token{.LeftParen, transmute([]u8)string("("), 25},
        token.Token{.Identifier, transmute([]u8)string("x0"), 25},
        token.Token{.Comma, transmute([]u8)string(","), 25},
        token.Token{.Identifier, transmute([]u8)string("y0"), 25},
        token.Token{.RightParen, transmute([]u8)string(")"), 25},

        token.Token{.If, transmute([]u8)string("if"), 26},
        token.Token{.Identifier, transmute([]u8)string("m"), 26},
        token.Token{.Eq, transmute([]u8)string("=="), 26},
        token.Token{.Integer, transmute([]u8)string("16"), 26},
        token.Token{.Then, transmute([]u8)string("then"), 26},

        token.Token{.Print, transmute([]u8)string("print"), 27},
        token.Token{.String, transmute([]u8)string("\"⚡\""), 27},

        token.Token{.Else, transmute([]u8)string("else"), 28},

        token.Token{.Print, transmute([]u8)string("print"), 29},
        token.Token{.String, transmute([]u8)string("\" \""), 29},

        token.Token{.End, transmute([]u8)string("end"), 30},
        
        token.Token{.Identifier, transmute([]u8)string("xi"), 31},
        token.Token{.Assign, transmute([]u8)string(":="), 31},
        token.Token{.Identifier, transmute([]u8)string("xi"), 31},
        token.Token{.Plus, transmute([]u8)string("+"), 31},
        token.Token{.Integer, transmute([]u8)string("1"), 31},

        token.Token{.End, transmute([]u8)string("end"), 32},

        token.Token{.Println, transmute([]u8)string("println"), 33},
        token.Token{.String, transmute([]u8)string("\"\""), 33},

        token.Token{.Identifier, transmute([]u8)string("yi"), 34},
        token.Token{.Assign, transmute([]u8)string(":="), 34},
        token.Token{.Identifier, transmute([]u8)string("yi"), 34},
        token.Token{.Plus, transmute([]u8)string("+"), 34},
        token.Token{.Integer, transmute([]u8)string("1"), 34},

        token.Token{.End, transmute([]u8)string("end"), 35},
    }

    if err != lexer_pkg.Tokenize_Error.None {
        log.infof("Expected error := %s", lexer_pkg.tokenize_error_to_string(err))
        testing.fail(t)
    }

    check_tokens_match_expected(t, tokens, expected)
}
