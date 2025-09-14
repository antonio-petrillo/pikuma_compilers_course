#+private
package parser

@require import "core:fmt"
import "core:strconv"
import "core:strings"

import "pinky:token"
import "pinky:ast"

Parser :: struct {
    tokens: []token.Token,
    start: int,
    current: int,
}

advance :: proc(parser: ^Parser) -> token.Token {
    tok := parser.tokens[parser.current] 
    parser.current += 1
    return tok
}

lookahead :: proc(parser: ^Parser, n: int = 1) -> Maybe(token.Token) {
    if n + parser.current >= len(parser.tokens) {
        return nil
    }
    return parser.tokens[parser.current + n]
}

peek :: proc(parser: ^Parser) -> token.Token {
    return parser.tokens[parser.current]
}

previous :: proc(parser: ^Parser) -> token.Token {
    return parser.tokens[parser.current - 1]
}

consume :: proc(parser: ^Parser) {
    parser.current += 1
}

match :: proc(parser: ^Parser, token_type: token.Token_Type) -> bool {
    if is_eof(parser) || parser.tokens[parser.current].token_type != token_type {
        return false
    }
    parser.current += 1
    return true
}

match_any :: proc(parser: ^Parser, token_types: ..token.Token_Type) -> bool {
    if is_eof(parser) do return false
    current_tok_type := parser.tokens[parser.current].token_type
    for token_type in token_types {
        if current_tok_type == token_type {
            parser.current += 1
            return true
        }
    }
    return false
}

is_eof :: proc(parser: ^Parser) -> bool {
    return parser.current >= len(parser.tokens)
}

parse_expr :: proc(parser: ^Parser) -> (ast.Expr, Parser_Error) {
    return parse_or(parser)
}

parse_or :: proc(parser: ^Parser) -> (expr: ast.Expr, err: Parser_Error) {
    and := parse_and(parser) or_return

    for match(parser, token.Token_Type.Or) {
        bin_op := new(ast.BinOp)
        bin_op.left = and
        bin_op.kind = .Or
        bin_op.right = parse_and(parser) or_return
        and = bin_op
    }

    return and, .None
}

parse_and :: proc(parser: ^Parser) -> (expr: ast.Expr, err: Parser_Error) {
    equality := parse_equality(parser) or_return

    for match(parser, token.Token_Type.And) {
        bin_op := new(ast.BinOp)
        bin_op.left = equality
        bin_op.kind = .And
        bin_op.right = parse_equality(parser) or_return
        equality = bin_op
    }

    return equality, .None
}

parse_equality :: proc(parser: ^Parser) -> (expr: ast.Expr, err: Parser_Error) {
    comparison := parse_comparison(parser) or_return

    // why did he add also '=' (.Eq)?
    for match_any(parser, token.Token_Type.Eq, token.Token_Type.EqEq, token.Token_Type.Ne) {
        tok := previous(parser) 
        bin_op := new(ast.BinOp)
        bin_op.left = comparison
        bin_op.right = parse_comparison(parser) or_return
        #partial switch tok.token_type {
            case token.Token_Type.Eq, token.Token_Type.EqEq: bin_op.kind = ast.BinaryOpKind.Eq
            case token.Token_Type.Ne: bin_op.kind = ast.BinaryOpKind.Neq
        }
        comparison = bin_op
    }
    return comparison, .None
}

parse_comparison :: proc(parser: ^Parser) -> (expr: ast.Expr, err: Parser_Error) {
    addition := parse_addition(parser) or_return

    for match_any(parser,
                  token.Token_Type.Lt,
                  token.Token_Type.Gt,
                  token.Token_Type.Le,
                  token.Token_Type.Ge) {
        tok := previous(parser)
        bin_op := new(ast.BinOp)
        bin_op.left = addition
        #partial switch tok.token_type {
            case token.Token_Type.Lt: bin_op.kind = ast.BinaryOpKind.Lt
            case token.Token_Type.Le: bin_op.kind = ast.BinaryOpKind.Le
            case token.Token_Type.Gt: bin_op.kind = ast.BinaryOpKind.Gt
            case token.Token_Type.Ge: bin_op.kind = ast.BinaryOpKind.Ge
            case: // noop
        }
        bin_op.right = parse_addition(parser) or_return
        addition = bin_op
    }

    return addition, .None
}

parse_addition :: proc(parser: ^Parser) -> (expr: ast.Expr, err: Parser_Error) {
    multiplication := parse_multiplication(parser) or_return
    for match_any(parser, token.Token_Type.Plus, token.Token_Type.Minus) {
        tok := previous(parser)
        bin_op := new(ast.BinOp) 
        bin_op.left = multiplication
        bin_op.kind = tok.token_type == token.Token_Type.Plus ? ast.BinaryOpKind.Add : ast.BinaryOpKind.Sub
        bin_op.right = parse_multiplication(parser) or_return
        multiplication = bin_op
    }
    return multiplication, .None
}

parse_multiplication :: proc(parser: ^Parser) -> (expr: ast.Expr, pe: Parser_Error) {
    bit_shift := parse_bit_shift(parser) or_return

    for match_any(parser, token.Token_Type.Star, token.Token_Type.Slash, token.Token_Type.Mod) {
        tok := previous(parser)
        bin_op := new(ast.BinOp) 
        bin_op.left = bit_shift
        #partial switch tok.token_type {
        case token.Token_Type.Star: bin_op.kind = .Mul
        case token.Token_Type.Slash: bin_op.kind = .Div
        case token.Token_Type.Mod: bin_op.kind = .Mod
        case: // noop
        }
        bin_op.right = parse_bit_shift(parser) or_return
        bit_shift = bin_op
    }
    return bit_shift, .None
}

parse_bit_shift :: proc(parser: ^Parser) -> (expr: ast.Expr, err: Parser_Error) {
    unary := parse_unary(parser) or_return
    for match_any(parser, token.Token_Type.LtLt, token.Token_Type.GtGt) {
        bin_op := new(ast.BinOp) 
        bin_op.left = unary
        bin_op.kind = previous(parser).token_type == token.Token_Type.LtLt ? .Shl : .Shr
        bin_op.right = parse_unary(parser) or_return
        unary = bin_op
    }
    return unary, .None
}

parse_unary :: proc(parser: ^Parser) -> (expr: ast.Expr, err: Parser_Error) {
    kind: Maybe(ast.UnaryOpKind) = nil
    switch {
    case match(parser, token.Token_Type.Plus): 
        kind = ast.UnaryOpKind.Pos
    case match(parser, token.Token_Type.Minus): 
        kind = ast.UnaryOpKind.Negate
    case match(parser, token.Token_Type.Not): 
        kind = ast.UnaryOpKind.Not
    }

    if kind != nil {
        unary := parse_unary(parser) or_return

        unary_node := new(ast.UnaryOp)
        unary_node.kind = kind.?
        unary_node.operand = unary

        return unary_node, .None
    }

    return parse_power(parser)
}

parse_power :: proc(parser: ^Parser) -> (expr: ast.Expr, err: Parser_Error) {
    primary := parse_primary(parser) or_return
    for match(parser, token.Token_Type.Caret) {
        bin_op := new(ast.BinOp) 
        bin_op.left = primary
        bin_op.kind = .Exp
        bin_op.right = parse_power(parser) or_return
        primary = bin_op
    }
    return primary, .None
}

parse_primary :: proc(parser: ^Parser) -> (expr: ast.Expr, err: Parser_Error) {
    if match(parser, token.Token_Type.LeftParen) {
        expr = parse_expr(parser) or_return
        if !match(parser, token.Token_Type.RightParen) {
            return expr, .UnclosedParen
        }

        grouping := new(ast.Grouping)
        grouping.expr = expr
        return grouping, .None
    }

    tok := advance(parser) 
    #partial switch tok.token_type {
        case token.Token_Type.Integer:
        num, ok := strconv.parse_i64_of_base(tok.lexeme, 10)
        if !ok {
            return expr, .InvalidInteger
        }
        return ast.Integer(num), .None

        case token.Token_Type.Float:
        num, ok := strconv.parse_f64(tok.lexeme)
        if !ok {
            return expr, .InvalidFloat
        }
        return ast.Float(num), .None

        case token.Token_Type.True, token.Token_Type.False:
        return ast.Bool(tok.lexeme == "true"), .None

        case token.Token_Type.String:
        str := strings.trim(tok.lexeme, "\"")
        return ast.String(str), .None

        case token.Token_Type.Identifier:
        identifier := ast.Identifier(tok.lexeme)
        if match(parser, token.Token_Type.LeftParen) {
            func_call := new(ast.FuncCall)
            func_call.identifier = identifier
            for !match(parser, token.Token_Type.RightParen) {
                expr_param := parse_expr(parser) or_return
                append(&func_call.params, expr_param)
                if match(parser, token.Token_Type.RightParen) do break
                if !match(parser, token.Token_Type.Comma) do return expr, .MissingCommaInArgList
            }
            if previous(parser).token_type != token.Token_Type.RightParen do return expr, .UnclosedParen
            return func_call, .None
        }
        return identifier, .None

        case: 
        return expr, .InvalidPrimaryExpression
    }
}


parse_stmt :: proc(parser: ^Parser) -> (stmt: ast.Stmt, err: Parser_Error) {
    if is_eof(parser) do return // allow for empty program

    #partial switch peek(parser).token_type {
    case token.Token_Type.Print, token.Token_Type.Println:
        stmt = parse_print(parser) or_return
    case token.Token_Type.If:
        stmt = parse_if(parser) or_return
    case token.Token_Type.Identifier:
        stmt = parse_assignment(parser) or_return
    case token.Token_Type.Func:
        stmt = parse_func(parser) or_return
    case token.Token_Type.Ret:
        stmt = parse_ret(parser) or_return
    case token.Token_Type.While:
        stmt = parse_while(parser) or_return
    case token.Token_Type.For:
        stmt = parse_for(parser) or_return
    case: 
        stmt = parse_wrap_expr(parser) or_return
    }
    return stmt, .None
}

parse_for :: proc(parser: ^Parser) -> (stmt: ast.Stmt, err: Parser_Error) {
    if !match(parser, token.Token_Type.For) do panic("Called 'parse_for' on wrong token")
    for_stmt := new(ast.For)
    stmt = parse_assignment(parser) or_return
    assign, ok := stmt.(^ast.Assignment)
    if !ok do return stmt, .MissingAssignmentInFor
    for_stmt.start = assign
    if !match(parser, token.Token_Type.Comma) do return stmt, .MissingCommaInFor
    for_stmt.end = parse_expr(parser) or_return 
    if match(parser, token.Token_Type.Comma) {
        for_stmt.step = parse_expr(parser) or_return
    } else {
        for_stmt.step = nil
    }

    if !match(parser, token.Token_Type.Do) do return stmt, .MissingDoInLoop
    for !match(parser, token.Token_Type.End) {
        body_stmt := parse_stmt(parser) or_return
        append(&for_stmt.body, body_stmt)
    }
    if previous(parser).token_type != token.Token_Type.End do return stmt, .MissingEndInFor

    stmt = for_stmt

    return stmt, .None
}

parse_while :: proc(parser: ^Parser) -> (stmt: ast.Stmt, err: Parser_Error) {
    if !match(parser, token.Token_Type.While) do panic("Called 'parse_while' on wrong token")
    while_stmt := new(ast.While)
    while_stmt.cond = parse_expr(parser) or_return

    if !match(parser, token.Token_Type.Do) do return stmt, .MissingDoInLoop
    
    for !match(parser, token.Token_Type.End) {
        body_stmt := parse_stmt(parser) or_return
        append(&while_stmt.body, body_stmt)
    }
    if previous(parser).token_type != token.Token_Type.End do return stmt, .MissingEndInWhile

    stmt = ast.Stmt(while_stmt)
    return stmt, .None
}

parse_ret :: proc(parser: ^Parser) -> (stmt: ast.Stmt, err: Parser_Error) {
    if !match(parser, token.Token_Type.Ret) do panic("Called 'parse_ret' on wrong token")
    ret_stmt := new(ast.Return)
    ret_stmt.expr = parse_expr(parser) or_return

    stmt = ast.Stmt(ret_stmt)
    return stmt, .None
}

parse_func :: proc(parser: ^Parser) -> (stmt: ast.Stmt, err: Parser_Error) {
    if !match(parser, token.Token_Type.Func) do panic("Called 'parse_func' on wrong token")
    if is_eof(parser) do return stmt, .UnexpectedEOF

    identifier := ast.Identifier(advance(parser).lexeme)
    if !match(parser, token.Token_Type.LeftParen) do return stmt, .MissingOpenParen

    func := new(ast.Function)
    stmt = func

    func.identifier = identifier
    for !match(parser, token.Token_Type.RightParen) {
        if !match(parser, token.Token_Type.Identifier) do return stmt, .UnexpectedTokenInFuncDefinition
        append(&func.params, ast.Identifier(previous(parser).lexeme))
        if match(parser, token.Token_Type.RightParen) do break
        if !match(parser, token.Token_Type.Comma) do return stmt, .MissingCommaInArgList
    }
    if is_eof(parser) do return stmt, .UnexpectedEOF
    if previous(parser).token_type != token.Token_Type.RightParen do return stmt, .UnclosedParen

    for !match(parser, token.Token_Type.End) {
        body_stmt := parse_stmt(parser) or_return
        append(&func.body, body_stmt)
    }
    if previous(parser).token_type != token.Token_Type.End do return stmt, .MissingEndInFunc

    return stmt, .None
}

parse_wrap_expr :: proc(parser: ^Parser) -> (stmt: ast.Stmt, err: Parser_Error) {
    wrap_expr := new(ast.WrapExpr)
    wrap_expr.expr = parse_expr(parser) or_return
    stmt = wrap_expr
    return stmt, .None
}

parse_print :: proc(parser: ^Parser) -> (stmt: ast.Stmt, err: Parser_Error) {
    if !match_any(parser, token.Token_Type.Print, token.Token_Type.Println) do panic("Called 'parse_print' on wrong token")

    if previous(parser).token_type == token.Token_Type.Print {
        print := new(ast.Print)
        print.expr = parse_expr(parser) or_return
        stmt = print
    } else {
        println := new(ast.Println)
        println.expr = parse_expr(parser) or_return
        stmt = println

    }

    return stmt, .None
}

parse_if :: proc(parser: ^Parser) -> (stmt: ast.Stmt, err: Parser_Error) {
    if !match(parser, token.Token_Type.If) do panic("Called 'parse_if' on wrong token")
    if_stmt := new(ast.If)
    if_stmt.cond = parse_expr(parser) or_return

    if !match(parser, token.Token_Type.Then) do return stmt, .MissingThenInIf

    for !is_eof(parser) && !match_any(parser, token.Token_Type.Else, token.Token_Type.End) {
        another_stmt := parse_stmt(parser) or_return 
        append(&if_stmt.then_branch, another_stmt)
    }

    if is_eof(parser) && (previous(parser).token_type != token.Token_Type.Else && previous(parser).token_type != token.Token_Type.End) {
        fmt.printfln("here")
        return stmt, .MissingEndInIf
    }

    stmt = if_stmt 

    if previous(parser).token_type == token.Token_Type.Else {
        for !is_eof(parser) && !match(parser, token.Token_Type.End) {
            another_stmt := parse_stmt(parser) or_return 
            append(&if_stmt.else_branch, another_stmt)
        }
    }

    if previous(parser).token_type != token.Token_Type.End do return stmt, .MissingEndInIf

    return stmt, .None
}

parse_assignment :: proc(parser: ^Parser) -> (stmt: ast.Stmt, err: Parser_Error) {
    if next := lookahead(parser); next != nil && next.?.token_type != token.Token_Type.Assign {
        return parse_wrap_expr(parser)
    }

    assignment := new(ast.Assignment)
    assignment.identifier = ast.Identifier(peek(parser).lexeme) 
    advance(parser)

    if !match(parser, token.Token_Type.Assign) do panic("Called 'parse_assignment' on wrong token")

    assignment.init = parse_expr(parser) or_return

    stmt = assignment
    return stmt, .None
}
