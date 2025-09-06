# TODO:
- Add `^If` and `WrapExpr` to test case (parser)
- Refactor test cases (parser) into:
  - Test expression
  - Test statement
- Add test interpreter
- Implement program state for the interpreter, something like:
```odin 
Env :: struct {
    parent_env: Maybe(^Env),
    // use string as identifier instead of token because it's more efficient, right?
    variables: map[string]interpreter.Interpreter_Result,
    functions: map[string]interpreter.Function,  
}

Interpreter_State :: struct {
    env: Env,
    program: [dynamic]ast.Stmt,
    program_counter: int,
    stack: [dynamic]int, // check if there is a stack in the stdlib
}

```
- Rename `Interpreter_Result` to `Runtime_Type`
