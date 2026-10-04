/* Browser entry point. Compiler logic remains in lexer.l and parser.y. */
#include <stdio.h>
#include <stdlib.h>

typedef struct ASTNode ASTNode;
extern int yyparse(void);
extern FILE *yyin;
extern int print_tokens;
extern int semantic_error_count;
extern ASTNode *ast_root;
extern void print_ast(ASTNode *node, int depth);
extern void print_symbol_table(void);
extern void print_tac(void);
extern void enter_scope(void);
extern char *gen_code(ASTNode *node);

int main(int argc, char *argv[]) {
    if (argc != 2 || !(yyin = fopen(argv[1], "r"))) {
        fprintf(stderr, "Error: Unable to read source code.\n");
        return 1;
    }
    printf("==================== TOKENS ====================\n");
    print_tokens = 1;
    enter_scope();
    int parse_result = yyparse();
    fclose(yyin);
    if (parse_result == 0 && ast_root) gen_code(ast_root);

    /* Print after the combined semantic/TAC pass so types and symbols exist. */
    printf("\n==================== ABSTRACT SYNTAX TREE ====================\n");
    if (ast_root) print_ast(ast_root, 0);
    else printf("  (no AST — parsing failed)\n");
    print_symbol_table();
    print_tac();
    printf("\n==================== COMPILATION SUMMARY ====================\n");
    int failed = parse_result != 0 || semantic_error_count > 0;
    printf("  Result: %s\n", failed ? "FAILED" : "SUCCESS");
    if (semantic_error_count > 0)
        printf("  %d semantic error(s) detected.\n", semantic_error_count);
    return failed ? 1 : 0;
}
