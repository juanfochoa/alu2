module Syntax

// ---------- Layout ----------
layout Layout = WhitespaceAndComment* !>> [\ \t\n\r];
lexical WhitespaceAndComment 
  = [\ \t\n\r]
  | @category="Comment" "//" ![\n]* [\n]?
  ;

// ---------- Tokens ----------
lexical Identifier = [a-z] [a-z0-9\-]* !>> [a-z0-9\-] \ Reserved;
lexical IntLiteral = [0-9]+ !>> [0-9];
lexical FloatLiteral = [0-9]+ "." [0-9]+ !>> [0-9];
lexical CharLiteral = "\'" [a-z] "\'";

keyword Reserved = 
  "cond" | "do" | "data" | "end" | "for" | "from" | "then"
| "function" | "else" | "elseif" | "if" | "in" | "iterator" | "sequence" | "struct"
| "to" | "tuple" | "type" | "with" | "yielding" | "and" | "or" | "neg"
| "true" | "false"
| "Int" | "Bool" | "Char" | "String"
;

// ---------- Tipos (Project 3) ----------
syntax TypeName
  = "Int" | "Bool" | "Char" | "String" | Identifier;

// ---------- START: Module ----------
start syntax Module = ModuleItem*;

syntax ModuleItem 
  = Function
  | Data
  | Variables
  ;

// ---------- Variables (declaración global) ----------
syntax Variables = {Identifier ","}+;

// ---------- Function ----------
syntax Function 
  = Identifier "=" "function" "(" {Identifier ","}* ")" "do" Body "end" Identifier
  | Identifier "=" "function" "do" Body "end" Identifier
  | "function" "(" {Identifier ","}* ")" "do" Body "end" Identifier
  | "function" "do" Body "end" Identifier
  ;

// ---------- Data ----------
syntax Data 
  = Identifier "=" "data" "with" {Identifier ","}+ DataBody "end" Identifier
  | "data" "with" {Identifier ","}+ DataBody "end" Identifier
  ;

syntax DataBody = DataBodyItem*;

syntax DataBodyItem 
  = Constructor
  | Function
  ;

syntax Constructor = Identifier "=" "struct" "(" {Identifier ","}+ ")";

// ---------- Body / Statements ----------
syntax Body = Statement*;

syntax Statement
  = Identifier "=" Expression                    // Assignment
  | "if" Expression "then" Body ElseIfClause* "else" Body "end"
  | "cond" Identifier "do" {PatternCase ","}+ "end"
  | "for" Identifier "from" Range "do" Body "end"
  | "for" Identifier "in" Expression "do" Body "end"
  | Expression                                   // Expression statement
  ;

syntax ElseIfClause = "elseif" Expression "then" Body;

// ---------- Range ----------
syntax Range = Expression "to" Expression;

// ---------- Pattern ----------
syntax PatternCase = Expression "-\>" Expression;

// ---------- Expression (precedencia según proyecto) ----------
syntax Expression
  = Principal
  | Invocation
  | bracket "(" Expression ")"
  | bracket "[" Expression "]"
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
  = Identifier "$" "(" {Expression ","}* ")"
  | Identifier "." Identifier "(" {Expression ","}* ")"
  | Identifier "(" {Expression ","}* ")"
  ;

// ---------- Principal ----------
syntax Principal
  = "true" 
  | "false"
  | CharLiteral
  | FloatLiteral  
  | IntLiteral
  | Identifier
  ;