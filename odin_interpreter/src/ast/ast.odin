package ast

Integer :: i64

Float :: f64

String :: string

Bool :: bool

Identifier :: distinct string

FuncCall :: struct {
    identifier: Identifier,
    params: [dynamic]Expr,
}

BinaryOpKind :: enum {
    Add,
    Sub,
    Mul,
    Div,
    Mod,
    Exp,

    Gt,
    Ge,
    Lt,
    Le,

    Eq,
    Neq,

    Shl,
    Shr,

    And,
    Or,
}

binary_op_kind_to_string :: proc(kind: BinaryOpKind) -> (s: string) {
    switch kind {
    case .Add: s = "+"
    case .Sub: s = "-"
    case .Mul: s = "*"
    case .Div: s = "/"
    case .Mod: s = "%"
    case .Exp: s = "^"
    case .Eq: s = "=="
    case .Neq: s = "~="
    case .Gt: s = ">"
    case .Ge: s = ">="
    case .Lt: s = "<"
    case .Le: s = "<="
    case .Shl: s = "<<"
    case .Shr: s = ">>"
    case .And: s = "and"
    case .Or: s = "or"
    }
    return
}

BinOp :: struct {
    left: Expr,
    right: Expr,
    kind: BinaryOpKind,
}

UnaryOpKind :: enum {
    Pos,
    Negate,
    Not,
}

unary_op_kind_to_string :: proc(kind: UnaryOpKind) -> (s: string) {
    switch kind {
    case .Pos: s = "+"
    case .Negate: s = "-"
    case .Not: s = "~"
    }
    return
}

UnaryOp :: struct {
    operand: Expr,
    kind: UnaryOpKind,
}

Grouping :: struct {
    expr: Expr 
}

Expr :: union #no_nil {
    Integer, 
    Float,
    String,
    Bool,
    Identifier,
    ^BinOp,
    ^UnaryOp,
    ^Grouping,
    ^FuncCall,
}

WrapExpr :: struct {
    expr: Expr,
}

Print :: struct {
    expr: Expr,
}

Println :: struct {
    expr: Expr,
}

Assignment :: struct {
    identifier: Identifier,
    init: Expr,
}

While :: struct {
    cond: Expr,
    body: [dynamic]Stmt,
}

For :: struct {
    start: ^Assignment,
    end: Expr,
    step: Maybe(Expr),
    body: [dynamic]Stmt,
} 

Function :: struct {
    identifier: Identifier,
    params: [dynamic]Identifier,
    body: [dynamic]Stmt,
}

If :: struct {
    cond: Expr,
    then_branch: [dynamic]Stmt,
    else_branch: [dynamic]Stmt,
    // use a maybe is more trouble than it is worth
    // remember that 'if .... else  end' is valid
    // in another word there is the possibility to create an emtpy else branch
}

Return :: struct {
    expr: Expr,
}

Stmt :: union #no_nil {
        ^WrapExpr,
        ^Print,
        ^Println,
        ^If,
        ^Assignment,
        ^Function,
        ^Return,
        ^While,
        ^For,
}

Program :: [dynamic]Stmt
