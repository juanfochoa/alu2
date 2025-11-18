module TypeChecker

import Syntax;
import ParseTree;
import Collect;
import IO;

extend analysis::typepal::TypePal;

TypePalConfig cfg() = tconfig(
  verbose = true,
  logTModel = true
);

public TModel typeCheckTree(Tree pt) {
  if (pt has top) pt = pt.top;
  c = newCollector("alu", pt, cfg());
  collect(pt, c);
  return newSolver(pt, c.run()).run();
}

public void typeCheckFile(loc file) {
  try {
    println("Reading file: <file>");
    str src = readFile(file);
    
    println("Parsing...");
    start[Module] pt = parse(#start[Module], src, file);
    
    println("Type checking...");
    TModel tm = typeCheckTree(pt);
    
    println("\n=== TYPE CHECKING RESULTS ===");
    if (size(tm.messages) == 0) {
      println("✓ No type errors found!");
    } else {
      println("✗ Type errors found:");
      for (msg <- tm.messages) {
        println("  - <msg>");
      }
    }
    
    println("\n=== DEFINITIONS ===");
    for (def <- tm.definitions) {
      println("  <def>");
    }
    
  } catch ParseError(loc l): {
    println("Parse error at <l>");
  } catch e: {
    println("Error: <e>");
  }
}

// Para usar desde el terminal de Rascal
public void checkMainFile() {
  typeCheckFile(|file:///C:/Users/jfoch/PLE/alu2/instance/prueba.alu|);
}