/* examples/valid/sample.mc
   Sample valid program — demonstrates all language features.
   This is the primary demo program used during the presentation.
*/

/* Declare variables */
int x;
int y;
bool flag;
float rate;

/* Assign values */
x = 10;
y = 0;
flag = true;
rate = 3.14;

/* While loop — count down and accumulate sum */
while (x > 0) {
    y = y + x;
    x = x - 1;
}

/* If-else — conditional print */
if (flag == true) {
    print y;
} else {
    print x;
}

/* Nested if inside while */
int i;
int result;
i = 5;
result = 1;

while (i > 0) {
    result = result * i;
    i = i - 1;
    if (result > 100) {
        print result;
    }
}

print result;
