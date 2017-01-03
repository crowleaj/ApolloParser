/*
A language simply with support of file and global scopes,
variable and function declarations, function bodies, arithmetic, assignments
and arrays of any dimension
Function calls, but not in assignments or arithmetic
*/

//include "capabilities/02_bodies"

gvar a int
var b int

//(Lua) function.  Header to make lua calls so they do not have to be recreated.
lfunc print(a Any)

gfunc add(a number, b number) number {
    return a + b
}

func mult(a number, b number) {
}

func main(){
    //add(5, 6)
    var k []int  = [1 + 2, 2, 3]
    var x int = 5
    var hi int = 5 + 2 * 3
    var y char = -2^4^-(x >> 4)//3 * -b//(6 + 5)
    print(y)
    var z int = add(2,3)
    print(z)
    print(hi)
}
