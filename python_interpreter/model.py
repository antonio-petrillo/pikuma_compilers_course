from tokens import *

class Node:
  '''
  The parent class for every node in the AST
  '''
  pass

class Expr(Node):
  '''
  Expressions evaluate to a result, like x + (3 * y) >= 6
  '''
  pass


class Stmt(Node):
  '''
  Statements perform an action
  '''
  pass


class Integer(Expr):
  '''
  Example: 17
  '''
  def __init__(self, value, line):
    assert isinstance(value, int), value
    self.value = value
    self.line = line
  def __repr__(self):
    return f'Integer[{self.value}]'


class Float(Expr):
  '''
  Example: 3.141592
  '''
  def __init__(self, value, line):
    assert isinstance(value, float), value
    self.value = value
    self.line = line
  def __repr__(self):
    return f'Float[{self.value}]'


class Bool(Expr):
  '''
  Example: true, false
  '''
  def __init__(self, value, line):
    assert isinstance(value, bool), value
    self.value = value
    self.line = line
  def __repr__(self):
    return f'Bool[{self.value}]'


class String(Expr):
  '''
  Example: 'this is a string'
  '''
  def __init__(self, value, line):
    assert isinstance(value, str), value
    self.value = value
    self.line = line
  def __repr__(self):
    return f'String[{self.value}]'


class UnOp(Expr):
  '''
  Example: -operand
  '''
  def __init__(self, op: Token, operand: Expr, line):
    assert isinstance(op, Token), op
    assert isinstance(operand, Expr), operand
    self.op = op
    self.operand = operand
    self.line = line
  def __repr__(self):
    return f'UnOp({self.op.lexeme!r}, {self.operand})'


class BinOp(Expr):
  '''
  Example: x + y
  '''
  def __init__(self, op: Token, left: Expr, right: Expr, line):
    assert isinstance(op, Token), op
    assert isinstance(left, Expr), left
    assert isinstance(right, Expr), right
    self.op = op
    self.left = left
    self.right = right
    self.line = line
  def __repr__(self):
    return f'BinOp({self.op.lexeme!r}, {self.left}, {self.right})'


class LogicalOp(Expr):
  '''
  Example: x and y, x or y
  '''
  def __init__(self, op: Token, left: Expr, right: Expr, line):
    assert isinstance(op, Token), op
    assert isinstance(left, Expr), left
    assert isinstance(right, Expr), right
    self.op = op
    self.left = left
    self.right = right
    self.line = line
  def __repr__(self):
    return f'LogicalOp({self.op.lexeme!r}, {self.left}, {self.right})'


class Grouping(Expr):
  '''
  Example: ( <expr> )
  '''
  def __init__(self, value, line):
    assert isinstance(value, Expr), value
    self.value = value
    self.line = line
  def __repr__(self):
    return f'Grouping({self.value})'


class Identifier(Expr):
  '''
  Example: x, PI, _score, numLives, start_vel
  '''
  def __init__(self, name, line):
    assert isinstance(name, str), name
    self.name = name
    self.line = line
  def __repr__(self):
    return f'Identifier[{self.name}]'


class Stmts(Node):
  '''
  A list of statements
  '''
  def __init__(self, stmts, line):
    assert all(isinstance(stmt, Stmt) for stmt in stmts), stmts
    self.stmts = stmts
    self.line = line
  def __repr__(self):
    return f'Stmts({self.stmts})'


class PrintStmt(Stmt):
  '''
  Example: print value, println value
  '''
  def __init__(self, value, end, line):
    assert isinstance(value, Expr), value
    self.value = value
    self.end = end
    self.line = line
  def __repr__(self):
    return f'PrintStmt({self.value}, end={self.end!r})'


class IfStmt(Stmt):
  '''
  "if" <expr> "then" <then_stmts> ("else" <else_stmts>)? "end"
  '''
  def __init__(self, test, then_stmts, else_stmts, line):
    assert isinstance(test, Expr), test
    assert isinstance(then_stmts, Stmts), then_stmts
    assert else_stmts is None or isinstance(else_stmts, Stmts), else_stmts
    self.test = test
    self.then_stmts = then_stmts
    self.else_stmts = else_stmts
    self.line = line
  def __repr__(self):
    return f'IfStmt({self.test}, then:{self.then_stmts}, else:{self.else_stmts})'


class WhileStmt(Stmt):
  '''
  "while" <expr> "do" <body_stmts> "end"
  '''
  def __init__(self, test, body_stmts, line):
    assert isinstance(test, Expr), test
    assert isinstance(body_stmts, Stmts), body_stmts
    self.test = test
    self.body_stmts = body_stmts
    self.line = line
  def __repr__(self):
    return f'WhileStmt({self.test}, {self.body_stmts})'
  
class ForStmt(Stmt):
  '''
  "For" <identifer> ":=" <start> "," <end> ("," <increment>)? "do" <body_stmts> "end"
  '''
  def __init__(self, ident, start, end, step, body_stmts, line):
    assert isinstance(ident, Identifier), ident
    assert isinstance(start, Expr), start
    assert isinstance(end, Expr), end
    assert isinstance(step, Expr) or step is None, step
    assert isinstance(body_stmts, Stmts), body_stmts
    self.ident = ident
    self.start = start
    self.end = end
    self.step = step
    self.body_stmts = body_stmts
    self.line = line

  def __repr__(self):
    return f"ForStmt({self.ident}, {self.start}, {self.end}, {self.step}, {self.body_stmts})"


class Assignment(Stmt):
  '''
  left := right
  '''
  def __init__(self, left, right, line):
    assert isinstance(left, Expr), left
    assert isinstance(right, Expr), right
    self.left = left
    self.right = right
    self.line = line
  def __repr__(self):
    return f'Assignment({self.left}, {self.right})'
