package main

import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:os"

import "pinky:ast"
import "pinky:interpreter"
import "pinky:lexer"
import "pinky:token"
import "pinky:parser"

main :: proc() {
    if len(os.args) != 2 {
        fmt.eprintf("Usage: pinky <scriptname>")
        os.exit(1)
    }

    // Setup tracking allocator
    default_allocator := context.allocator
    tracking_allocator:  mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking_allocator, default_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)

    reset_tracking_allocator :: proc(a: ^mem.Tracking_Allocator) -> bool {
        err := false

        for _, value in a.allocation_map {
            fmt.printf("%v: Leaked %v bytes\n", value.location, value.size) 
            err = true
        }
        mem.tracking_allocator_clear(a)

        return err
    }
    defer {
        if reset_tracking_allocator(&tracking_allocator) {
            fmt.printf("Check for memory leaks!\n")
        }  

        mem.tracking_allocator_destroy(&tracking_allocator)
    } 


    filename := os.args[1]
    source, err := os.read_entire_file_from_filename_or_err(filename)

    {
        fmt.printf("#########################\n")
        fmt.printf("#####  SOURCE CODE: #####\n")
        fmt.printf("#########################\n")

        defer fmt.print("#########################\n#########################\n\n")

        fmt.printf("%s\n", source)
    }

    if err != os.General_Error.None {
        fmt.eprintf("Error reading file <%s>, error := %s", filename, os.error_string(err))
        os.exit(1)
    }

    arena: virtual.Arena
    defer virtual.arena_destroy(&arena)

    tokens, lexer_err := lexer.tokenize(source, &arena)

    if lexer_err != lexer.Tokenize_Error.None {
        fmt.eprintf("Error lexing source: %s\n", lexer.tokenize_error_to_string(lexer_err))
        fmt.eprintf("Source: %s\n", source)
        os.exit(1)
    }
    delete(source)
    defer delete(tokens)

    {
        fmt.print("#########################\n")
        fmt.print("##### TOKENS LEXED: #####\n")
        fmt.print("#########################\n")
        defer fmt.print("#########################\n#########################\n\n")

        for &tok, index in tokens {
            str := token.token_to_string(tok)
            defer delete(str)
            fmt.printf("tokens[%2d-th] := %s\n", index, str)
        }
    }

    nodes, parser_err := parser.parse(tokens[:], &arena)
    if parser_err != parser.Parser_Error.None {
        fmt.eprintf("Error parsing tokens: %s\n", parser.parser_error_to_string(parser_err))
        os.exit(1)
    }

    {
        fmt.print("###########################\n")
        fmt.print("#######  AST NODES: #######\n")
        fmt.print("###########################\n")
        defer fmt.print("#########################\n#########################\n\n")

        for &node, index in nodes {
            str: string
            switch node_ in node {
            case ast.Expr: str = ast.expr_to_string(node_) 
            case ast.Stmt: str = ast.stmt_to_string(node_) 
            }
            defer delete(str)
            fmt.print("###########################\n")
            fmt.printf("node[%d] :=\n%s\n", index, str)
            fmt.print("###########################\n\n")
        }
    }

    {
        fmt.print("###########################\n")
        fmt.print("#######  TREE WALK: #######\n")
        fmt.print("###########################\n")
        defer fmt.print("\n#########################\n#########################\n\n")

        for &node in nodes {
            str: string
            switch node_ in node {
            case ast.Expr: str = ast.expr_to_string_summary(node_) 
            case ast.Stmt: str = ast.stmt_to_string_summary(node_) 
            }
            defer delete(str)
            _, err := interpreter.interpret(node, &arena)
            if err != interpreter.Runtime_Error.None {
                fmt.printf("Interpreter Error: %s\n", interpreter.interpreter_error_to_string(err))
                continue
            }
        }
    }

}
