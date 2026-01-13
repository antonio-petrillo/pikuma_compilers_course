from model import *
from tokens import *
from utils import *

TYPE_NUMBER = 'TYPE_NUMBER'
TYPE_STRING = 'TYPE_STRING'
TYPE_BOOL = 'TYPE_BOOL'

class Symbol:
    def __init__(self, name):
        self.name = name

class Compiler:
    def __init__(self):
        self.code = []
        self.label_counter = 0
        self.globals = []
        self.numglobals = 0

    def get_symbol(self, name):
        for symbol in self.globals:
            if symbol.name == name:
                return symbol
        return None

    def make_label(self):
        self.label_counter += 1
        return f'LBL{self.label_counter}'

    def emit(self, instruction):
        self.code.append(instruction)

    def compile(self, node):
        if isinstance(node, Integer):
            value = (TYPE_NUMBER, float(node.value))
            self.emit(('PUSH', value))

        elif isinstance(node, Float):
            value = (TYPE_NUMBER, float(node.value))
            self.emit(('PUSH', value))

        elif isinstance(node, String):
            value = (TYPE_STRING, str(node.value))
            self.emit(('PUSH', value))

        elif isinstance(node, Bool):
            value = (TYPE_BOOL, True if node.value == True or node.value == 'true' else False)
            self.emit(('PUSH', value))

       # TODO: instr for bool and strings

        elif isinstance(node, BinOp):
            self.compile(node.left)
            self.compile(node.right)
            if node.op.token_type == TOK_PLUS:
                self.emit(('ADD', ))
            elif node.op.token_type == TOK_MINUS:
                self.emit(('SUB', ))
            elif node.op.token_type == TOK_STAR:
                self.emit(('MUL', ))
            elif node.op.token_type == TOK_SLASH:
                self.emit(('DIV', ))
            elif node.op.token_type == TOK_MOD:
                self.emit(('MOD', ))
            elif node.op.token_type == TOK_CARET:
                self.emit(('EXP', ))
            elif node.op.token_type == TOK_EQ or node.op.token_type == TOK_EQEQ:
                self.emit(('EQ', ))
            elif node.op.token_type == TOK_LT:
                self.emit(('LT', ))
            elif node.op.token_type == TOK_LE:
                self.emit(('LE', ))
            elif node.op.token_type == TOK_GT:
                self.emit(('GT', ))
            elif node.op.token_type == TOK_GE:
                self.emit(('GE', ))
            elif node.op.token_type == TOK_EQ:
                self.emit(('EQ', ))
            elif node.op.token_type == TOK_NE:
                self.emit(('NE', ))

        elif isinstance(node, UnOp):
            self.compile(node.operand)
            if node.op.token_type == TOK_MINUS:
                self.emit(('NEG', ))
            elif node.op.token_type == TOK_NOT:
                self.emit(('PUSH', (TYPE_BOOL, True)))
                self.emit(('XOR', ))

        elif isinstance(node, Grouping):
            self.compile(node.value)

        elif isinstance(node, LogicalOp):
            self.compile(node.left)
            self.compile(node.right)
            if node.op.token_type == TOK_AND:
                self.emit(('AND',))
            elif node.op.token_type == TOK_OR:
                self.emit(('OR', ))

        elif isinstance(node, PrintStmt):
            self.compile(node.value)
            if node.end == '':
                self.emit(('PRINT', ))
            else:
                self.emit(('PRINTLN', ))
                

        elif isinstance(node, IfStmt):
            self.compile(node.test)
            then_label = self.make_label()
            else_label = self.make_label()
            exit_label = self.make_label()
            self.emit(('JMPZ', else_label))
            self.emit(('LABEL', then_label))
            self.compile(node.then_stmts)
            self.emit(('JMP', exit_label))
            self.emit(('LABEL', else_label))
            if node.else_stmts:
                self.compile(node.else_stmts)
            self.emit(('LABEL', exit_label))

    
        elif isinstance(node, Stmts):
            for stmt in node.stmts:
                self.compile(stmt)
                
        elif isinstance(node, Assignment):
            self.compile(node.right)
            symbol = self.get_symbol(node.left.name) 
            if not symbol:
                symbol = Symbol(node.left.name)
                self.globals.append(symbol)
                self.numglobals += 1

            self.emit(('STORE_GLOBAL', symbol.name))

        elif isinstance(node, Identifier):
            symbol = self.get_symbol(node.name)
            if not symbol:
                #TODO: compile err, var not def
                compiler_error(f'Variable {node.name} is not defined.', node.line)
                pass
            else:
                self.emit(('LOAD_GLOBAL', symbol.name))

    def generate_code(self, node):
        self.emit(('LABEL', 'START'))
        self.compile(node)
        self.emit(('HALT',))
        return self.code

    def print_code(self):
        i = 0
        for instruction in self.code:
            if instruction[0] == 'LABEL':
                print(f'{i:08} {instruction[1]}:')
                i += 1
                continue
            elif instruction[0] == 'PUSH':
                print(f"{i:08}    {instruction[0]} {stringify(instruction[1][1])}")
                i += 1
                continue

            if len(instruction) == 1:
                print(f"{i:08}    {instruction[0]}")
            elif len(instruction) == 2:
                print(f"{i:08}   {instruction[0]} {instruction[1]}")
            i += 1
            
        
