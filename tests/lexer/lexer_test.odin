package lexer_test

import "core:fmt"
import "core:log"
import "core:mem/virtual"
import "core:strings"
import "core:testing"

import "pinky:lexer"
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
        testing.expect(t, tok.lexeme == expected[index].lexeme,
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
all_token_source_data := #load("lexer_test_data.pinky")

@(test)
test_all_tokens_are_lexed_correctly :: proc(t: ^testing.T) {
    lexer_arena: virtual.Arena
    defer virtual.arena_destroy(&lexer_arena)

    tokens, err := lexer.tokenize(all_token_source_data, &lexer_arena)

    expected := []token.Token {
        token.Token{.LeftParen, "(", 1},
        token.Token{.RightParen, ")", 1}, 
        token.Token{.LeftSquare, "[", 1},
        token.Token{.RightSquare, "]", 1},
        token.Token{.LeftCurly, "{", 1},
        token.Token{.RightCurly, "}", 1},
        token.Token{.Comma, ",", 2},
        token.Token{.Dot, ".", 2},
        token.Token{.Plus, "+", 2},
        token.Token{.Minus, "-", 2},
        token.Token{.Star, "*", 2},
        token.Token{.Slash, "/", 2},
        token.Token{.Caret, "^", 2},
        token.Token{.Mod, "%", 2},
        token.Token{.Semicolon, ";", 2},
        token.Token{.Question, "?", 2},
        token.Token{.Colon, ":", 3},
        token.Token{.Assign, ":=", 3},
        token.Token{.Eq, "=", 4},
        token.Token{.Not, "~", 4},
        token.Token{.Ne, "~=", 4},
        token.Token{.EqEq, "==", 4},
        token.Token{.Gt, ">", 5},
        token.Token{.Ge, ">=", 5},
        token.Token{.GtGt, ">>", 5},
        token.Token{.Lt, "<", 6},
        token.Token{.Le, "<=", 6},
        token.Token{.LtLt, "<<", 6},
        token.Token{.String, "\"a string literal\"", 7},
        token.Token{.Integer, "1234567890", 8},
        token.Token{.Float, "12345.6789", 9},
        token.Token{.If, "if", 10},
        token.Token{.Then, "then", 10},
        token.Token{.Else, "else", 10},
        token.Token{.True, "true", 11},
        token.Token{.False, "false", 11},
        token.Token{.And, "and", 12},
        token.Token{.Or, "or", 12},
        token.Token{.While, "while", 13},
        token.Token{.Do, "do", 13},
        token.Token{.For, "for", 13},
        token.Token{.Func, "func", 14},
        token.Token{.Null, "null", 15},
        token.Token{.End, "end", 15},
        token.Token{.Print, "print", 16},
        token.Token{.Println, "println", 16},
        token.Token{.Ret, "ret", 17},
        token.Token{.Identifier, "varname", 18}, 
        token.Token{.Identifier, "another_var", 19}, 
    }

    if err != lexer.Tokenize_Error.None {
        log.infof("Expected error := %s", lexer.tokenize_error_to_string(err))
        testing.fail(t)
    }

    check_tokens_match_expected(t, tokens, expected)
}

@(rodata)
simple_pinky_program_data := #load("mandelbrot.pinky")

@(test)
test_lex_a_simple_proper_program :: proc(t: ^testing.T) {
    lexer_arena: virtual.Arena
    defer virtual.arena_destroy(&lexer_arena)

    tokens, err := lexer.tokenize(simple_pinky_program_data, &lexer_arena)

    expected := []token.Token {
        // func definition
        token.Token{.Func, "func", 1},
        token.Token{.Identifier, "mandelbrot", 1}, 
        token.Token{.LeftParen, "(", 1},
        token.Token{.Identifier, "cx", 1}, 
        token.Token{.Comma, ",", 1}, 
        token.Token{.Identifier, "cy", 1}, 
        token.Token{.RightParen, ")", 1},

        token.Token{.Identifier, "x", 2},
        token.Token{.Assign, ":=", 2},
        token.Token{.Integer, "0", 2},

        token.Token{.Identifier, "y", 3},
        token.Token{.Assign, ":=", 3},
        token.Token{.Integer, "0", 3},

        token.Token{.Identifier, "iter", 4},
        token.Token{.Assign, ":=", 4},
        token.Token{.Integer, "0", 4},

        token.Token{.Identifier, "max", 5},
        token.Token{.Assign, ":=", 5},
        token.Token{.Integer, "16", 5},

        token.Token{.While, "while", 6},
        token.Token{.Identifier, "x", 6},
        token.Token{.Star, "*", 6},
        token.Token{.Identifier, "x", 6},
        token.Token{.Plus, "+", 6},
        token.Token{.Identifier, "y", 6},
        token.Token{.Star, "*", 6},
        token.Token{.Identifier, "y", 6},
        token.Token{.Le, "<=", 6},
        token.Token{.Integer, "4", 6},
        token.Token{.And, "and", 6},
        token.Token{.Identifier, "iter", 6},
        token.Token{.Lt, "<", 6},
        token.Token{.Identifier, "max", 6},
        token.Token{.Do, "do", 6},

        token.Token{.Identifier, "xtemp", 7},
        token.Token{.Assign, ":=", 7},
        token.Token{.Identifier, "x", 7},
        token.Token{.Star, "*", 7},
        token.Token{.Identifier, "x", 7},
        token.Token{.Minus, "-", 7},
        token.Token{.Identifier, "y", 7},
        token.Token{.Star, "*", 7},
        token.Token{.Identifier, "y", 7},
        token.Token{.Plus, "+", 7},
        token.Token{.Identifier, "cx", 7},

        token.Token{.Identifier, "y", 8},
        token.Token{.Assign, ":=", 8},
        token.Token{.Integer, "2", 8},
        token.Token{.Star, "*", 8},
        token.Token{.Identifier, "x", 8},
        token.Token{.Star, "*", 8},
        token.Token{.Identifier, "y", 8},
        token.Token{.Plus, "+", 8},
        token.Token{.Identifier, "cy", 8},

        token.Token{.Identifier, "x", 9},
        token.Token{.Assign, ":=", 9},
        token.Token{.Identifier, "xtemp", 9},

        token.Token{.Identifier, "iter", 10},
        token.Token{.Assign, ":=", 10},
        token.Token{.Identifier, "iter", 10},
        token.Token{.Plus, "+", 10},
        token.Token{.Integer, "1", 10},

        token.Token{.End, "end", 11},

        token.Token{.Ret, "ret", 12},
        token.Token{.Identifier, "iter", 12},

        token.Token{.End, "end", 13},

        // script main body
        token.Token{.Identifier, "height", 17},
        token.Token{.Assign, ":=", 17},
        token.Token{.Integer, "16", 17},

        token.Token{.Identifier, "width", 18},
        token.Token{.Assign, ":=", 18},
        token.Token{.Integer, "22", 18},

        token.Token{.Identifier, "yi", 19},
        token.Token{.Assign, ":=", 19},
        token.Token{.Integer, "0", 19},

        token.Token{.While, "while", 20},
        token.Token{.Identifier, "yi", 20},
        token.Token{.Lt, "<", 20},
        token.Token{.Identifier, "height", 20},
        token.Token{.Do, "do", 20},

        token.Token{.Identifier, "y0", 21},
        token.Token{.Assign, ":=", 21},
        token.Token{.LeftParen, "(", 21},
        token.Token{.Identifier, "yi", 21},
        token.Token{.Slash, "/", 21},
        token.Token{.Identifier, "height", 21},
        token.Token{.RightParen, ")", 21},
        token.Token{.Star, "*", 21},
        token.Token{.Float, "2.0", 21},
        token.Token{.Minus, "-", 21},
        token.Token{.Float, "1.0", 21},

        token.Token{.Identifier, "xi", 22},
        token.Token{.Assign, ":=", 22},
        token.Token{.Integer, "0", 22},

        token.Token{.While, "while", 23},
        token.Token{.Identifier, "xi", 23},
        token.Token{.Lt, "<", 23},
        token.Token{.Identifier, "width", 23},
        token.Token{.Do, "do", 23},

        token.Token{.Identifier, "x0", 24},
        token.Token{.Assign, ":=", 24},
        token.Token{.LeftParen, "(", 24},
        token.Token{.Identifier, "xi", 24},
        token.Token{.Slash, "/", 24},
        token.Token{.Identifier, "width", 24},
        token.Token{.RightParen, ")", 24},
        token.Token{.Star, "*", 24},
        token.Token{.Float, "3.5", 24},
        token.Token{.Minus, "-", 24},
        token.Token{.Float, "2.5", 24},

        token.Token{.Identifier, "m", 25},
        token.Token{.Assign, ":=", 25},
        token.Token{.Identifier, "mandelbrot", 25},
        token.Token{.LeftParen, "(", 25},
        token.Token{.Identifier, "x0", 25},
        token.Token{.Comma, ",", 25},
        token.Token{.Identifier, "y0", 25},
        token.Token{.RightParen, ")", 25},

        token.Token{.If, "if", 26},
        token.Token{.Identifier, "m", 26},
        token.Token{.EqEq, "==", 26},
        token.Token{.Integer, "16", 26},
        token.Token{.Then, "then", 26},

        token.Token{.Print, "print", 27},
        token.Token{.String, "\"⚡\"", 27},

        token.Token{.Else, "else", 28},

        token.Token{.Print, "print", 29},
        token.Token{.String, "\" \"", 29},

        token.Token{.End, "end", 30},
        
        token.Token{.Identifier, "xi", 31},
        token.Token{.Assign, ":=", 31},
        token.Token{.Identifier, "xi", 31},
        token.Token{.Plus, "+", 31},
        token.Token{.Integer, "1", 31},

        token.Token{.End, "end", 32},

        token.Token{.Println, "println", 33},
        token.Token{.String, "\"\"", 33},

        token.Token{.Identifier, "yi", 34},
        token.Token{.Assign, ":=", 34},
        token.Token{.Identifier, "yi", 34},
        token.Token{.Plus, "+", 34},
        token.Token{.Integer, "1", 34},

        token.Token{.End, "end", 35},
    }

    if err != lexer.Tokenize_Error.None {
        log.infof("Expected error := %s", lexer.tokenize_error_to_string(err))
        testing.fail(t)
    }

    check_tokens_match_expected(t, tokens, expected)
}
