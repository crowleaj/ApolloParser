# ApolloParser
Parser for the Nitro programming language implemented in Lua

## Running the Parser (ZeroBrane studio recommended)

1. Set directory to project directory
2. Run test/test.lua
  - To change file to run, edit the path in runfile function call without adding the file extension.

## Current Support
- Declarations
- Assignments
- Function definitions (local and global)
- Arithmetic
- Function calls, not as assignment or in arithmetic
- Includes

## Language Roadmap
- Function assignments
- Function in arithmetic
- Array and Map support

Lexer:

The lexer uses the provided grammar and capture rules in lexer.lua to create an AST of the language.


Simplified expressions for the AST data descriptions are:

var = \<classvariable + variable>

numval = \<parentheses + arithmetic + numberconst + functioncall + tablelookup + var>

val = \<stringconst + numval>


Nodes of the AST are one of the following:

numberconst {val = \<number value>}

stringconst {val = \<string value>}

variable {val = \<string value>}

classvariable {val = \<string value>} (tag used to specify class variable in instance annotator for same variable name in scope by using this: prefix)

comment {val = \<rhs of -- until newline>}

dotreference {val = \<string value>} (for accessing table indices with foo.bar syntax)

fornormal {var = \<string value>, first = \<numval>, last = \<numval>, step = \<numval>}

forenhanced {vars = {k = \<string value>, v = \<string value>}, var = \<numval>}

operator {val = \<one of +-*/>}

assignment {var = \<var> val = \<table + val>}

declaration {var = \<var>, scope = \<local + global>, val = \<val>}

functioncall {name = \<string value>, args = {\<params>*}} (whenever at least one reference is involved, tag automatically is tablelookup because lpeg matches are "greedy")

function {vars = {\<string value>*}, val = {\<instruction*>}}

params {val = {<val>*}}

arithmetic = {val = {\<val + operator>*}}

parentheses = {val = \<parentheses + arithmetic + numval>}

table {val = {\<val>*}}

forloop {iter = \<fornormal + forenhanced>, val = {\<instruction>*}}

brackets {val = \<val>}

tablelookup {name = \<var>, val = \<dotreference + brackets + params>}

class {name = \<string value>, val = {\<assignment + classmethod + variable>*}}

classmethod {name = \<var>, vars = {\<string value>*}, val = {\<instruction>*}}

Note: The type of node can be queried with the type attribute.
      Whenever a variable is guarenteed to be a string value, it is favored to use the string value instead of a variable tag in the lexer
