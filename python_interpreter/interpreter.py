from utils import *
from model import *
from tokens import *
from state import *
import codecs

###############################################################################
# Constants for different runtime value types
###############################################################################
TYPE_NUMBER = 'TYPE_NUMBER'  # Default to 64-bit float
TYPE_STRING = 'TYPE_STRING'  # String managed by the host language
TYPE_BOOL   = 'TYPE_BOOL'    # true | false

class Interpreter:
  def interpret(self, node, env):
    if isinstance(node, Integer):
      return (TYPE_NUMBER, float(node.value))

    elif isinstance(node, Float):
      return (TYPE_NUMBER, float(node.value))

    elif isinstance(node, String):
      return (TYPE_STRING, str(node.value))

    elif isinstance(node, Bool):
      return (TYPE_BOOL, node.value)

    elif isinstance(node, Grouping):
      return self.interpret(node.value, env)

    elif isinstance(node, Identifier):
      value = env.get_var(node.name)
      if value is None:
        runtime_error(f'Undeclared identifier {node.name!r}', node.line)
      if value[1] is None:
        runtime_error(f'Uninitialized identifier {node.name!r}', node.line)
      return value

    elif isinstance(node, Assignment):
      # Evaluate the right-hand side expression
      righttype, rightval = self.interpret(node.right, env)
      # Update the value of the left-hand side variable or create a new one
      env.set_var(node.left.name, (righttype, rightval))

    elif isinstance(node, BinOp):
      lefttype, leftval  = self.interpret(node.left, env)
      righttype, rightval = self.interpret(node.right, env)
      if node.op.token_type == TOK_PLUS:
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
          return (TYPE_NUMBER, leftval + rightval)
        elif lefttype == TYPE_STRING or righttype == TYPE_STRING:
          return (TYPE_STRING, stringify(leftval) + stringify(rightval))
        else:
          runtime_error(f'Unsupported operator {node.op.lexeme!r} between {lefttype} and {righttype}.', node.op.line)

      elif node.op.token_type == TOK_MINUS:
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
          return (TYPE_NUMBER, leftval - rightval)
        else:
          runtime_error(f'Unsupported operator {node.op.lexeme!r} between {lefttype} and {righttype}.', node.op.line)

      elif node.op.token_type == TOK_STAR:
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
          return (TYPE_NUMBER, leftval * rightval)
        else:
          runtime_error(f'Unsupported operator {node.op.lexeme!r} between {lefttype} and {righttype}.', node.op.line)

      elif node.op.token_type == TOK_SLASH:
        if rightval == 0:
          runtime_error(f'Division by zero.', node.line)
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
          return (TYPE_NUMBER, leftval / rightval)
        else:
          runtime_error(f'Unsupported operator {node.op.lexeme!r} between {lefttype} and {righttype}.', node.op.line)

      elif node.op.token_type == TOK_MOD:
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
          return (TYPE_NUMBER, leftval % rightval)
        else:
          runtime_error(f'Unsupported operator {node.op.lexeme!r} between {lefttype} and {righttype}.', node.op.line)

      elif node.op.token_type == TOK_CARET:
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
          return (TYPE_NUMBER, leftval ** rightval)
        else:
          runtime_error(f'Unsupported operator {node.op.lexeme!r} between {lefttype} and {righttype}.', node.op.line)

      elif node.op.token_type == TOK_GT:
        if (lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER) or (lefttype == TYPE_STRING and righttype == TYPE_STRING):
          return (TYPE_BOOL, leftval > rightval)
        else:
          runtime_error(f'Unsupported operator {node.op.lexeme!r} between {lefttype} and {righttype}.', node.op.line)

      elif node.op.token_type == TOK_GE:
        if (lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER) or (lefttype == TYPE_STRING and righttype == TYPE_STRING):
          return (TYPE_BOOL, leftval >= rightval)
        else:
          runtime_error(f'Unsupported operator {node.op.lexeme!r} between {lefttype} and {righttype}.', node.op.line)

      elif node.op.token_type == TOK_LT:
        if (lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER) or (lefttype == TYPE_STRING and righttype == TYPE_STRING):
          return (TYPE_BOOL, leftval < rightval)
        else:
          runtime_error(f'Unsupported operator {node.op.lexeme!r} between {lefttype} and {righttype}.', node.op.line)

      elif node.op.token_type == TOK_LE:
        if (lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER) or (lefttype == TYPE_STRING and righttype == TYPE_STRING):
          return (TYPE_BOOL, leftval <= rightval)
        else:
          runtime_error(f'Unsupported operator {node.op.lexeme!r} between {lefttype} and {righttype}.', node.op.line)

      elif node.op.token_type == TOK_EQEQ:
        if (lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER) or (lefttype == TYPE_STRING and righttype == TYPE_STRING) or (lefttype == TYPE_BOOL and righttype == TYPE_BOOL):
          return (TYPE_BOOL, leftval == rightval)
        else:
          runtime_error(f'Unsupported operator {node.op.lexeme!r} between {lefttype} and {righttype}.', node.op.line)

      elif node.op.token_type == TOK_NE:
        if (lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER) or (lefttype == TYPE_STRING and righttype == TYPE_STRING) or (lefttype == TYPE_BOOL and righttype == TYPE_BOOL):
          return (TYPE_BOOL, leftval != rightval)
        else:
          runtime_error(f'Unsupported operator {node.op.lexeme!r} between {lefttype} and {righttype}.', node.op.line)

    elif isinstance(node, UnOp):
      operandtype, operandval = self.interpret(node.operand, env)
      if node.op.token_type == TOK_MINUS:
        if operandtype == TYPE_NUMBER:
          return (TYPE_NUMBER, -operandval)
        else:
          runtime_error(f'Unsupported operator {node.op.lexeme!r} with {operandtype}.', node.op.line)

      if node.op.token_type == TOK_PLUS:
        if operandtype == TYPE_NUMBER:
          return (TYPE_NUMBER, operandval)
        else:
          runtime_error(f'Unsupported operator {node.op.lexeme!r} with {operandtype}.', node.op.line)

      elif node.op.token_type == TOK_NOT:
        if operandtype == TYPE_BOOL:
          return (TYPE_BOOL, not operandval)
        else:
          runtime_error(f'Unsupported operator {node.op.lexeme!r} with {operandtype}.', node.op.line)

    elif isinstance(node, LogicalOp):
      lefttype, leftval = self.interpret(node.left, env)
      if node.op.token_type == TOK_OR:
        if leftval:
          return (lefttype, leftval)
      elif node.op.token_type == TOK_AND:
        if not leftval:
          return (lefttype, leftval)
      return self.interpret(node.right, env)

    elif isinstance(node, Stmts):
      #Evaluate statements in sequence, one after the other.
      for stmt in node.stmts:
        self.interpret(stmt, env)

    elif isinstance(node, PrintStmt):
      exprtype, exprval = self.interpret(node.value, env)
      val = stringify(exprval)
      print(codecs.escape_decode(bytes(val, "utf-8"))[0].decode("utf-8"), end=node.end)

    elif isinstance(node, IfStmt):
      testtype, testval = self.interpret(node.test, env)
      if testtype != TYPE_BOOL:
        runtime_error("Condition test is not a boolean expression.", node.line)
      if testval:
        self.interpret(node.then_stmts, env.new_env()) # We must create a new child scope for the then-block
      else:
        self.interpret(node.else_stmts, env.new_env()) # We must create a new child scope for the else-block

    elif isinstance(node, WhileStmt):
      new_env = env.new_env()
      while True:
        testtype, testval = self.interpret(node.test, env)
        if testtype != TYPE_BOOL:
          runtime_error(f'While test is not a boolean expression.', node.line)
        if not testval:
          break
        self.interpret(node.body_stmts, new_env) # pass the new child environment for the scope of the while block

    elif isinstance(node, ForStmt):
      varname = node.ident.name
      itype, i = self.interpret(node.start, env)
      endtype, end = self.interpret(node.end, env)
      block_new_env = env.new_env()
      if i < end:
        if node.step is None:
          step = 1
        else:
          steptype, step = self.interpret(node.step, env)
        while i <= end:
          newval = (TYPE_NUMBER, i)
          block_new_env.set_var(varname, newval)
          self.interpret(node.body_stmts, block_new_env)
          i = i + step
      else:
        if node.step is None:
          step = -1
        else:
          steptype, step = self.interpret(node.step, env)
        while i >= end:
          newval = (TYPE_NUMBER, i)
          block_new_env.set_var(varname, newval)
          self.interpret(node.body_stmts, block_new_env)
          i = i + step

  def interpret_ast(self, node):
    # Entry point of our interpreter creating a brand new global/parent environment
    env = Environment()
    self.interpret(node, env)
