/* tests/valid/test_if_else.mc
   Test: If-else with boolean expressions
   Expected: Compiles cleanly, correct TAC with conditional jumps
*/
int x;
bool flag;

x = 42;
flag = true;

if (flag == true) {
    print x;
} else {
    x = 0;
    print x;
}
