import sys
from utils import *
from tokens import *
from lexer import *
from parser import *
from interpreter import *
from vm import *
from compiler import *

VERBOSE_MODE = False
INTERPRET_MODE = False

if __name__ == '__main__':
  if len(sys.argv) != 2:
    raise SystemExit('Usage: python3 pinky.py <filename>')
  filename = sys.argv[1]

  with open(filename) as file:
    source = file.read()

    if VERBOSE_MODE:
        print(f'{Colors.GREEN}***************************************{Colors.WHITE}')
        print(f'{Colors.GREEN}SOURCE:{Colors.WHITE}')
        print(f'{Colors.GREEN}***************************************{Colors.WHITE}')
        print(source)

        print(f'{Colors.GREEN}***************************************{Colors.WHITE}')
        print(f'{Colors.GREEN}TOKENS:{Colors.WHITE}')
        print(f'{Colors.GREEN}***************************************{Colors.WHITE}')

    tokens = Lexer(source).tokenize()
    
    if VERBOSE_MODE:
        for tok in tokens: print(tok)

        print()
        print(f'{Colors.GREEN}***************************************{Colors.WHITE}')
        print(f'{Colors.GREEN}AST:{Colors.WHITE}')
        print(f'{Colors.GREEN}***************************************{Colors.WHITE}')

    ast = Parser(tokens).parse()

    if INTERPRET_MODE:
        if VERBOSE_MODE:
            print_pretty_ast(ast)

            print()
            print(f'{Colors.GREEN}***************************************{Colors.WHITE}')
            print(f'{Colors.GREEN}INTERPRETER:{Colors.WHITE}')
            print(f'{Colors.GREEN}***************************************{Colors.WHITE}')
        interpreter = Interpreter()
        interpreter.interpret_ast(ast)
    else:
        if VERBOSE_MODE:
            print_pretty_ast(ast)

            print()
            print(f'{Colors.GREEN}***************************************{Colors.WHITE}')
            print(f'{Colors.GREEN}COMPILE AND RUN:{Colors.WHITE}')
            print(f'{Colors.GREEN}***************************************{Colors.WHITE}')

        compiler = Compiler()
        code = compiler.generate_code(ast)
        compiler.print_code()
        vm = VM()
        vm.run(code)
