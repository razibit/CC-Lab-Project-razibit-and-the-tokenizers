/* tests/invalid/test_syntax_error.mc
   Test: Syntax errors — missing tokens
   Expected: Syntax Error messages, compiler recovers and continues
*/
int x;
int y;

x = 10

/* Missing semicolon above — syntax error */

/* Missing closing parenthesis */
if (x > 0 {
    y = x;
}

/* Missing semicolon again */
y = 5
