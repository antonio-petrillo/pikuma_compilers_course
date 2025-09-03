package main

import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:os"

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

    for &tok, index in tokens {
        str := token.token_to_string(tok)
        defer delete(str)
        fmt.printf("tokens[%2d-th] := %s\n", index, str)
    }

    fmt.println()

    nodes, parser_err := parser.parse(tokens[:], &arena)
    if parser_err != parser.Parser_Error.None {
        fmt.eprintf("Error parsing tokens: %s\n", parser.parser_error_to_string(parser_err))
        os.exit(1)
    }

    for node, index in nodes {
        str := parser.ast_to_string(node)
        defer delete(str)
        fmt.printf("node[%d] := %s\n", index, str)
    }

}
