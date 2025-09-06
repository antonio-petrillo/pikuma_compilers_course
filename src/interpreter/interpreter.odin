package interpreter

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
    }
    return
}

@(private)
interpret_expr :: proc(expr_node: ast.Expr) -> (result: ast.Expr, err: Runtime_Error) {
    switch expr in expr_node {
    case ast.Integer, ast.Float, ast.String, ast.Bool:
        result = expr
    case ^ast.UnaryOp:
        result = interpret_expr(expr.operand) or_return
        switch expr.kind {
        case ast.UnaryOpKind.Not: 
            bool_res, ok := result.(ast.Bool)
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
                right_operand, ok := right.(ast.Integer)
                if !ok do return expr, .BinaryOpTypeMismatch 
                if right_operand < 0 do return expr, .BitShiftWorksMustBePositive
                result = expr.kind == ast.BinaryOpKind.Shl ? left_operand << u64(right_operand) : left_operand >> u64(right_operand)
                case:
                return expr, .BitShiftWorksOnlyOnInteger
        }
        case ast.BinaryOpKind.And:
            #partial switch left_operand in left {
            case ast.Bool:
                if left_operand {
                    right_operand, ok := right.(ast.Bool)
                    if !ok do return expr, .BinaryOpTypeMismatch 
                    result = right_operand
                } else do result = false
                case:
                return expr, .LogicConnectorOnlyOnBools
            }
        case ast.BinaryOpKind.Or:
            #partial switch left_operand in left {
            case ast.Bool:
                if left_operand do result = true
                else {
                    right_operand, ok := right.(ast.Bool)
                    if !ok do return expr, .BinaryOpTypeMismatch 
                    result = right_operand
                }
                case:
                return expr, .LogicConnectorOnlyOnBools
            }
        case ast.BinaryOpKind.Neq:
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(ast.Integer)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand != right_operand
            case ast.Float:
                right_operand, ok := right.(ast.Float)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand != right_operand
            case ast.Bool:
                right_operand, ok := right.(ast.Bool)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand != right_operand
            case ast.String:
                right_operand, ok := right.(ast.String)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand != right_operand
            }
        case ast.BinaryOpKind.Eq:
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(ast.Integer)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand == right_operand
            case ast.Float:
                right_operand, ok := right.(ast.Float)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand == right_operand
            case ast.Bool:
                right_operand, ok := right.(ast.Bool)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand == right_operand
            case ast.String:
                right_operand, ok := right.(ast.String)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand == right_operand
            }
        case ast.BinaryOpKind.Lt:
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(ast.Integer)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand < right_operand
            case ast.Float:
                right_operand, ok := right.(ast.Float)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand < right_operand
            case ast.Bool:
                return expr, .BoolAreNotComparable
            case ast.String:
                right_operand, ok := right.(ast.String)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand < right_operand
            }
        case ast.BinaryOpKind.Le:
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(ast.Integer)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand <= right_operand
            case ast.Float:
                right_operand, ok := right.(ast.Float)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand <= right_operand
            case ast.Bool:
                return expr, .BoolAreNotComparable
            case ast.String:
                right_operand, ok := right.(ast.String)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand <= right_operand
            }
        case ast.BinaryOpKind.Gt:
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(ast.Integer)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand > right_operand
            case ast.Float:
                right_operand, ok := right.(ast.Float)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand > right_operand
            case ast.Bool:
                return expr, .BoolAreNotComparable
            case ast.String:
                right_operand, ok := right.(ast.String)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand > right_operand
            }
        case ast.BinaryOpKind.Ge:
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(ast.Integer)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand >= right_operand
            case ast.Float:
                right_operand, ok := right.(ast.Float)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand >= right_operand
            case ast.Bool:
                return expr, .BoolAreNotComparable
            case ast.String:
                right_operand, ok := right.(ast.String)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand >= right_operand
            }
        case ast.BinaryOpKind.Add:
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(ast.Integer)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand + right_operand
            case ast.Float:
                right_operand, ok := right.(ast.Float)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand + right_operand
            case ast.String:
                right_operand, ok := right.(ast.String)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = strings.concatenate({left_operand, right_operand})
            case:
                return expr, .BinaryOpUnapplicableToType
            }
        case ast.BinaryOpKind.Sub:
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(ast.Integer)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand - right_operand
            case ast.Float:
                right_operand, ok := right.(ast.Float)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand - right_operand
            case:
                return expr, .BinaryOpUnapplicableToType
            }
        case ast.BinaryOpKind.Mul:
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(ast.Integer)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand * right_operand
            case ast.Float:
                right_operand, ok := right.(ast.Float)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = left_operand * right_operand
            case:
                return expr, .BinaryOpUnapplicableToType
            }
        case ast.BinaryOpKind.Div:
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(ast.Integer)
                if !ok do return expr, .BinaryOpTypeMismatch 
                if right_operand == 0 do return expr, .DivisionByZero
                result = left_operand / right_operand
            case ast.Float:
                right_operand, ok := right.(ast.Float)
                if !ok do return expr, .BinaryOpTypeMismatch 
                if right_operand == 0 do return expr, .DivisionByZero
                result = left_operand / right_operand
            case:
                return expr, .BinaryOpUnapplicableToType
            }
        case ast.BinaryOpKind.Mod:
            #partial switch left_operand in left {
            case ast.Integer:
                right_operand, ok := right.(ast.Integer)
                if !ok do return expr, .BinaryOpTypeMismatch 
                if right_operand == 0 do return expr, .DivisionByZero
                result = left_operand % right_operand
           case ast.Float:
                right_operand, ok := right.(ast.Float)
                if !ok do return expr, .BinaryOpTypeMismatch 
                if right_operand == 0 do return expr, .DivisionByZero
                result = math.mod_f64(left_operand, right_operand)
           case:
                return expr, .BinaryOpUnapplicableToType
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
                right_operand, ok := right.(ast.Integer)
                if !ok do return expr, .BinaryOpTypeMismatch 
                if left_operand == right_operand && left_operand == 0 do return expr, .DivisionByZero
                if right_operand < 0 do return expr, .IntegerExpOnlyPositiveExponent
                result = fast_pow(left_operand, right_operand)
           case ast.Float:
                right_operand, ok := right.(ast.Float)
                if !ok do return expr, .BinaryOpTypeMismatch 
                result = math.pow_f64(left_operand, right_operand)
           case:
                return expr, .BinaryOpUnapplicableToType
            }
        }
    case ^ast.Grouping:
        return interpret_expr(expr.expr)
    }
    return result, .None
}

interpret :: proc(node: ast.AstNode, interpret_arena: ^virtual.Arena) -> (result: Interpreter_Result, err: Runtime_Error) {
    arena_allocator := virtual.arena_allocator(interpret_arena)
    context.allocator = arena_allocator

    switch node_kind in node {
    case ast.Expr:
        expr, err_expr := interpret_expr(node_kind)
        if err != .None {
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
        panic("Not implemented Yet!")
    }
    return result, .None
}
