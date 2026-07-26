/* tests/valid/test_arithmetic.mc
   Test: Arithmetic expressions and operator precedence
   Expected: Compiles cleanly, TAC shows correct precedence
*/
int a;
int b;
int c;

a = 5;
b = 10;

/* c = a + b * 2 — multiplication before addition */
c = a + b * 2;

print c;   /* expected: c = 25 */
