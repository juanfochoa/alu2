module Collect

import Syntax;
import ParseTree;
import IO;

extend analysis::typepal::TypePal;

// Roles
data IdRole = variableId() | functionId() | dataTypeId();

private str t2s(Tree t) = "<t>";

// ==================== Module ====================
void collect(current: start[Module] m, Collector c) {
  c.enterScope(current);
  visit(m) {
    case (Function) f: collect(f, c);
    case (Data) d: collect(d, c);
    case (Variables) vs: collect(vs, c);
  }
  c.leaveScope(current);
}

// ==================== Variables ====================
void collect(current: (Variables) vars, Collector c) {
  visit(vars) {
    case Identifier id: c.define(t2s(id), variableId(), id, defType(tyVoid()));
  }
}

// ==================== Data ====================
void collect(current: (Data) d, Collector c) {
  // Buscar el primer identificador (nombre del data - puede estar en assignment)
  list[Identifier] allIds = [id | /Identifier id := d];
  
  if (size(allIds) >= 2) {
    // Primer ID es el nombre asignado: complex = data...
    c.define(t2s(allIds[0]), dataTypeId(), allIds[0], defType(tyVoid()));
  }
  
  c.enterScope(current);
  
  // Recolectar constructores y funciones dentro
  visit(d) {
    case (Constructor) cons: collect(cons, c);
    case (Function) func: collect(func, c);
  }
  
  c.leaveScope(current);
}

void collect(current: (Constructor) cons, Collector c) {
  // Buscar el identificador del constructor (rep = struct...)
  list[Identifier] ids = [id | /Identifier id := cons];
  if (size(ids) > 0) {
    c.define(t2s(ids[0]), functionId(), ids[0], defType(tyVoid()));
  }
}

// ==================== Function ====================
void collect(current: (Function) f, Collector c) {
  // Buscar identificadores
  list[Identifier] allIds = [id | /Identifier id := f];
  
  if (size(allIds) >= 2) {
    // Primer ID es el nombre asignado: create = function...
    // Último ID es después del end
    c.define(t2s(allIds[0]), functionId(), allIds[0], defType(tyVoid()));
  }
  
  c.enterScope(current);
  
  // Parámetros (los que están entre paréntesis al inicio)
  bool foundParams = false;
  visit(f) {
    case Identifier p: {
      if (!foundParams && "function" in "<f>"[..50]) {
        c.define(t2s(p), variableId(), p, defType(tyVoid()));
      }
    }
  }
  
  // Body
  visit(f) {
    case (Body) body: collect(body, c);
  }
  
  c.leaveScope(current);
}

// ==================== Body ====================
void collect(current: (Body) body, Collector c) {
  visit(body) {
    case (Statement) stmt: collect(stmt, c);
  }
}

void collect(current: (Statement) stmt, Collector c) {
  visit(stmt) {
    case Expression e: collect(e, c);
    case Invocation inv: collect(inv, c);
    case Body b: collect(b, c);
  }
}

// ==================== Expression ====================
void collect(current: (Expression) e, Collector c) {
  visit(e) {
    case Identifier x: c.use(x, {variableId(), functionId()});
    case Invocation inv: collect(inv, c);
  }
}

// ==================== Invocation ====================
void collect(current: (Invocation) inv, Collector c) {
  list[Identifier] ids = [id | /Identifier id := inv];
  if (size(ids) > 0) {
    c.use(ids[0], {functionId()});
  }
}

// Catch-all
default void collect(Tree t, Collector c) {}