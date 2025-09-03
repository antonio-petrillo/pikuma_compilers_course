# Pinky's Grammar:
Here is the [BNF](https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form) grammar (not fully defined) for pinky.
``` txt
<expr> ::= <term> ( <addop> <term>)*
<term> ::= <factor> ( <mulop> <factor>)*
<factor> ::= <unary>
<unary> ::= ('+', '-', '~') <unary> | <primary>
<primary> :: <number> | '(' <expr> ')'

<addop> ::= '+' | '-'
<mulop> ::= '*' | '/'
<unaryop> ::= '+' | '-' | '~'
<number> ::= <digit> | <digit>(\.<digit>)?
<digit> ::= [0-9]+
```

# Examples
Expression: `-2 + 42 * 2 + (47 * -21)`
``` lisp
(+
    (+ (- 2)
       (* 42 2))
    (* 47
       (- 21)))
```
