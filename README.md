# ZTH1-Forth
Forth cross-compiler for the ZTH1 computer

This is a Forth language cross-compiler running under Linux and producing .mif files for the ZTH1 computer. It includes an "OS" consisting of a a library of base routines (arithmetic, text display...) written in assembly language. 

The Forth language of this compiler is not fully standard and has been adapted to the peculiarities of the ZTH1 CPU, in order to optimize the object code. Please refer to the document ZTH1_forth.pdf in this repository to use this compiler.
