package interpreter

import "core:fmt"
import "core:math"
import "core:mem/virtual"
import "core:strings"

import "pinky:ast"

Runtime_Error :: enum {
    None,
    UnaryOpTypeMismatch,
    BinaryOpTypeMismatch,
    BinaryOpUnapplicableToType,
    DivisionByZero,
    IntegerExpOnlyPositiveExponent,
    BoolAreNotComparable,
    BitShiftWorksOnlyOnInteger,
    BitShiftWorksMustBePositive,
    LogicConnectorOnlyOnBools,
    ExpectedBoolInCondition,
    UndefinedVariable,
    UndefinedFunction,
    MismatchedNumberArgs,
}

Bool :: bool
Integer :: i64
Float :: f64
String :: string
Null :: distinct struct {}

NULL :: Null{}

Runtime_Type :: union #no_nil {
    Null,
    Bool,
    Integer,
    Float,
    String,
}

result_to_string :: proc(rt: Runtime_Type) -> string {
    sb := strings.builder_make()
    switch res in rt {
    case Null: strings.write_string(&sb, "NULL")
    case Bool: strings.write_string(&sb, res ? "true" : "false")
    case Integer: strings.write_i64(&sb, res)
    case Float: strings.write_f64(&sb, res, 'e')
    case String: strings.write_string(&sb, res)
    }
    return strings.to_string(sb)
}

interpreter_error_to_string :: proc(ie: Runtime_Error) -> (s: string) {
    switch ie {
    case .None: s = "None"
    case .UnaryOpTypeMismatch: s = "Unary operation type mismatch"
    case .BinaryOpTypeMismatch: s = "Binary operation type mismatch between the two operands"
    case .BinaryOpUnapplicableToType: s = "Binary operation unapplicable to the first operand"
    case .DivisionByZero: s = "Division by Zero error"
    case .IntegerExpOnlyPositiveExponent: s = "Can't raise an integer to a negative power"
    case .BoolAreNotComparable: s = "Boolean value are not comparable through '<', '<=', '>', '>='"
    case .BitShiftWorksOnlyOnInteger: s = "BitShifts '>>' and '<<' can only be applied to integers"
    case .BitShiftWorksMustBePositive: s = "Right hand side of '>>' and '<<' cannot be negative"
    case .LogicConnectorOnlyOnBools: s = "Logic connectors 'and' and 'or' can be used only 'bool' types"
    case .ExpectedBoolInCondition: s = "Expected Bool in condition"
    case .UndefinedVariable: s = "Undefined variable"
    case .UndefinedFunction: s = "Undefined function"
    case .MismatchedNumberArgs: s = "Mismatched number of arguments in function call"
    }
    return
}

interpret_expr :: proc(expr_node: ast.Expr, env: ^Interpreter_Env) -> (result: Runtime_Type, err: Runtime_Error) {
    switch expr in expr_node {
    case ast.Integer:
        result = Integer(expr)
    case ast.Float:
        result = Float(expr)
    case ast.String:
        result = String(expr)
    case ast.Bool:
        result = Bool(expr)
    case ast.Identifier:
        env_result, ok := env.vars[expr]
        if !ok do return result, .UndefinedVariable
        result = env_result
    case ^ast.UnaryOp:
        result = interpret_expr(expr.operand, env) or_return
        switch expr.kind {
        case ast.UnaryOpKind.Not: 
            bool_res, ok := result.(Bool)
            if !ok do return result, .UnaryOpTypeMismatch
            result = ast.Bool(!bool_res)
        case ast.UnaryOpKind.Pos:
            #partial switch num in result {
                case ast.Integer, ast.Float:
                // noop
                case:
                return result, .UnaryOpTypeMismatch
            }
        case ast.UnaryOpKind.Negate:
            #partial switch num in result {
                case ast.Integer:
                result = ast.Integer(num * -1)
                case ast.Float:
                result = ast.Float(num * -1.0)
                case:
                return result, .UnaryOpTypeMismatch
            }
        }
    case ^ast.BinOp:
        left := interpret_expr(expr.left, env) or_return
        switch expr.kind {
        case ast.BinaryOpKind.Shl, ast.BinaryOpKind.Shr:
            right := interpret_expr(expr.right, env) or_return
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(Integer)
                if !ok do return result, .BinaryOpTypeMismatch 
                if right_operand < 0 do return result, .BitShiftWorksMustBePositive
                result = expr.kind == ast.BinaryOpKind.Shl ? left_operand << u64(right_operand) : left_operand >> u64(right_operand)
                case:
                return result, .BitShiftWorksOnlyOnInteger
        }
        case ast.BinaryOpKind.And:
            #partial switch left_operand in left {
            case ast.Bool:
                if left_operand {
                    right := interpret_expr(expr.right, env) or_return
                    right_operand, ok := right.(Bool)
                    if !ok do return result, .BinaryOpTypeMismatch 
                    result = right_operand
                } else do result = false
                case:
                return result, .LogicConnectorOnlyOnBools
            }
        case ast.BinaryOpKind.Or:
            #partial switch left_operand in left {
            case ast.Bool:
                if left_operand do result = true
                else {
                    right := interpret_expr(expr.right, env) or_return
                    right_operand, ok := right.(Bool)
                    if !ok do return result, .BinaryOpTypeMismatch 
                    result = right_operand
                }
                case:
                return result, .LogicConnectorOnlyOnBools
            }
        case ast.BinaryOpKind.Neq:
            right := interpret_expr(expr.right, env) or_return
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(Integer)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand != right_operand
            case ast.Float:
                right_operand, ok := right.(Float)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand != right_operand
            case ast.Bool:
                right_operand, ok := right.(Bool)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand != right_operand
            case ast.String:
                right_operand, ok := right.(String)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand != right_operand
            }
        case ast.BinaryOpKind.Eq:
            right := interpret_expr(expr.right, env) or_return
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(Integer)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand == right_operand
            case ast.Float:
                right_operand, ok := right.(Float)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand == right_operand
            case ast.Bool:
                right_operand, ok := right.(Bool)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand == right_operand
            case ast.String:
                right_operand, ok := right.(String)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand == right_operand
            }
        case ast.BinaryOpKind.Lt:
            #partial switch left_operand in left {
            case ast.Integer:
                right := interpret_expr(expr.right, env) or_return
                right_operand, ok := right.(Integer)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand < right_operand
            case ast.Float:
                right := interpret_expr(expr.right, env) or_return
                right_operand, ok := right.(Float)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand < right_operand
            case ast.Bool:
                return result, .BoolAreNotComparable
            case ast.String:
                right := interpret_expr(expr.right, env) or_return
                right_operand, ok := right.(String)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand < right_operand
            }
        case ast.BinaryOpKind.Le:
            #partial switch left_operand in left {
            case ast.Integer:
                right := interpret_expr(expr.right, env) or_return
                right_operand, ok := right.(Integer)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand <= right_operand
            case ast.Float:
                right := interpret_expr(expr.right, env) or_return
                right_operand, ok := right.(Float)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand <= right_operand
            case ast.Bool:
                return result, .BoolAreNotComparable
            case ast.String:
                right := interpret_expr(expr.right, env) or_return
                right_operand, ok := right.(String)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand <= right_operand
            }
        case ast.BinaryOpKind.Gt:
            #partial switch left_operand in left {
            case ast.Integer:
                right := interpret_expr(expr.right, env) or_return
                right_operand, ok := right.(Integer)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand > right_operand
            case ast.Float:
                right := interpret_expr(expr.right, env) or_return
                right_operand, ok := right.(Float)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand > right_operand
            case ast.Bool:
                return result, .BoolAreNotComparable
            case ast.String:
                right := interpret_expr(expr.right, env) or_return
                right_operand, ok := right.(String)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand > right_operand
            }
        case ast.BinaryOpKind.Ge:
            #partial switch left_operand in left {
            case ast.Integer:
                right := interpret_expr(expr.right, env) or_return
                right_operand, ok := right.(Integer)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand >= right_operand
            case ast.Float:
                right := interpret_expr(expr.right, env) or_return
                right_operand, ok := right.(Float)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand >= right_operand
            case ast.Bool:
                return result, .BoolAreNotComparable
            case ast.String:
                right := interpret_expr(expr.right, env) or_return
                right_operand, ok := right.(String)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand >= right_operand
            }
        case ast.BinaryOpKind.Add:
            right := interpret_expr(expr.right, env) or_return
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(Integer)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand + right_operand
            case ast.Float:
                right_operand, ok := right.(Float)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand + right_operand
            case ast.String:
                right_operand, ok := right.(String)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = strings.concatenate({left_operand, right_operand})
            case:
                return result, .BinaryOpUnapplicableToType
            }
        case ast.BinaryOpKind.Sub:
            right := interpret_expr(expr.right, env) or_return
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(Integer)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand - right_operand
            case ast.Float:
                right_operand, ok := right.(Float)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand - right_operand
            case:
                return result, .BinaryOpUnapplicableToType
            }
        case ast.BinaryOpKind.Mul:
            right := interpret_expr(expr.right, env) or_return
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(Integer)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand * right_operand
            case ast.Float:
                right_operand, ok := right.(Float)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand * right_operand
            case:
                return result, .BinaryOpUnapplicableToType
            }
        case ast.BinaryOpKind.Div:
            right := interpret_expr(expr.right, env) or_return
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(Integer)
                if !ok do return result, .BinaryOpTypeMismatch 
                if right_operand == 0 do return result, .DivisionByZero
                result = left_operand / right_operand
            case ast.Float:
                right_operand, ok := right.(Float)
                if !ok do return result, .BinaryOpTypeMismatch 
                if right_operand == 0 do return result, .DivisionByZero
                result = left_operand / right_operand
            case:
                return result, .BinaryOpUnapplicableToType
            }
        case ast.BinaryOpKind.Mod:
            right := interpret_expr(expr.right, env) or_return
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(Integer)
                if !ok do return result, .BinaryOpTypeMismatch 
                if right_operand == 0 do return result, .DivisionByZero
                result = left_operand % right_operand
           case ast.Float:
                right_operand, ok := right.(Float)
                if !ok do return result, .BinaryOpTypeMismatch 
                if right_operand == 0 do return result, .DivisionByZero
                result = math.mod_f64(left_operand, right_operand)
           case:
                return result, .BinaryOpUnapplicableToType
            }
        case ast.BinaryOpKind.Exp:
            right := interpret_expr(expr.right, env) or_return
            #partial switch left_operand in left {
            case ast.Integer:
                fast_pow :: proc(a, b: i64) -> i64 {
                    a, b := a, b
                    if a == 1 || b == 0 do return 1
                    acc: i64 = 1
                    for b > 1 {
                        if b & 1 == 1 {
                            acc *= a
                            b -= 1
                        }
                        a *= a
                        b >>= 1
                    }
                    return acc * a
                }
                right_operand, ok := right.(Integer)
                if !ok do return result, .BinaryOpTypeMismatch 
                if left_operand == right_operand && left_operand == 0 do return result, .DivisionByZero
                if right_operand < 0 do return result, .IntegerExpOnlyPositiveExponent
                result = fast_pow(left_operand, right_operand)
           case ast.Float:
                right_operand, ok := right.(Float)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = math.pow_f64(left_operand, right_operand)
           case:
                return result, .BinaryOpUnapplicableToType
            }
        }
    case ^ast.Grouping:
        return interpret_expr(expr.expr, env)
    case ^ast.FuncCall:
        new_env := new(Interpreter_Env)
        defer free(new_env)

        func, ok := env.functions[expr.identifier]
        if !ok do return result, .UndefinedFunction
        if len(func.params) != len(expr.params) do return result, .MismatchedNumberArgs

        for identifier, index in func.params {
            new_env.vars[identifier] = interpret_expr(expr.params[index], env) or_return
        }

        for stmt in func.body {
            result = interpret_stmt(stmt, new_env) or_return
        }
    }
    return result, .None
}

interpret_stmt :: proc(node: ast.Stmt, env: ^Interpreter_Env) -> (result: Runtime_Type, err: Runtime_Error) {
    env := env
    result = NULL
    switch stmt in node {
    case ^ast.Print:
        expr := interpret_expr(stmt.expr, env) or_return
        str := result_to_string(expr)
        fmt.printf("%s", str)
    case ^ast.Println:
        expr := interpret_expr(stmt.expr, env) or_return
        str := result_to_string(expr)
        fmt.printf("%s\n", str)
    case ^ast.WrapExpr:
        result = interpret_expr(stmt.expr, env) or_return
    case ^ast.If:
        cond_expr := interpret_expr(stmt.cond, env) or_return
        cond, ok := cond_expr.(Bool)
        if !ok do return NULL, .ExpectedBoolInCondition
        if cond {
            for then_stmt in stmt.then_branch {
                result = interpret_stmt(then_stmt, env) or_return
            } 
        } else {
            for then_stmt in stmt.else_branch {
                result = interpret_stmt(then_stmt, env) or_return
            } 
        }
    case ^ast.Assignment:
        init := interpret_expr(stmt.init, env) or_return
        env.vars[stmt.identifier] = init
    case ^ast.Function:
        env.functions[stmt.identifier] = stmt
    }
    return result, .None
}

interpret :: proc(node: ast.Stmt, env: ^Interpreter_Env, interpret_arena: ^virtual.Arena) -> (result: Runtime_Type, err: Runtime_Error) {
    arena_allocator := virtual.arena_allocator(interpret_arena)
    context.allocator = arena_allocator

    return interpret_stmt(node, env)
}

Interpreter_Env :: struct {
    vars: map[ast.Identifier]Runtime_Type,
    functions: map[ast.Identifier]^ast.Function,
}
