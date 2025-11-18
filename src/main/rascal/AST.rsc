module AST

// ==================== TIPOS ====================
data Type
  = intType()
  | boolType()
  | charType()
  | stringType()
  | userType(str name)
  | unknownType()
  ;

// Programa y módulos
data Program = program(list[Module] modules);

data Module
  = funMod(FunctionDecl f)
  | dataMod(DataDecl d)
  ;

// Declaraciones 
data FunctionDecl = function(
  str name,
  list[str] params,
  list[Statement] body
);

data DataDecl = dataDecl(
  str name,
  list[str] fields
);

// Sentencias 
data Statement
  = assign(list[str] lhs, Expression rhs)
  | ifStmt(
      Condition cond,
      list[Statement] thenBody,
      list[tuple[Condition, list[Statement]]] elifs,
      list[Statement] elseBody
    )
  | condStmt(
      str selector,
      list[tuple[Condition, list[Statement]]] branches
    )
  | forStmt(
      str var,
      Range range,
      list[Statement] body
    )
  | exprStmt(Expression e)
  ;

// Rango y condición
data Range = range(Expression lo, Expression hi);

data Operator = lt() | gt() | le() | ge() | ne() | eq() | and() | or();

data Condition = condition(Expression left, Operator op, Expression right);

// Expresiones
data Expression
  = add(Expression left, Expression right)
  | sub(Expression left, Expression right)
  | mul(Expression left, Expression right)
  | div(Expression left, Expression right)
  | call(str callee, list[Expression] args)
  | var(str name)
  | number(str lexeme)
  | boolean(bool b)
  | char(str c)
  | string(str s)
  ;