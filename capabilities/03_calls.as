/*
A language simply with support of file and global scopes,
variable and function declarations, function bodies and function calls
No assignments
*/
gvar a int
var b int

gfunc add(a number, b number) (number, number) {
    return a + b * 3
}

func mult(a number, b number){
}

func main(){
    func inner(){
    }
    --add(5, 6)
    var x int
}