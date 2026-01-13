package parser

import "core:mem/virtual"
import "core:fmt"

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
    UnexpectedEOF,
    MissingOpenParen,
    MissingEndInFunc,
    MissingCommaInArgList,
    UnexpectedTokenInFuncDefinition,
    MissingDoInLoop,
    MissingEndInWhile,
    MissingAssignmentInFor,
    MissingEndLimitInFor,
    MissingCommaInFor,
    MissingEndInFor,
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
    case .UnexpectedEOF: s = "Unexpected EOF"
    case .MissingOpenParen: s = "Missing opening parentheses '('"
    case .MissingEndInFunc: s = "Missing 'end' after 'func <identifier> (<expr> *) <stmt>*'"
    case .MissingCommaInArgList: s = "Missing ',' in argument list"
    case .UnexpectedTokenInFuncDefinition: s = "Unexpected token in function definition"
    case .MissingDoInLoop: s = "Missing 'do' after 'while <cond_expr>'"
    case .MissingEndInWhile: s =  "Missing 'end' after 'while <expr> do <stmt>*'"
    case .MissingAssignmentInFor: s =   "Missing 'assignment' in 'for <assignment>, <end>, <step>? do <stmt>*' end"
    case .MissingCommaInFor: s = "Missing ',' in for statement"
    case .MissingEndLimitInFor: s =  "Missing '<end>' after 'for <assignment>, ...'"
    case .MissingEndInFor: s =  "Missing 'end' after 'for <assignment>, <end>, <step>? do <stmt>*'"
    }
    return
}

parse :: proc(tokens: []token.Token, parser_arena: ^virtual.Arena) -> ([dynamic]ast.Stmt, Parser_Error) {
    arena_allocator := virtual.arena_allocator(parser_arena)
    context.allocator = arena_allocator

    ast_nodes := make([dynamic]ast.Stmt)
    parser_error: Parser_Error = .None
    encountered_error := false

    parser := &Parser{
        tokens = tokens,
        current = 0,
    }

    for !is_eof(parser) {
        node, err := parse_stmt(parser)
        if err != .None {
            fmt.printf("error!\n")
            parser_error = err
            encountered_error = true
            break
        }
        append(&ast_nodes, node) 
    }

    if encountered_error {
        clear(&ast_nodes)
    }

    return ast_nodes, parser_error
}
