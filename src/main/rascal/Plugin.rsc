module Plugin

import IO;
import ParseTree;
import util::Reflective;
import util::IDEServices;
import util::LanguageServer;
import Relation;
import Syntax;
import Collect;

// Import correcto para TypePal
extend analysis::typepal::TypePal;

PathConfig pcfg = getProjectPathConfig(|project://alu2|);

Language aluLang = language(pcfg, "ALU", "alu", "Plugin", "contribs");

TypePalConfig cfg() = tconfig(
  verbose = false,
  logTModel = false
);

TModel TModelFromTree(Tree pt) {
  if (pt has top) pt = pt.top;
  TypePalConfig config = cfg();
  c = newCollector("collectAndSolve", pt, config);
  collect(pt, c);
  return newSolver(pt, c.run()).run();
}

Summary aluSummarizer(loc l, start[Program] input) {
  try {
    tm = TModelFromTree(input);
    defs = getUseDef(tm);
    return summary(l, 
      messages = {<m.at, m> | m <- getMessages(tm)},
      definitions = defs
    );
  } catch e: {
    println("Error in summarizer: <e>");
    return summary(l, messages = {});
  }
}

set[LanguageService] contribs() = {
  parser(start[Program] (str program, loc src) {
    return parse(#start[Program], program, src);
  }),
  summarizer(aluSummarizer)
};

public void main() { 
  registerLanguage(aluLang); 
  println("ALU Language registered with TypePal support");
}