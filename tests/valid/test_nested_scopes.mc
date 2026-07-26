/* tests/valid/test_nested_scopes.mc
   Test: Nested scopes — inner variables not visible outside
   Expected: Compiles cleanly, inner 'temp' only exists inside while block
*/
int x;
int y;

x = 10;
y = 0;

while (x > 0) {
    int temp;          /* temp only exists inside this { } block */
    temp = x * 2;
    y = y + temp;
    x = x - 1;
}

/* temp is NOT visible here — out of scope */
print y;
