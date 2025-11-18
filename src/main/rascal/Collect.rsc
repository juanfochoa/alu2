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
  }
  c.leaveScope(current);
}

// ==================== Data ====================
void collect(current: (Data) d, Collector c) {
  // Encuentra el último identificador (nombre del data)
  list[Identifier] ids = [id | /Identifier id := d];
  if (size(ids) > 0) {
    c.define(t2s(ids[-1]), dataTypeId(), ids[-1], defType(tyVoid()));
  }
  
  c.enterScope(current);
  
  // Recolecta funciones y constructores dentro
  visit(d) {
    case (Function) f: collect(f, c);
    case (Constructor) cons: {
      visit(cons) {
        case (Assignment) `<Identifier id> =`:
          c.define(t2s(id), functionId(), id, defType(tyVoid()));
      }
    }
  }
  
  c.leaveScope(current);
}

// ==================== Function ====================
void collect(current: (Function) f, Collector c) {
  // Encuentra el último identificador (nombre de la función)
  list[Identifier] ids = [id | /Identifier id := f];
  if (size(ids) > 0) {
    c.define(t2s(ids[-1]), functionId(), ids[-1], defType(tyVoid()));
  }
  
  c.enterScope(current);
  
  // Recolecta el body
  visit(f) {
    case (Body) body: collect(body, c);
  }
  
  c.leaveScope(current);
}

// ==================== Body ====================
void collect(current: (Body) body, Collector c) {
  visit(body) {
    case (Expression) e: collect(e, c);
    case (Invocation) inv: collect(inv, c);
  }
}

// ==================== Expression ====================
void collect(current: (Expression) e, Collector c) {
  visit(e) {
    case (Identifier) x: c.use(x, {variableId(), functionId()});
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