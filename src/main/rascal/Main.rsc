module Main

import IO;
import AST;
import Implode;
import Generator1;

public void main(list[str] args=[]) {
  str path =
    (args == [])
      // cambiar por la ruta de archivo
      ? "C:/Users/jfoch/PLE/alu2/instance/prueba.alu"
      : args[0];

  if (args == [])
    println("No se proporcionó ruta. Usando por defecto: <path>");

  str src = readFile(|file://<path>|);
  println(src); 
  Program p = Implode::toAST(src, |file://<path>|);
  runProgram(p);
}

