module Collect

import Syntax;
import ParseTree;
import IO;
import Set;
import String;
import List;

extend analysis::typepal::TypePal;

// Roles para identificadores
data IdRole = variableId() | functionId() | dataTypeId() | fieldId();

private str t2s(Tree t) = "<t>";

// Mapeo de tipos
AType mapType(str typeName) {
  switch (typeName) {
    case "Int": return tyInt();
    case "Bool": return tyBool();
    case "Char": return tyChar();
    case "String": return tyString();
    default: return tyVoid();
  }
}

// ==================== Module ====================
void collect(current: start[Module] m, Collector c) {
  c.enterScope(current);
  collect(m.top, c);
  c.leaveScope(current);
}

void collect(current: (Module) `<Variables? vs> <Function* fs> <Data* ds>`, Collector c) {
  if (vs is Variables) collect(vs, c);
  for (f <- fs) collect(f, c);
  for (d <- ds) collect(d, c);
}

// ==================== Variables ====================
void collect(current: (Variables) vars, Collector c) {
  for (/Identifier id := vars) {
    c.define(t2s(id), variableId(), id, defType(tyVoid()));
  }
}

// ==================== Data ====================
void collect(current: (Data) d, Collector c) {
  str dataName = "";
  
  // Extraer nombre del data (último identificador)
  list[Identifier] ids = [id | /Identifier id := d];
  if (size(ids) > 0) {
    dataName = t2s(ids[-1]);
    c.define(dataName, dataTypeId(), ids[-1], defType(tyVoid()));
  }
  
  c.enterScope(current);
  
  // Recolectar campos con tipos (TypedVariables)
  for (/(TypedVariables) tvs := d) {
    for (/(TypedVariable) tv := tvs) {
      str fieldName = "";
      AType fieldType = tyVoid();
      
      for (/Identifier fid := tv) {
        fieldName = t2s(fid);
        break;
      }
      
      for (/TypeName tn := tv) {
        fieldType = mapType(t2s(tn));
      }
      
      if (fieldName != "") {
        c.define(fieldName, fieldId(), tv@\loc, defType(fieldType));
      }
    }
  }
  
  // Si no hay TypedVariables, buscar Variables simple
  for (/(Variables) vs := d, /(TypedVariables) _ !:= d) {
    for (/Identifier fid := vs) {
      c.define(t2s(fid), fieldId(), fid, defType(tyVoid()));
    }
  }
  
  // Recolectar constructores o funciones dentro
  for (/(DataBody) db := d) {
    collect(db, c);
  }
  
  c.leaveScope(current);
}

void collect(current: (DataBody) db, Collector c) {
  for (/(Constructor) cons := db) collect(cons, c);
  for (/(Function) func := db) collect(func, c);
}

void collect(current: (Constructor) cons, Collector c) {
  // Los constructores definen funciones
  for (/Identifier id := cons, "struct" notin t2s(id)) {
    c.define(t2s(id), functionId(), id, defType(tyVoid()));
    break;
  }
}

// ==================== Function ====================
void collect(current: (Function) f, Collector c) {
  str funcName = "";
  
  // Extraer nombre de función (último identificador)
  list[Identifier] ids = [id | /Identifier id := f];
  if (size(ids) > 0) {
    funcName = t2s(ids[-1]);
    c.define(funcName, functionId(), ids[-1], defType(tyVoid()));
  }
  
  c.enterScope(current);
  
  // Recolectar parámetros
  for (/(Variables) params := f, /(Body) _ !:= params) {
    for (/Identifier p := params) {
      c.define(t2s(p), variableId(), p, defType(tyVoid()));
    }
    break;
  }
  
  // Recolectar cuerpo
  for (/(Body) body := f) {
    collect(body, c);
  }
  
  c.leaveScope(current);
}

// ==================== Body / Statements ====================
void collect(current: (Body) `<Statement* stmts>`, Collector c) {
  for (stmt <- stmts) collect(stmt, c);
}

void collect(current: (Statement) stmt, Collector c) {
  visit(stmt) {
    case Expression e: collect(e, c);
    case Variables vs: collect(vs, c);
    case Range r: collect(r, c);
    case Iterator ite: collect(ite, c);
    case Loop lp: collect(lp, c);
    case Invocation inv: collect(inv, c);
    case Body b: collect(b, c);
  }
}

// ==================== Range ====================
void collect(current: (Range) `<Assignment? _> from <Principal lo> to <Principal hi>`, Collector c) {
  collect(lo, c);
  collect(hi, c);
}

// ==================== Iterator ====================
void collect(current: (Iterator) ite, Collector c) {
  c.enterScope(current);
  for (/(Variables) vs := ite) {
    collect(vs, c);
  }
  c.leaveScope(current);
}

// ==================== Loop ====================
void collect(current: (Loop) `for <Identifier i> <Range r> do <Body b> end`, Collector c) {
  c.enterScope(current);
  c.define(t2s(i), variableId(), i, defType(tyInt()));
  collect(r, c);
  collect(b, c);
  c.leaveScope(current);
}

// ==================== Expression ====================
void collect(current: (Expression) e, Collector c) {
  visit(e) {
    case Principal p: collect(p, c);
    case Invocation inv: collect(inv, c);
  }
}

// ==================== Invocation ====================
void collect(current: (Invocation) inv, Collector c) {
  for (/Identifier id := inv) {
    c.use(id, {functionId()});
    break; // Solo el primero es la función
  }
}

// ==================== Principal ====================
void collect(current: (Principal) `<Identifier x>`, Collector c) {
  c.use(x, {variableId(), functionId()});
}

void collect(current: (Principal) `<IntLiteral _>`, Collector c) {
  c.fact(current, tyInt());
}

void collect(current: (Principal) `<FloatLiteral _>`, Collector c) {
  c.fact(current, tyInt()); // o podrías crear tyFloat()
}

void collect(current: (Principal) `<CharLiteral _>`, Collector c) {
  c.fact(current, tyChar());
}

void collect(current: (Principal) `true`, Collector c) {
  c.fact(current, tyBool());
}

void collect(current: (Principal) `false`, Collector c) {
  c.fact(current, tyBool());
}

// Catch-all para otros nodos
default void collect(Tree t, Collector c) {
  // No hacer nada para otros nodos
}