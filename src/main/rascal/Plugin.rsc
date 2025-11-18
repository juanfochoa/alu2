module Plugin

import IO;
import ParseTree;
import util::Reflective;
import util::IDEServices;
import util::LanguageServer;
import Syntax;
import Collect;

extend analysis::typepal::TypePal;

PathConfig pcfg = getProjectPathConfig(|project://alu2|);

Language aluLang = language(pcfg, "ALU", "alu", "Plugin", "contribs");

TModel TModelFromTree(Tree pt) {
  if (pt has top) pt = pt.top;
  c = newCollector("alu", pt, tconfig(verbose = false));
  collect(pt, c);
  return newSolver(pt, c.run()).run();
}

Summary aluSummarizer(loc l, start[Module] input) {
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
  parser(start[Module] (str program, loc src) {
    return parse(#start[Module], program, src);
  }),
  summarizer(aluSummarizer)
};

public void main() { 
  registerLanguage(aluLang); 
  println("✓ ALU Language registered with TypePal");
}