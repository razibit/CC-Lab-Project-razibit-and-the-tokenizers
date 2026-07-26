/* tests/invalid/test_undeclared.mc
   Test: Semantic error — using a variable before declaring it
   Expected: "Semantic Error: Variable 'y' used before declaration"
*/
int x;

x = 10;
y = 20;    /* ERROR: y not declared */
z = x + y; /* ERROR: z and y not declared */

print w;   /* ERROR: w not declared */
