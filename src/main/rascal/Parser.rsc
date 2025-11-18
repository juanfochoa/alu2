module Parser

import ParseTree;
import Syntax;

public Tree parse(str input, loc src) {
  return parse(#start[Module], input, src);
}