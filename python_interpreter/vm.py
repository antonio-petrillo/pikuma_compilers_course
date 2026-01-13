from defs import *
from utils import *
import codecs

class VM:
    def __init__(self):
        self.stack = []
        self.labels = {}

        self.globals = {}

        self.pc = 0
        self.sp = 0
        self.is_running = False

    def run(self, instructions):
        self.is_running = True
        self.pc = 0
        self.sp = 0

        self.create_label_table(instructions)

        while self.is_running:
            opcode, *args = instructions[self.pc]
            self.pc += 1

            getattr(self, opcode)(*args)

    def create_label_table(self, instructions):
        self.labels = {}
        for pc, instruction in enumerate(instructions):
            opcode, *args = instruction
            if opcode == 'LABEL':
                self.labels.update({args[0]: pc})

    def LABEL(self, name):
        pass

    def PUSH(self, value):
        self.stack.append(value)
        self.sp += 1

    def POP(self):
        self.sp -= 1
        return self.stack.pop()

    def ADD(self):
        righttype, rightval = self.POP()
        lefttype, leftval = self.POP()
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
            val = leftval + rightval
            self.PUSH((TYPE_NUMBER, val))
        if lefttype == TYPE_STRING or righttype == TYPE_STRING:
            val = stringify(leftval) + stringify(rightval)
            self.PUSH((TYPE_STRING, val))
        else:
            vm_error(f'Error on ADD between {lefttype} and {righttype}.', self.pc - 1)

    def SUB(self):
        righttype, rightval = self.POP()
        lefttype, leftval = self.POP()
        val = leftval - rightval
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
            self.PUSH((TYPE_NUMBER, val))
        else:
            vm_error(f'Error on SUB between {lefttype} and {righttype}.', self.pc - 1)

    def MUL(self):
        righttype, rightval = self.POP()
        lefttype, leftval = self.POP()
        val = leftval * rightval
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
            self.PUSH((TYPE_NUMBER, val))
        else:
            vm_error(f'Error on MUL between {lefttype} and {righttype}.', self.pc - 1)

    def DIV(self):
        righttype, rightval = self.POP()
        lefttype, leftval = self.POP()
        val = leftval / rightval
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
            self.PUSH((TYPE_NUMBER, val))
        else:
            vm_error(f'Error on DIV between {lefttype} and {righttype}.', self.pc - 1)

    def MOD(self):
        righttype, rightval = self.POP()
        lefttype, leftval = self.POP()
        val = leftval % rightval
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
            self.PUSH((TYPE_NUMBER, val))
        else:
            vm_error(f'Error on DIV between {lefttype} and {righttype}.', self.pc - 1)

    def EXP(self):
        righttype, rightval = self.POP()
        lefttype, leftval = self.POP()
        val = leftval ** rightval
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
            self.PUSH((TYPE_NUMBER, val))
        else:
            vm_error(f'Error on DIV between {lefttype} and {righttype}.', self.pc - 1)

    def AND(self):
        righttype, rightval = self.POP()
        lefttype, leftval = self.POP()
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
            val = leftval & rightval
            self.PUSH((TYPE_NUMBER, val))
        elif lefttype == TYPE_BOOL and righttype == TYPE_BOOL:
            val = leftval & rightval
            self.PUSH((TYPE_BOOL, val))
        else:
            vm_error(f'Error on AND between {lefttype} and {righttype}.', self.pc - 1)

    def OR(self):
        righttype, rightval = self.POP()
        lefttype, leftval = self.POP()
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
            val = leftval | rightval
            self.PUSH((TYPE_NUMBER, val))
        elif lefttype == TYPE_BOOL and righttype == TYPE_BOOL:
            val = leftval | rightval
            self.PUSH((TYPE_BOOL, val))
        else:
            vm_error(f'Error on OR between {lefttype} ({leftval}) and {righttype} ({rightval}).', self.pc - 1)

    def XOR(self):
        righttype, rightval = self.POP()
        lefttype, leftval = self.POP()
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
            val = leftval ^ rightval
            self.PUSH((TYPE_NUMBER, val))
        elif lefttype == TYPE_BOOL and righttype == TYPE_BOOL:
            val = leftval ^ rightval
            self.PUSH((TYPE_BOOL, val))
        else:
            vm_error(f'Error on XOR between {lefttype} and {righttype}.', self.pc - 1)

    def NEG(self):
        operandtype, val = self.POP()
        if operandtype == TYPE_NUMBER:
            self.PUSH((TYPE_NUMBER, -val))
        else:
            vm_error(f'Error on NEG on {operandtype}.', self.pc - 1)

    def EQ(self):
        righttype, rightval = self.POP()
        lefttype, leftval = self.POP()
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
            self.PUSH((TYPE_BOOL, leftval == rightval))
        if lefttype == TYPE_BOOL and righttype == TYPE_BOOL:
            self.PUSH((TYPE_BOOL, leftval == rightval))
        elif lefttype == TYPE_STRING and righttype == TYPE_STRING:
            self.PUSH((TYPE_BOOL, leftval == rightval))
        else:
            vm_error(f'Error on EQ between {lefttype} and {righttype}.', self.pc - 1)

    def NE(self):
        righttype, rightval = self.POP()
        lefttype, leftval = self.POP()
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
            self.PUSH((TYPE_BOOL, leftval != rightval))
        if lefttype == TYPE_BOOL and righttype == TYPE_BOOL:
            self.PUSH((TYPE_BOOL, leftval != rightval))
        elif lefttype == TYPE_STRING and righttype == TYPE_STRING:
            self.PUSH((TYPE_BOOL, leftval != rightval))
        else:
            vm_error(f'Error on EQ between {lefttype} and {righttype}.', self.pc - 1)

    def LT(self):
        righttype, rightval = self.POP()
        lefttype, leftval = self.POP()
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
            self.PUSH((TYPE_BOOL, leftval < rightval))
        elif lefttype == TYPE_STRING and righttype == TYPE_STRING:
            self.PUSH((TYPE_BOOL, leftval < rightval))
        else:
            vm_error(f'Error on LT between {lefttype} and {righttype}.', self.pc - 1)

    def LE(self):
        righttype, rightval = self.POP()
        lefttype, leftval = self.POP()
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
            self.PUSH((TYPE_BOOL, leftval <= rightval))
        elif lefttype == TYPE_STRING and righttype == TYPE_STRING:
            self.PUSH((TYPE_BOOL, leftval < rightval))
        else:
            vm_error(f'Error on LE between {lefttype} and {righttype}.', self.pc - 1)

    def GT(self):
        righttype, rightval = self.POP()
        lefttype, leftval = self.POP()
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
            self.PUSH((TYPE_BOOL, leftval > rightval))
        elif lefttype == TYPE_STRING and righttype == TYPE_STRING:
            self.PUSH((TYPE_BOOL, leftval > rightval))
        else:
            vm_error(f'Error on GT between {lefttype} and {righttype}.', self.pc - 1)

    def GE(self):
        righttype, rightval = self.POP()
        lefttype, leftval = self.POP()
        if lefttype == TYPE_NUMBER and righttype == TYPE_NUMBER:
            self.PUSH((TYPE_BOOL, leftval >= rightval))
        elif lefttype == TYPE_STRING and righttype == TYPE_STRING:
            self.PUSH((TYPE_BOOL, leftval >= rightval))
        else:
            vm_error(f'Error on GE between {lefttype} and {righttype}.', self.pc - 1)

    def PRINT(self):
        valtype, val = self.POP()
        print(codecs.escape_decode(bytes(stringify(val), "utf-8"))[0].decode("utf-8"), end='')

    def PRINTLN(self):
        valtype, val = self.POP()
        print(codecs.escape_decode(bytes(stringify(val), "utf-8"))[0].decode("utf-8"), end='\n')

    def JMP(self, label):
        self.pc = self.labels[label]

    def JMPZ(self, label):
        valtype, val = self.POP()
        if val == 0 or val == False:
            self.pc = self.labels[label]

    def STORE_GLOBAL(self, name):
        self.globals[name] = self.POP()

    def LOAD_GLOBAL(self, name):
        self.PUSH(self.globals[name])

    def HALT(self):
        self.is_running = False
