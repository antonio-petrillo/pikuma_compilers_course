package interpreter

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

interpret :: proc(program: ast.Program, env: ^Interpreter_Env, interpret_arena: ^virtual.Arena) -> (err: Runtime_Error) {
    arena_allocator := virtual.arena_allocator(interpret_arena)
    context.allocator = arena_allocator

    return interpret_program(program, env)
}

Interpreter_Env :: struct {
    vars: map[ast.Identifier]Runtime_Type,
    functions: map[ast.Identifier]^ast.Function,
}
