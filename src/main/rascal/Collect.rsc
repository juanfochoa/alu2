module Collect

import Syntax;
import ParseTree;
import IO;

// Imports correctos para TypePal
extend analysis::typepal::TypePal;

// Roles para identificadores
data IdRole = variableId() | functionId() | dataTypeId() | fieldId();

private str t2s(Tree t) = "<t>";

// ==================== MAPEO DE TIPOS ====================
AType mapType(TypeName tn) {
  str s = t2s(tn);
  switch (s) {
    case "Int":    return tyInt();
    case "Bool":   return tyBool();
    case "Char":   return tyChar();
    case "String": return tyString();
    default:       return tyVoid(); // tipo de usuario (para data types)
  }
}

// Punto de entrada
void collect(current: start[Program] p, Collector c) = collect(p.top, c);

/* =========================
 * Programa & Modulo
 * ========================= */
void collect(current: (Program) `<Module* ms>`, Collector c) {
  c.enterScope(current);
  for (Module m <- ms) collect(m, c);
  c.leaveScope(current);
}

void collect(current: (Module) `<FunctionModule f>`, Collector c) = collect(f, c);
void collect(current: (Module) `<DataModule d>`, Collector c) = collect(d, c);

/* =========================
 * Declaraciones de Data con tipos
 * ========================= */
void collect(current: (DataModule)
  `data <Identifier id> with <TypedIdentifierList til> end`, Collector c) {
  c.define(t2s(id), dataTypeId(), id, defType(tyVoid()));
  c.enterScope(current);
  // Recolectar campos con tipos
  visit(til) {
    case (TypedIdentifier) `<Identifier fid> : <TypeName tn>`:
      c.define(t2s(fid), fieldId(), fid, defType(mapType(tn)));
    case (TypedIdentifier) `<Identifier fid>`:
      c.define(t2s(fid), fieldId(), fid, defType(tyVoid()));
  }
  c.leaveScope(current);
}

// Compatibilidad sin tipos
void collect(current: (DataModule)
  `data <Identifier id> with <IdentifierList il> end`, Collector c) {
  c.define(t2s(id), dataTypeId(), id, defType(tyVoid()));
  c.enterScope(current);
  visit(il) {
    case (Identifier) i:
      c.define(t2s(i), fieldId(), i, defType(tyVoid()));
  }
  c.leaveScope(current);
}

/* =========================
 * Funciones
 * ========================= */
void collect(current: (FunctionModule)
  `function <Identifier id> ( ) do <Statements ss> end`, Collector c) {
  c.define(t2s(id), functionId(), id, defType(tyVoid()));
  c.enterScope(current);
  collect(ss, c);
  c.leaveScope(current);
}

void collect(current: (FunctionModule)
  `function <Identifier id> ( <Parameters ps> ) do <Statements ss> end`, Collector c) {
  c.define(t2s(id), functionId(), id, defType(tyVoid()));
  c.enterScope(current);
  visit(ps) {
    case (Identifier) p:
      c.define(t2s(p), variableId(), p, defType(tyVoid()));
  }
  collect(ss, c);
  c.leaveScope(current);
}

/* =========================
 * Statements / Bloques
 * ========================= */
void collect(current: (Statements) `<Statement+ ss>`, Collector c) {
  for (Statement s <- ss) collect(s, c);
}

void collect(current: (Statement) `<ControlStatement cs>`, Collector c) = collect(cs, c);

void collect(current: (Statement) `<Expression e>`, Collector c) = collect(e, c);

// Asignación con definición de variables
void collect(current: (Expression) `<VariableList vs> = <Expression e>`, Collector c) {
  collect(e, c);
  visit(vs) {
    case (Identifier) v:
      c.define(t2s(v), variableId(), v, defType(tyVoid()));
  }
}

/* =========================
 * Control: if / elseif / else 
 * ========================= */
void collect(current: (IfExpression) iexp, Collector c) {
  visit(iexp) {
    case (Condition) cnd: collect(cnd, c);
    case (Statements) body: {
      c.enterScope(body);
      collect(body, c);
      c.leaveScope(body);
    }
  }
}

/* =========================
 * Control: for
 * ========================= */
void collect(current: (ForExpression)
  `for <Identifier v> from <Range r> do <Statements b> end`, Collector c) {
  c.enterScope(current);
  c.define(t2s(v), variableId(), v, defType(tyInt()));
  collect(r, c);
  collect(b, c);
  c.leaveScope(current);
}

/* =========================
 * Control: cond
 * ========================= */
void collect(current: (CondExpression) cexp, Collector c) {
  visit(cexp) {
    case (Identifier) sel: c.use(sel, {variableId(), functionId()});
    case (Condition) g: collect(g, c);
    case (Statements) s: {
      c.enterScope(s);
      collect(s, c);
      c.leaveScope(s);
    }
  }
}

/* =========================
 * Rango / Condición
 * ========================= */
void collect(current: (Range) `<Expression lo> to <Expression hi>`, Collector c) {
  collect(lo, c);
  collect(hi, c);
  c.requireEqual(lo, tyInt(), error(lo, "Range lower bound must be Int"));
  c.requireEqual(hi, tyInt(), error(hi, "Range upper bound must be Int"));
}

void collect(current: (Condition) `<Expression a> <Operator _> <Expression b>`, Collector c) {
  collect(a, c);
  collect(b, c);
  c.fact(current, tyBool());
}

/* =========================
 * Expresiones
 * ========================= */
void collect(current: (Expression) `<Add a>`, Collector c) = collect(a, c);
void collect(current: (Add) `<Mul m>`, Collector c) = collect(m, c);
void collect(current: (Mul) `<Primary p>`, Collector c) = collect(p, c);

void collect(current: (Add) `<Add l> + <Add r>`, Collector c) {
  collect(l, c); collect(r, c);
  c.calculate("add", current, [l, r],
    AType(Solver s) {
      s.requireEqual(l, tyInt(), error(l, "Left operand must be Int"));
      s.requireEqual(r, tyInt(), error(r, "Right operand must be Int"));
      return tyInt();
    });
}

void collect(current: (Add) `<Add l> - <Add r>`, Collector c) {
  collect(l, c); collect(r, c);
  c.calculate("sub", current, [l, r],
    AType(Solver s) {
      s.requireEqual(l, tyInt(), error(l, "Left operand must be Int"));
      s.requireEqual(r, tyInt(), error(r, "Right operand must be Int"));
      return tyInt();
    });
}

void collect(current: (Mul) `<Mul l> * <Mul r>`, Collector c) {
  collect(l, c); collect(r, c);
  c.calculate("mul", current, [l, r],
    AType(Solver s) {
      s.requireEqual(l, tyInt(), error(l, "Left operand must be Int"));
      s.requireEqual(r, tyInt(), error(r, "Right operand must be Int"));
      return tyInt();
    });
}

void collect(current: (Mul) `<Mul l> / <Mul r>`, Collector c) {
  collect(l, c); collect(r, c);
  c.calculate("div", current, [l, r],
    AType(Solver s) {
      s.requireEqual(l, tyInt(), error(l, "Left operand must be Int"));
      s.requireEqual(r, tyInt(), error(r, "Right operand must be Int"));
      return tyInt();
    });
}

/* =========================
 * Llamadas y primarios
 * ========================= */
void collect(current: (Primary) `<FunctionCall fc>`, Collector c) = collect(fc, c);
void collect(current: (Primary) `<Identifier x>`, Collector c) = 
  c.use(x, {variableId(), functionId()});
void collect(current: (Primary) `<Value v>`, Collector c) = collect(v, c);

void collect(current: (FunctionCall) fc, Collector c) {
  visit(fc) {
    case (Identifier) f: c.use(f, {functionId()});
    case (Expression) e: collect(e, c);
  }
}

/* =========================
 * Valores literales
 * ========================= */
void collect(current: (Value) `<Number _>`, Collector c) = c.fact(current, tyInt());
void collect(current: (Value) `<Boolean _>`, Collector c) = c.fact(current, tyBool());
void collect(current: (Value) `<Char _>`, Collector c) = c.fact(current, tyChar());
void collect(current: (Value) `<String _>`, Collector c) = c.fact(current, tyString());