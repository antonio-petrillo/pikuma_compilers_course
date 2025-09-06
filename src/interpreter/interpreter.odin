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
}

Bool :: bool
Integer :: i64
Float :: f64
String :: string
Null :: distinct struct {}

NULL :: Null{}

Interpreter_Result :: union #no_nil {
    Null,
    Bool,
    Integer,
    Float,
    String,
}

result_to_string :: proc(ir: Interpreter_Result) -> string {
    sb := strings.builder_make()
    switch res in ir {
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
    }
    return
}

interpret_expr :: proc(expr_node: ast.Expr) -> (result: Interpreter_Result, err: Runtime_Error) {
    switch expr in expr_node {
    case ast.Integer:
        result = Integer(expr)
    case ast.Float:
        result = Float(expr)
    case ast.String:
        result = String(expr)
    case ast.Bool:
        result = Bool(expr)
    case ^ast.UnaryOp:
        result = interpret_expr(expr.operand) or_return
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
        left := interpret_expr(expr.left) or_return
        right := interpret_expr(expr.right) or_return
        switch expr.kind {
        case ast.BinaryOpKind.Shl, ast.BinaryOpKind.Shr:
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
                    right_operand, ok := right.(Bool)
                    if !ok do return result, .BinaryOpTypeMismatch 
                    result = right_operand
                }
                case:
                return result, .LogicConnectorOnlyOnBools
            }
        case ast.BinaryOpKind.Neq:
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
                right_operand, ok := right.(Integer)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand < right_operand
            case ast.Float:
                right_operand, ok := right.(Float)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand < right_operand
            case ast.Bool:
                return result, .BoolAreNotComparable
            case ast.String:
                right_operand, ok := right.(String)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand < right_operand
            }
        case ast.BinaryOpKind.Le:
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(Integer)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand <= right_operand
            case ast.Float:
                right_operand, ok := right.(Float)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand <= right_operand
            case ast.Bool:
                return result, .BoolAreNotComparable
            case ast.String:
                right_operand, ok := right.(String)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand <= right_operand
            }
        case ast.BinaryOpKind.Gt:
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(Integer)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand > right_operand
            case ast.Float:
                right_operand, ok := right.(Float)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand > right_operand
            case ast.Bool:
                return result, .BoolAreNotComparable
            case ast.String:
                right_operand, ok := right.(String)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand > right_operand
            }
        case ast.BinaryOpKind.Ge:
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(Integer)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand >= right_operand
            case ast.Float:
                right_operand, ok := right.(Float)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand >= right_operand
            case ast.Bool:
                return result, .BoolAreNotComparable
            case ast.String:
                right_operand, ok := right.(String)
                if !ok do return result, .BinaryOpTypeMismatch 
                result = left_operand >= right_operand
            }
        case ast.BinaryOpKind.Add:
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
        return interpret_expr(expr.expr)
    }
    return result, .None
}

interpret_stmt :: proc(node: ast.Stmt) -> (err: Runtime_Error) {
    switch stmt in node {
    case ^ast.Print:
        expr := interpret_expr(stmt.expr) or_return
        str := result_to_string(expr)
        fmt.printf("%s", str)
    case ^ast.Println:
        expr := interpret_expr(stmt.expr) or_return
        str := result_to_string(expr)
        fmt.printf("%s\n", str)
    case ^ast.WrapExpr:
        _ = interpret_expr(stmt.expr) or_return
    case ^ast.If:
        cond_expr := interpret_expr(stmt.cond) or_return
        cond, ok := cond_expr.(Bool)
        if !ok do return .ExpectedBoolInCondition
        if cond {
            for then_stmt in stmt.then_branch {
                interpret_stmt(then_stmt) or_return
            } 
        } else {
            for then_stmt in stmt.else_branch {
                interpret_stmt(then_stmt) or_return
            } 
        }
    }
    return .None
}

interpret :: proc(node: ast.AstNode, interpret_arena: ^virtual.Arena) -> (result: Interpreter_Result, err: Runtime_Error) {
    arena_allocator := virtual.arena_allocator(interpret_arena)
    context.allocator = arena_allocator

    switch node_kind in node {
    case ast.Expr:
        expr, err_expr := interpret_expr(node_kind)
        if err_expr != .None {
            return NULL, err_expr
        }
        #partial switch res in expr {
        case Integer: result = Integer(res)
        case Float: result = Float(res)
        case String: result = String(res)
        case Bool: result = Bool(res)
        case: result = NULL
        } 
    case ast.Stmt:
        result = NULL
        err_stmt := interpret_stmt(node_kind)
        if err_stmt != .None {
            return NULL, err_stmt
        }
    }
    return result, .None
}
