/* =============================================================
   lexer.l  —  Lexical Analyzer for the Mini Compiler
   Course:  Compiler Construction Lab
   Team:    Razibit and The Tokenizers
   University: Metropolitan University, Bangladesh

   HOW IT WORKS (explain to teacher):
     Flex reads this file and generates a C function called yylex().
     Each rule is a PATTERN → ACTION pair.
     The longest matching pattern wins (Flex rule).
     Keywords are listed BEFORE identifiers so "int" matches
     KEYWORD, not IDENTIFIER.
   ============================================================= */

%{
#include "../parser/parser.tab.h"  /* token types from Bison */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Line number tracking — Flex provides yylineno automatically */
/* We use it for error messages: "Lexical Error at line N"       */

/* Token printing flag — set by main.c */
extern int print_tokens;

/* Helper: print a token with its line number and value */
void print_token(const char* type, const char* value) {
    if (print_tokens) {
        printf("  [Line %3d]  %-20s  %s\n", yylineno, type, value);
    }
}
%}

/* Tell Flex to track line numbers automatically */
%option noyywrap
%option yylineno
%option nounput
%option noinput

/* ----------------------------------------------------------------
   DEFINITIONS (named patterns for reuse below)
   These are just shorthand names — makes the rules easier to read.
   ---------------------------------------------------------------- */
DIGIT       [0-9]
LETTER      [a-zA-Z_]
ALNUM       [a-zA-Z0-9_]
INT_LIT     {DIGIT}+
FLOAT_LIT   {DIGIT}+"."{DIGIT}+
IDENT       {LETTER}{ALNUM}*
WHITESPACE  [ \t\r]+
NEWLINE     \n

%%

 /* ----------------------------------------------------------------
   SECTION 1: KEYWORDS
   Must come BEFORE the identifier rule so "int" is a keyword,
   not an identifier. Flex always picks the FIRST matching rule
   when two patterns match the same length.
   ---------------------------------------------------------------- */
"int"       { print_token("KEYWORD", "int");   return T_INT;   }
"float"     { print_token("KEYWORD", "float"); return T_FLOAT; }
"bool"      { print_token("KEYWORD", "bool");  return T_BOOL;  }
"if"        { print_token("KEYWORD", "if");    return T_IF;    }
"else"      { print_token("KEYWORD", "else");  return T_ELSE;  }
"while"     { print_token("KEYWORD", "while"); return T_WHILE; }
"print"     { print_token("KEYWORD", "print"); return T_PRINT; }
"true"      { print_token("BOOL_LIT", "true");
              yylval.bval = 1; return T_BOOL_LIT; }
"false"     { print_token("BOOL_LIT", "false");
              yylval.bval = 0; return T_BOOL_LIT; }

 /* ----------------------------------------------------------------
   SECTION 2: IDENTIFIERS
   Matches any name starting with a letter or underscore.
   yylval.sval stores the name for the parser to use.
   ---------------------------------------------------------------- */
{IDENT}     {
                print_token("IDENTIFIER", yytext);
                yylval.sval = strdup(yytext);
                return T_IDENT;
            }

 /* ----------------------------------------------------------------
   SECTION 3: NUMERIC LITERALS
   Float pattern must come BEFORE integer to match "3.14" fully.
   ---------------------------------------------------------------- */
{FLOAT_LIT} {
                print_token("FLOAT_LIT", yytext);
                yylval.fval = atof(yytext);
                return T_FLOAT_LIT;
            }

{INT_LIT}   {
                print_token("INT_LIT", yytext);
                yylval.ival = atoi(yytext);
                return T_INT_LIT;
            }

 /* ----------------------------------------------------------------
   SECTION 4: OPERATORS
   Each operator returns a unique token type.
   ---------------------------------------------------------------- */
"+"         { print_token("OPERATOR", "+");  return T_PLUS;   }
"-"         { print_token("OPERATOR", "-");  return T_MINUS;  }
"*"         { print_token("OPERATOR", "*");  return T_STAR;   }
"/"         { print_token("OPERATOR", "/");  return T_SLASH;  }
"%"         { print_token("OPERATOR", "%");  return T_PERCENT;}
"<="        { print_token("OPERATOR", "<="); return T_LE;     }
">="        { print_token("OPERATOR", ">="); return T_GE;     }
"=="        { print_token("OPERATOR", "=="); return T_EQ;     }
"!="        { print_token("OPERATOR", "!="); return T_NEQ;    }
"<"         { print_token("OPERATOR", "<");  return T_LT;     }
">"         { print_token("OPERATOR", ">");  return T_GT;     }
"&&"        { print_token("OPERATOR", "&&"); return T_AND;    }
"||"        { print_token("OPERATOR", "||"); return T_OR;     }
"!"         { print_token("OPERATOR", "!");  return T_NOT;    }
"="         { print_token("ASSIGN", "=");    return T_ASSIGN; }

 /* ----------------------------------------------------------------
   SECTION 5: DELIMITERS
   ---------------------------------------------------------------- */
"{"         { print_token("LBRACE", "{");  return T_LBRACE; }
"}"         { print_token("RBRACE", "}");  return T_RBRACE; }
"("         { print_token("LPAREN", "(");  return T_LPAREN; }
")"         { print_token("RPAREN", ")");  return T_RPAREN; }
";"         { print_token("SEMICOLON", ";"); return T_SEMI; }

 /* ----------------------------------------------------------------
   SECTION 6: COMMENTS (silently discard — do not tokenize)
   Single-line: // ...
   Block:       [slash]* ... *[slash]
   ---------------------------------------------------------------- */
"//"[^\n]*          { /* single-line comment — ignore */ }
"/*"([^*]|\*+[^*/])*\*+"/"  { /* block comment — ignore */ }

 /* ----------------------------------------------------------------
   SECTION 7: WHITESPACE (silently discard)
   ---------------------------------------------------------------- */
{WHITESPACE}    { /* skip spaces and tabs */ }
{NEWLINE}       { /* skip newlines — yylineno handles counting */ }

 /* ----------------------------------------------------------------
   SECTION 8: INVALID TOKENS
   Anything that did not match any of the above patterns is an
   illegal character. Report it with its line number and continue.
   ---------------------------------------------------------------- */
.           {
                fprintf(stderr, "Lexical Error [Line %d]: Invalid token '%s'\n",
                        yylineno, yytext);
            }

%%
