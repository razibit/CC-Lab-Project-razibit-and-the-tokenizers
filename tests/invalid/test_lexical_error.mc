/* tests/invalid/test_lexical_error.mc
   Test: Lexical error — invalid characters
   Expected: Lexical Error messages for '@', '#', '$'
*/
int x;
x = 10;

/* These characters are invalid in our language */
@ invalid_char;
# another_bad_char;
$ yet_another;

print x;
