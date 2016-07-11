# NitroParser
Parser for the Nitro programming language implemented in Lua

Lexer:

The lexer uses the provided grammar and capture rules in lexer.lua to create an AST of the language.


Simplified expressions for the AST data descriptions are:

var = \<classvariable + variable>

numval = \<arithmetic + numberconst + functioncall + tablelookup + var>

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

functioncall {name = \<string value>, args = {\<val>*}} (whenever at least one reference is involved, tag automatically is tablelookup because lpeg matches are "greedy")

function {vars = {\<string value>*}, val = {\<instruction*>}}


Note: The type of node can be queried with the type attribute.
      Whenever a variable is guarenteed to be a string value, it is favored to use the string value instead of a variable tag in the lexer