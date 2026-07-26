/* examples/invalid/sample.mc
   Sample INVALID program — demonstrates error detection.
   Contains: lexical error, syntax error, semantic errors.
   Use during demo to show the compiler catches mistakes.
*/

/* SEMANTIC ERROR 1: Using 'y' before declaring it */
y = 20;

int x;
bool flag;

x = 10;

/* SEMANTIC ERROR 2: Assigning int expression to bool variable */
flag = x + 5;

/* SYNTAX ERROR: Missing closing parenthesis */
if (x > 0 {
    print x;
}

/* SEMANTIC ERROR 3: Redeclaring x */
int x;

/* LEXICAL ERROR: '@' is not a valid character */
@invalid_token;
