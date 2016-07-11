# NitroParser
Parser for the Nitro programming language implemented in Lua

Lexer:

The lexer uses the provided grammar and capture rules in lexer.lua to create an AST of the language.

Nodes of the AST are one of the following:

numberconst {val = <number value>}

stringconst {val = <string value>}

variable {val = <string value>}

classvariable {val = <string value>} (tag used to specify class variable in instance annotator for same variable name in scope by using this: prefix)

comment {val = <rhs of -- until newline>}

dotreference {val = <string value>} (for accessing table indices with foo.bar syntax)

fornormal {var = <string value>, first = <numberconst + functioncall + classvariable + variable>, last = <numberconst + functioncall + classvariable + variable>, step = <numberconst + functioncall + classvariable + variable>}

forenhanced {vars = {k = <string value>, v = <string value>}, var = <functioncall + tablelookup + variable + classvariable>}

operator {val = <one of +-*/>}

assignment {var = <variable + classvariable> val = <tablelookup + table + function + arithmetic + numberconst + stringconst + variable + classvariable>}



Note: The type of node can be queried with the type attribute.
      Whenever a variable is guarenteed to be a string value, it is favored to use the string value instead of a variable tag in the lexer