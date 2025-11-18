module Syntax

// ---------- Layout ----------
layout Layout = WhitespaceAndComment* !>> [\ \t\n\r];
lexical WhitespaceAndComment = [\ \t\n\r] | "//" ![\n]*;

// ---------- Tokens ----------
lexical Identifier = [a-z] [a-z0-9\-]* !>> [a-z0-9\-] \ Reserved;
lexical IntLiteral = [0-9]+ !>> [0-9];
lexical FloatLiteral = [0-9]+ "." [0-9]+;
lexical CharLiteral = [a-z];

keyword Reserved = 
  "cond" | "do" | "data" | "end" | "for" | "from" | "then"
| "function" | "else" | "if" | "in" | "iterator" | "sequence" | "struct"
| "to" | "tuple" | "type" | "with" | "yielding" | "and" | "or" | "neg"
| "true" | "false"
| "Int" | "Bool" | "Char" | "String"
;

// ---------- Tipos ----------
syntax TypeName
  = "Int" | "Bool" | "Char" | "String" | Identifier;

// ---------- START ----------
start syntax Module = Variables? ModuleItem*;

syntax ModuleItem = Function | Data;

// ---------- Variables ----------
syntax Variables = Identifier ("," Identifier)*;

// ---------- Function ----------
syntax Function 
  = Assignment? "function" "(" Variables ")" "do" Body "end" Identifier
  | Assignment? "function" "do" Body "end" Identifier
  ;

// ---------- Data ----------
syntax Data 
  = Assignment? "data" "with" TypedVariables DataBody "end" Identifier
  | Assignment? "data" "with" Variables DataBody "end" Identifier
  ;

syntax TypedVariables = TypedVariable ("," TypedVariable)*;
syntax TypedVariable = Identifier ":" TypeName | Identifier;

syntax DataBody = DataBodyItem*;
syntax DataBodyItem = Constructor | Function;

syntax Constructor = Identifier "=" "struct" "(" Variables ")";

// ---------- Assignment ----------
syntax Assignment = Identifier "=";

// ---------- Body ----------
syntax Body = Statement*;

syntax Statement
  = Expression
  | Variables  
  | Range
  | Iterator
  | Loop
  | "if" Expression "then" Body "else" Body "end"
  | "cond" Expression "do" PatternBody "end"
  | Invocation
  ;

// ---------- Range ----------
syntax Range = Assignment? "from" Principal "to" Principal;

// ---------- Iterator ----------
syntax Iterator = Assignment "iterator" "(" Variables ")" "yielding" "(" Variables ")";

// ---------- Loop ----------
syntax Loop = "for" Identifier Range "do" Body "end";

// ---------- Pattern ----------
syntax PatternBody = PatternCase+;
syntax PatternCase = Expression "-\>" Expression;

// ---------- Expression ----------
syntax Expression
  = Principal
  | Invocation
  | bracket "(" Expression ")"
  | "[" Expression "]"
  > right "-" Expression
  > left Expression "**" Expression
  > left Expression "*" Expression
  | left Expression "/" Expression
  | left Expression "%" Expression
  > left Expression "+" Expression
  | left Expression "-" Expression
  > non-assoc Expression "\<" Expression
  | non-assoc Expression "\>" Expression
  | non-assoc Expression "\<=" Expression
  | non-assoc Expression "\>=" Expression
  | non-assoc Expression "\<\>" Expression
  | non-assoc Expression "=" Expression
  > left Expression "and" Expression
  > left Expression "or" Expression
  > right Expression "-\>" Expression
  > right Expression ":" Expression
  ;

// ---------- Invocation ----------
syntax Invocation
  = Identifier "$" "(" Variables? ")"
  | Identifier "." Identifier "(" Variables? ")"
  ;

// ---------- Principal ----------
syntax Principal
  = "true" | "false"
  | CharLiteral
  | FloatLiteral  
  | IntLiteral
  | Identifier
  ;