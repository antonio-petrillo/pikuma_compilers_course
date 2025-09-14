#+private
package interpreter

import "core:fmt"
import "core:math"
import "core:strings"

import "pinky:ast"

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
        env_result, ok := env_get_var(env, expr)
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
                #partial switch right_operand in right {
                case ast.String:
                    result = strings.concatenate({left_operand, right_operand})

                case ast.Integer:
                    sb := strings.builder_make()
                    strings.write_string(&sb, left_operand)
                    strings.write_i64(&sb, right_operand)
                    result = strings.to_string(sb)

                case ast.Float:
                    sb := strings.builder_make()
                    strings.write_string(&sb, left_operand)
                    strings.write_f64(&sb, right_operand, 'f')
                    result = strings.to_string(sb)

                case:
                    return result, .BinaryOpTypeMismatch 
                }
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
        new_env := new_env_with_parent(env)
        defer delete_env(new_env)

        func, ok := env_get_func(env, expr.identifier)
        if !ok do return result, .UndefinedFunction
        if len(func.params) != len(expr.params) do return result, .MismatchedNumberArgs

        for identifier, index in func.params {
            new_env.vars[identifier] = interpret_expr(expr.params[index], env) or_return
        }

        func_result: Runtime_Type
        state: Runtime_State = .Continue
        for stmt in func.body {
            func_result, state = interpret_stmt(stmt, new_env) or_return
            if state != .Continue do return func_result, .None // return called
        }
    }
    return result, .None
}

Runtime_State :: enum {
        Continue,
        Stop,
}

interpret_stmt :: proc(node: ast.Stmt, env: ^Interpreter_Env) -> (result: Runtime_Type, state: Runtime_State, err: Runtime_Error) {
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
        new_env := new_env_with_parent(env)
        defer delete_env(new_env)
        if !ok do return NULL, .Stop, .ExpectedBoolInCondition
        if cond {
            for then_stmt in stmt.then_branch {
                result, state = interpret_stmt(then_stmt, new_env) or_return
                if state != .Continue do break
            } 
        } else {
            for then_stmt in stmt.else_branch {
                result, state = interpret_stmt(then_stmt, new_env) or_return
                if state != .Continue do break
            } 
        }
    case ^ast.Assignment:
        init := interpret_expr(stmt.init, env) or_return
        env_set_var(env, stmt.identifier, init) 
    case ^ast.Function:
        env.functions[stmt.identifier] = stmt
    case ^ast.While:
        new_env := new_env_with_parent(env)
        defer delete_env(new_env)
        for {
            cond_expr := interpret_expr(stmt.cond, env) or_return
            cond, ok := cond_expr.(Bool)
            if !ok do return NULL, .Stop, .ExpectedBoolInCondition
            if !cond do break

            for body_stmt in stmt.body {
                result, state = interpret_stmt(body_stmt, new_env) or_return
                if state != .Continue do break
            }
        }

    // assume works only on integers because why not
    case ^ast.For:
        new_env := new_env_with_parent(env)
        defer delete_env(new_env)
        start_ := interpret_expr(stmt.start.init, env) or_return
        start, ok_start := start_.(Integer)
        if !ok_start do return NULL, .Stop, .ExpectedOnlyIntegerInFor
        end_ := interpret_expr(stmt.end, env) or_return
        end, ok_end := end_.(Integer)
        if !ok_end do return NULL, .Stop, .ExpectedOnlyIntegerInFor
        step: Runtime_Type
        if  stmt.step != nil {
            ok_step: bool
            step_ := interpret_expr(stmt.step.?, env) or_return
            step, ok_step = step_.(Integer)
            if !ok_step do return NULL, .Stop, .ExpectedOnlyIntegerInFor
        } else {
            step = Integer(start < end ? 1 : -1)
        }

        env_set_var(new_env, stmt.start.identifier, start)

        bin_op := ast.BinOp{
            kind =  start < end ? ast.BinaryOpKind.Lt : ast.BinaryOpKind.Gt,
            left = stmt.start.identifier,
            right = ast.Integer(end),
        }

        for {
            cond_expr := interpret_expr(&bin_op, new_env) or_return
            cond, ok := cond_expr.(Bool)
            if !ok do return NULL, .Stop, .ExpectedBoolInCondition
            if !cond do break

            for body_stmt in stmt.body {
                result, state = interpret_stmt(body_stmt, new_env) or_return
                if state != .Continue do break
            }

            start_ = new_env.vars[stmt.start.identifier]
            new_env.vars[stmt.start.identifier] = start_.(Integer) + step.(Integer)
        }
        
    case ^ast.Return:
        result = interpret_expr(stmt.expr, env) or_return
        state = .Stop
    }
    return result, state, .None
}

interpret_program :: proc(program: ast.Program, env: ^Interpreter_Env) -> (err: Runtime_Error) {
    for &stmt in program {
        _, state := interpret_stmt(stmt, env) or_return
        if state != .Continue do break
    }
    return 
}

new_env_with_parent :: proc(env: ^Interpreter_Env) -> ^Interpreter_Env {
    new_env := new(Interpreter_Env)
    new_env.parent = env

    return new_env
}

env_set_var :: proc(env: ^Interpreter_Env, ident: ast.Identifier, rt: Runtime_Type) {
    iter := env
    for {
        if ident in iter.vars {
            iter.vars[ident] = rt
            return
        }
        if iter.parent == nil do break
        iter = iter.parent.?
    }

    env.vars[ident] = rt 
} 

env_get_var :: proc(env: ^Interpreter_Env, ident: ast.Identifier) -> (Runtime_Type, bool) {
    rt, ok := env.vars[ident]
    if !ok && env.parent != nil {
        return env_get_var(env.parent.?, ident)
    }
    return rt, ok
}

env_get_func :: proc(env: ^Interpreter_Env, ident: ast.Identifier) -> (^ast.Function, bool) {
    func, ok := env.functions[ident]
    if !ok && env.parent != nil {
        return env_get_func(env.parent.?, ident)
    }
    return func, ok
}
