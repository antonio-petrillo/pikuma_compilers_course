package main

import "core:fmt"
import "core:mem"
import "core:os"

import "lexer"
import "token"

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
    defer delete(source)
    if err != os.General_Error.None {
        fmt.eprintf("Error reading file <%s>, error := %s", filename, os.error_string(err))
        os.exit(1)
    }

    fmt.printf("source:\n%s\n", source)
    _ = source

    the_lexer := lexer.new_lexer(source)
    tokens := lexer.tokenize(&the_lexer)
    defer delete(tokens)

    for &tok, index in tokens {
        str := token.token_to_string(tok)
        defer delete(str)
        fmt.printf("tokens[%2d-th] := %s\n", index, str)
    }

}
