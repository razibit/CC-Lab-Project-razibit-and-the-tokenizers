/* =============================================================
   main.c  —  Compiler Entry Point
   Course:  Compiler Construction Lab
   Team:    Razibit and The Tokenizers
   University: Metropolitan University, Bangladesh

   HOW IT WORKS (explain to teacher):
     main.c is the entry point. It:
       1) Opens the source file given on the command line
       2) Calls yyparse() which runs the Flex+Bison pipeline
       3) After parsing, prints the AST, Symbol Table, and TAC
       4) Reports the total number of errors found

   This file is intentionally kept SHORT and SIMPLE.
   All the compiler logic lives in parser.y.
   main.c is the "start button" that launches the pipeline.
   ============================================================= */

#include <stdio.h>
#include <stdlib.h>

/* ---------------------------------------------------------------
   These are defined in parser.y (Bison generates them).
   We declare them here so main.c can call them.
   --------------------------------------------------------------- */
extern int   yyparse(void);         /* entry point of the parser    */
extern FILE *yyin;                  /* Flex reads tokens from here  */
extern int   print_tokens;          /* 1 = print tokens to stdout   */
extern int   semantic_error_count;  /* counts semantic errors found */

/* The root AST node — set by parser.y after parsing completes */
extern void *ast_root;

/* Functions defined in parser.y that we call after parsing */
extern void enter_scope(void);
extern char *gen_code(void *node);
extern void print_ast(void *node, int depth);
extern void print_symbol_table(void);
extern void print_tac(void);

/* Functions defined in optimizer.c */
extern void run_all_optimizations(void *ast_root);

int main(int argc, char *argv[]) {

    /* ========================================================= */
    /*                 INITIALIZATION PHASE                      */
    /* ========================================================= */

    /* ── Step 1: Require a source file argument ─────────────── */
    if (argc < 2) {
        fprintf(stderr,
            "Usage:   %s <source_file.mc>\n"
            "Example: ./compiler examples/valid/sample.mc\n",
            argv[0]);
        return 1;
    }

    /* ── Step 2: Open the source file ───────────────────────── */
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        fprintf(stderr, "Error: Cannot open file '%s'\n", argv[1]);
        return 1;
    }

    /* ── Step 3: Print banner ───────────────────────────────── */
    printf("============================================================\n");
    printf("  Mini Compiler  —  Razibit and The Tokenizers\n");
    printf("  Metropolitan University, Bangladesh\n");
    printf("  File: %s\n", argv[1]);
    printf("============================================================\n");

    /* ── Step 4: Print the TOKENS section header ────────────── */
    /* The lexer will print each token as it is scanned.        */
    printf("\n==================== TOKENS ====================\n");
    print_tokens = 1;   /* tell the lexer to print tokens */

    /* ── Step 5: Open global scope, then parse ──────────────── */
    /* enter_scope() opens scope 0 (the global scope).          */
    /* yyparse() drives the whole Flex+Bison pipeline:          */
    /*   - yyparse calls yylex (the Flex lexer) to get tokens   */
    /*   - As rules are matched, AST nodes are built            */
    /*   - ast_root is set when the top-level rule is matched   */
    enter_scope();
    int parse_ok = yyparse();
    fclose(yyin);

    /* ── Step 6: Print the AST ──────────────────────────────── */
    printf("\n==================== ABSTRACT SYNTAX TREE ====================\n");
    if (ast_root != NULL) {
        print_ast(ast_root, 0);
        
        /* Run Experimental Optimizer (Feature Flag Enabled) */
        run_all_optimizations(ast_root);
    } else {
        printf("  (no AST — parsing failed)\n");
    }

    /* ── Step 7: Print the Symbol Table ─────────────────────── */
    print_symbol_table();

    /* ── Step 8: Semantic analysis + TAC generation ─────────── */
    /* gen_code() walks the AST:                                 */
    /*   - Checks types and declarations (semantic analysis)     */
    /*   - Emits Three Address Code instructions                 */
    if (parse_ok == 0 && ast_root != NULL) {
        printf("\n  [Performing semantic analysis and TAC generation...]\n");
        gen_code(ast_root);
    }

    /* ── Step 9: Print the TAC output ──────────────────────── */
    print_tac();

    /* ── Step 10: Print compilation summary ─────────────────── */
    printf("\n==================== COMPILATION SUMMARY ====================\n");
    if (parse_ok != 0) {
        printf("  Result:  FAILED\n");
        printf("  Reason:  Syntax errors prevented full compilation.\n");
    } else if (semantic_error_count > 0) {
        printf("  Result:  FAILED\n");
        printf("  Reason:  %d semantic error(s) detected.\n", semantic_error_count);
    } else {
        printf("  Result:  SUCCESS\n");
        printf("  Output:  Three Address Code generated successfully.\n");
    }
    printf("============================================================\n\n");

    /* ========================================================= */
    /*                 TERMINATION PHASE                         */
    /* ========================================================= */

    /* Return 0 = success, 1 = errors */
    return (parse_ok != 0 || semantic_error_count > 0) ? 1 : 0;
}
