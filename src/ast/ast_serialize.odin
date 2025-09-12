package ast

import "core:strings"

@(private)
pad_builder :: proc(sb: ^strings.Builder, pad: int) {
    for _ in 0..<pad {
        strings.write_string(sb, "  ") // two space indentation
    }
}

expr_to_string :: proc(expr: Expr) -> (s: string) {
    sb := strings.builder_make()
    expr_to_string_with_builder(expr, &sb)
    return strings.to_string(sb)
}

expr_to_string_summary :: proc(expr: Expr) -> (s: string) {
    sb := strings.builder_make()
    expr_to_string_summary_with_builder(expr, &sb)
    return strings.to_string(sb)
}

@(private)
expr_to_string_summary_with_builder :: proc(expr: Expr, sb: ^strings.Builder) {
    switch expr_ in expr {
    case Integer:
        strings.write_i64(sb, expr_)
    case Float:
        strings.write_f64(sb, expr_, 'f')
    case String:
        strings.write_string(sb, expr_)
    case Bool:
        bool_str := expr_ ? "true" : "false"
        strings.write_string(sb, bool_str)
    case Identifier:
        strings.write_string(sb, "Identifier := '")
        strings.write_string(sb, string(expr_))
        strings.write_string(sb, "'")
    case ^BinOp:
        expr_to_string_summary_with_builder(expr_.left, sb)
        strings.write_byte(sb, ' ')
        strings.write_string(sb, binary_op_kind_to_string(expr_.kind))
        strings.write_byte(sb, ' ')
        expr_to_string_summary_with_builder(expr_.right, sb)
    case ^UnaryOp:
        strings.write_string(sb, unary_op_kind_to_string(expr_.kind))
        expr_to_string_summary_with_builder(expr_.operand, sb)
    case ^Grouping:
        strings.write_string(sb, "(")
        expr_to_string_summary_with_builder(expr_.expr, sb)
        strings.write_string(sb, ")")
    case ^FuncCall:
        strings.write_string(sb, "FuncCall := '")
        strings.write_string(sb, string(expr_.identifier))
        strings.write_string(sb, "' (...)\n")
    }
}

@(private)
expr_to_string_with_builder :: proc(expr: Expr, sb: ^strings.Builder, indentation: int = 0) {
    pad_builder(sb, indentation)
    switch expr_ in expr {
    case Integer:
        strings.write_string(sb, "Integer := <")
        strings.write_i64(sb, expr_)
        strings.write_byte(sb, '>')
    case Float:
        strings.write_string(sb, "Float := <")
        strings.write_f64(sb, expr_, 'f')
        strings.write_byte(sb, '>')
    case String:
        strings.write_string(sb, "String := '")
        strings.write_string(sb, expr_)
        strings.write_string(sb, "'")
    case Bool:
        strings.write_string(sb, "Bool := <")
        bool_str := expr_ ? "true" : "false"
        strings.write_string(sb, bool_str)
        strings.write_byte(sb, '>')
    case Identifier:
        defer {
            pad_builder(sb, indentation)
            /* strings.write_byte(sb, '}') */
            strings.write_string(sb, "}") // odin-mode broken 
        }
        strings.write_string(sb, "Identifier {\n")
        pad_builder(sb, indentation + 1)
        strings.write_string(sb, "indetifier = ")
        strings.write_string(sb, "'")
        strings.write_string(sb, string(expr_))
        strings.write_string(sb, "'\n")
    case ^BinOp:
        defer {
            pad_builder(sb, indentation)
            /* strings.write_byte(sb, '}') */
            strings.write_string(sb, "}") // odin-mode broken 
        }
        strings.write_string(sb, "BinOp := '")
        strings.write_string(sb, binary_op_kind_to_string(expr_.kind))
        strings.write_string(sb, "': {\n")
        expr_to_string_with_builder(expr_.left, sb, indentation + 1)
        strings.write_string(sb, ",\n")
        expr_to_string_with_builder(expr_.right, sb, indentation + 1)
        strings.write_byte(sb, '\n')

    case ^UnaryOp:
        defer {
            pad_builder(sb, indentation)
            /* strings.write_byte(sb, '}') */
            strings.write_string(sb, "}") // odin-mode broken 
        }
        strings.write_string(sb, "UnaryOp := '")
        strings.write_string(sb, unary_op_kind_to_string(expr_.kind))
        strings.write_string(sb, "': {\n")
        expr_to_string_with_builder(expr_.operand, sb, indentation + 1)
        strings.write_string(sb, "\n")
    case ^Grouping:
        defer {
            pad_builder(sb, indentation)
            strings.write_string(sb, "}") // odin-mode broken 
        }
        strings.write_string(sb, "Grouping {\n")
        expr_to_string_with_builder(expr_.expr, sb, indentation + 1)
        strings.write_byte(sb, '\n')
    case ^FuncCall:
        defer {
            pad_builder(sb, indentation)
            strings.write_string(sb, "}")
        }
        strings.write_string(sb, "FuncCall := '\n")
        strings.write_string(sb, string(expr_.identifier))
        strings.write_string(sb, "' {\n")
        pad_builder(sb, indentation + 1)
        strings.write_string(sb, "params = {")
        for param in expr_.params {
            expr_to_string_with_builder(param, sb, indentation + 2)
            strings.write_string(sb, ",\n")
        }
        pad_builder(sb, indentation + 1)
        strings.write_string(sb, "}\n")
    }
}

stmt_to_string :: proc(stmt: Stmt) -> (s: string) {
    sb := strings.builder_make()
    stmt_to_string_with_builder(stmt, &sb)
    return strings.to_string(sb)
}

stmt_to_string_summary :: proc(stmt: Stmt) -> (s: string) {
    sb := strings.builder_make()
    stmt_to_string_summary_with_builder(stmt, &sb)
    return strings.to_string(sb)
}

@(private)
stmt_to_string_with_builder :: proc(stmt: Stmt, sb: ^strings.Builder, indentation: int = 0) {
    pad_builder(sb, indentation)
    switch stmt_ in stmt {
    case ^Print:
        strings.write_string(sb, "Print := {\n")
        defer {
            strings.write_string(sb, "\n")
            pad_builder(sb, indentation)
            strings.write_string(sb, "}") // odin-mode broken 
        }
        expr_to_string_with_builder(stmt_.expr, sb, indentation + 1)
    case ^Println:
        strings.write_string(sb, "Println := \n")
        defer {
            strings.write_string(sb, "\n")
            pad_builder(sb, indentation)
            strings.write_string(sb, "}") // odin-mode broken 
        }
        expr_to_string_with_builder(stmt_.expr, sb, indentation + 1)
    case ^WrapExpr:
        strings.write_string(sb, "WrapExpr := \n")
        defer {
            strings.write_string(sb, "\n")
            pad_builder(sb, indentation)
            strings.write_string(sb, "}") // odin-mode broken 
        }
        expr_to_string_with_builder(stmt_.expr, sb, indentation + 1)
    case ^If:
        strings.write_string(sb, "If := ")
        strings.write_string(sb, "'")
        expr_to_string_summary_with_builder(stmt_.cond, sb)
        strings.write_string(sb, "' {\n")
        for node in stmt_.then_branch {
            stmt_to_string_with_builder(node, sb, indentation + 1)
            strings.write_string(sb, "\n")
        }
        pad_builder(sb, indentation)
        strings.write_string(sb, "\n")
        pad_builder(sb, indentation)
        strings.write_string(sb, "Else := {\n") // odin-mode broken 
        for node in stmt_.else_branch {
            stmt_to_string_with_builder(node, sb, indentation + 1)
        }
        strings.write_string(sb, "\n")
        pad_builder(sb, indentation)
        strings.write_string(sb, "}") // odin-mode broken 
    case ^Assignment:
        defer {
            pad_builder(sb, indentation)
            /* strings.write_byte(sb, '}') */
            strings.write_string(sb, "}") // odin-mode broken 
        }
        strings.write_string(sb, "Assignment := {\n")
        pad_builder(sb, indentation + 1)
        strings.write_string(sb, "indetifier = ")
        strings.write_string(sb, "'")
        strings.write_string(sb, string(stmt_.identifier))
        strings.write_string(sb, "'\n")
        pad_builder(sb, indentation + 1)
        strings.write_string(sb, "init = ")
        expr_to_string_summary_with_builder(stmt_.init, sb)
        strings.write_string(sb, "\n")
    case ^Function:
        defer {
            pad_builder(sb, indentation)
            /* strings.write_byte(sb, '}') */
            strings.write_string(sb, "}") // odin-mode broken 
        }
        strings.write_string(sb, "Func := '\n")
        strings.write_string(sb, string(stmt_.identifier))
        strings.write_string(sb, "' {\n")
        pad_builder(sb, indentation + 1)
        strings.write_string(sb, "params = {")
        for param in stmt_.params {
            expr_to_string_with_builder(param, sb, indentation + 2)
            strings.write_string(sb, ",\n")
        }
        pad_builder(sb, indentation + 1)
        strings.write_string(sb, "}\n")
        pad_builder(sb, indentation + 1)
        strings.write_string(sb, "body = {")
        for body_stmt in stmt_.body {
            stmt_to_string_with_builder(body_stmt, sb, indentation + 2)
            strings.write_string(sb, ",\n")
        }
        pad_builder(sb, indentation + 1)
        strings.write_string(sb, "}\n")

    case ^Return:
        defer {
            pad_builder(sb, indentation)
            /* strings.write_byte(sb, '}') */
            strings.write_string(sb, "}") // odin-mode broken 
        }
        strings.write_string(sb, "Return := {\n")
        expr_to_string_with_builder(stmt_.expr, sb, indentation + 1)
    }
}

@(private)
stmt_to_string_summary_with_builder :: proc(stmt: Stmt, sb: ^strings.Builder, indentation: int = 0) {
    switch stmt_ in stmt {
    case ^Print:
        strings.write_string(sb, "Print {")
        expr_to_string_summary_with_builder(stmt_.expr, sb)
        strings.write_string(sb, "}")
    case ^Println:
        strings.write_string(sb, "Println {")
        expr_to_string_summary_with_builder(stmt_.expr, sb)
        strings.write_string(sb, "}")
    case ^WrapExpr:
        strings.write_string(sb, "WrapExpr {")
        expr_to_string_summary_with_builder(stmt_.expr, sb)
        strings.write_string(sb, "}") 
    case ^If:
        strings.write_string(sb, "If := ")
        strings.write_string(sb, "'")
        expr_to_string_summary_with_builder(stmt_.cond, sb)
        strings.write_string(sb, "' {...} else {...}}")
    case ^Assignment:
        strings.write_string(sb, "Assignment := '")
        strings.write_string(sb, string(stmt_.identifier))
        strings.write_string(sb, " := ")
        expr_to_string_summary_with_builder(stmt_.init, sb)
        strings.write_string(sb, "'")
    case ^Function:
        strings.write_string(sb, "Function := '")
        strings.write_string(sb, string(stmt_.identifier))
        strings.write_string(sb, "(...){...}")
    case ^Return:
        strings.write_string(sb, "Return := {\n")
        expr_to_string_summary_with_builder(stmt_.expr, sb)
        strings.write_string(sb, "}")
    }
}
