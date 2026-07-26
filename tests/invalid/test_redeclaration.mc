/* tests/invalid/test_redeclaration.mc
   Test: Semantic error — declaring the same variable twice in same scope
   Expected: "Semantic Error: Variable 'x' already declared in this scope"
*/
int x;
int x;   /* ERROR: x already declared */

bool flag;
bool flag; /* ERROR: flag already declared */

x = 5;
print x;
