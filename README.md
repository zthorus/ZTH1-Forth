# ZTH1-Forth
Forth cross-compiler for ZTH1 CPU machines

This is a Forth language cross-compiler running under Linux and producing .mif files for the machines using the ZTH1 CPU (the Zythium-1 computer and the VectorUGo-2 game console). It includes for each of these machines an "OS" consisting of a library of base routines (arithmetic, text display, sprite management,...) written in assembly language that can be called by Forth words which have been defined in the built-in dictionary of ZTH1-Forth. 

The ZTH1-Forth language is not fully standard and has been adapted to the peculiarities of the ZTH1 CPU, in order to optimize the object code. Please refer to the document ZTH1_forth.pdf in this repository to use this cross-compiler. Details on the VectorUGo-2 OS can be found in the document VUG2_OS.pdf located in this repository.
