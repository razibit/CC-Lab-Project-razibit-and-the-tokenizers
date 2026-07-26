/* tests/valid/test_while.mc
   Test: While loop and nested scope
   Expected: Compiles cleanly, TAC shows Lstart/Lend labels
*/
int n;
int sum;

n = 5;
sum = 0;

while (n > 0) {
    sum = sum + n;
    n = n - 1;
}

print sum;   /* expected: sum = 15 */
