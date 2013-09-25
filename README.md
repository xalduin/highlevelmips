highlevelmips
=============
Prototype high level language to MIPS compiler capable of compiling individual functions into MIPS assembly.

Language Features
=================
* Functions
* Local variables
* Basic arithmatic
* Arrays
* If/Else statements
* Loops
* Standard input/output

Example syntax:
````
func add(a:word, b:word) -> word
    return a + b
endfunc

func test() -> word
    var abc:word
    abc = 5

    loop
        exitwhen abc > 6
        abc = abc + 1
    endloop

    if abc == 5
        abc = abc * 2
    endif

    return add(abc, 5)
endfunc
````


Requirements
============
Ruby version 2.0 or greater

To Run
======

    ruby main.rb <input file>

Will produce an output file with the same name as the input with a .asm suffix.

Warning, this prototype is not feature complete and may contain bugs.
