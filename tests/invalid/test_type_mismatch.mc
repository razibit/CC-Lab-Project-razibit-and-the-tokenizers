/* tests/invalid/test_type_mismatch.mc
   Test: Semantic error — assigning wrong type to a variable
   Expected: Type mismatch errors for each assignment
*/
int x;
bool flag;
float rate;

/* ERROR: assigning float expression to int */
x = 3.14;

/* ERROR: assigning int+int expression to bool */
flag = 5 + 3;

/* ERROR: assigning bool to float */
rate = true;

print x;
