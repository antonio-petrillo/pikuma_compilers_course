package parser

import "core:mem/virtual"

import "pinky:token"
import "pinky:ast"

Parser_Error :: enum {
    None,
    InvalidInteger,
    InvalidFloat,
    InvalidPrimaryExpression,
    UnclosedParen,
    MissingThenInIf,
    MissingEndInIf,
}

parser_error_to_string :: proc(pe: Parser_Error) -> (s: string) {
    switch pe {
    case .None: s = "None" 
    case .InvalidInteger: s = "Can't parse Integer lexeme"
    case .InvalidFloat: s = "Can't parse Float lexeme"
    case .InvalidPrimaryExpression: s = "Can't parse primary expression"
    case .UnclosedParen: s = "Missing closing parenthesis ')'"
    case .MissingThenInIf: s = "Missing 'then' after 'if <expr>'"
    case .MissingEndInIf: s = "Missing 'end' after 'if <expr> then <stmt>*'"
    }
    return
}

parse :: proc(tokens: []token.Token, parser_arena: ^virtual.Arena) -> ([dynamic]ast.AstNode, Parser_Error) {
    arena_allocator := virtual.arena_allocator(parser_arena)
    context.allocator = arena_allocator

    ast_nodes := make([dynamic]ast.AstNode)
    parser_error: Parser_Error = .None
    encountered_error := false

    parser := &Parser{
        tokens = tokens,
        current = 0,
    }

    loop: for !is_eof(parser) {
        node, err := parse_stmt(parser)
        if err != .None {
            parser_error = err
            encountered_error = true
            break loop
        }
        append(&ast_nodes, node) 
    }

    if encountered_error {
        clear(&ast_nodes)
    }

    return ast_nodes, parser_error
}
