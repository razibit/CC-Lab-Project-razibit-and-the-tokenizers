/* =============================================================
   parser.y  —  Bison Grammar + AST + Symbol Table + Semantic + TAC
   Course:  Compiler Construction Lab
   Team:    Razibit and The Tokenizers
   University: Metropolitan University, Bangladesh

   HOW IT WORKS (explain to teacher):
     This single file contains the COMPLETE compiler logic after
     the lexer. Bison reads the grammar rules and generates a
     parser. Inside each grammar rule's action { ... } block,
     we:
       1) Build an AST node
       2) Check semantics (types, declarations, scopes)
       3) Generate Three Address Code (TAC)
   All 4 compiler phases live here, making it easy to trace
   exactly what happens at each point in parsing.
   ============================================================= */

%{
/* ---------------------------------------------------------------
   C HEADER SECTION — included at the top of the generated C file
   --------------------------------------------------------------- */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Forward declarations */
int  yylex(void);
void yyerror(const char *msg);
extern int yylineno;     /* line number from Flex */
extern FILE *yyin;       /* input file pointer    */
extern char *yytext;     /* current token text from Flex */

/* ---------------------------------------------------------------
   FLAGS — controlled by main.c
   --------------------------------------------------------------- */
int print_tokens = 1;    /* 1 = print tokens as they are scanned */

/* ================================================================
   PART A: AST (Abstract Syntax Tree)
   ================================================================

   HOW TO EXPLAIN:
     "The AST is a tree. Each node is one C struct. The parser
     builds the tree bottom-up as it recognizes grammar rules.
     Each internal node has up to 3 child pointers. Leaf nodes
     hold values (numbers, variable names). We print it with
     indentation — one level per tree depth."

   ================================================================ */

/* All possible types of AST nodes */
typedef enum {
    NODE_PROGRAM,    /* root: entire program         */
    NODE_STMT_LIST,  /* list of statements            */
    NODE_DECL,       /* variable declaration: int x; */
    NODE_ASSIGN,     /* assignment: x = expr;        */
    NODE_IF,         /* if statement                  */
    NODE_IF_ELSE,    /* if-else statement             */
    NODE_WHILE,      /* while loop                    */
    NODE_PRINT,      /* print x;                      */
    NODE_BLOCK,      /* { statement_list }            */
    NODE_BINOP,      /* binary operation: a + b       */
    NODE_UNOP,       /* unary operation: !a           */
    NODE_IDENT,      /* identifier: variable name     */
    NODE_INT_LIT,    /* integer literal: 42           */
    NODE_FLOAT_LIT,  /* float literal: 3.14           */
    NODE_BOOL_LIT    /* boolean literal: true/false   */
} NodeType;

/* Data types used in the language */
typedef enum {
    TYPE_INT,
    TYPE_FLOAT,
    TYPE_BOOL,
    TYPE_UNKNOWN,
    TYPE_VOID
} DataType;

/* The AST node structure.
   Every node in the tree is one of these.
   Children form the tree structure. */
typedef struct ASTNode {
    NodeType     type;        /* what kind of node is this?          */
    DataType     data_type;   /* inferred type (set by semantic pass) */
    char         op[8];       /* operator string (for BINOP/UNOP)    */
    char        *name;        /* identifier name or type keyword      */
    int          ival;        /* integer value (for INT_LIT)          */
    double       fval;        /* float value (for FLOAT_LIT)          */
    int          bval;        /* boolean value (for BOOL_LIT)         */
    int          line;        /* source line number (for errors)      */
    struct ASTNode *child[3]; /* up to 3 children                    */
} ASTNode;

/* Helper: create a new AST node, zero-initialized */
ASTNode* make_node(NodeType type, int line) {
    ASTNode *n = (ASTNode*) calloc(1, sizeof(ASTNode));
    n->type      = type;
    n->line      = line;
    n->data_type = TYPE_UNKNOWN;
    return n;
}

/* Convert DataType enum to a readable string */
const char* type_name(DataType t) {
    switch (t) {
        case TYPE_INT:   return "int";
        case TYPE_FLOAT: return "float";
        case TYPE_BOOL:  return "bool";
        default:         return "unknown";
    }
}

/* ================================================================
   AST PRINTER — print_ast(node, depth)
   Prints the tree with indentation (2 spaces per depth level).
   HOW TO EXPLAIN:
     "We call print_ast on the root. It prints itself, then
     recursively calls print_ast on each child. The depth
     parameter adds spaces for indentation."
   ================================================================ */
void print_ast(ASTNode *node, int depth) {
    if (!node) return;

    /* Print indentation */
    for (int i = 0; i < depth; i++) printf("  ");

    /* Print this node's description */
    switch (node->type) {
        case NODE_PROGRAM:
            printf("Program\n");
            break;
        case NODE_STMT_LIST:
            printf("StatementList\n");
            break;
        case NODE_DECL:
            printf("Declare [%s %s] at line %d\n",
                   node->name, node->child[0] ? node->child[0]->name : "?", node->line);
            return; /* leaf-ish: no sub-children to recurse */
        case NODE_ASSIGN:
            printf("Assign [%s =] at line %d\n", node->name, node->line);
            break;
        case NODE_IF:
            printf("If at line %d\n", node->line);
            for (int i = 0; i < depth+1; i++) printf("  ");
            printf("Condition:\n");
            print_ast(node->child[0], depth + 2);
            for (int i = 0; i < depth+1; i++) printf("  ");
            printf("Then:\n");
            print_ast(node->child[1], depth + 2);
            return;
        case NODE_IF_ELSE:
            printf("IfElse at line %d\n", node->line);
            for (int i = 0; i < depth+1; i++) printf("  ");
            printf("Condition:\n");
            print_ast(node->child[0], depth + 2);
            for (int i = 0; i < depth+1; i++) printf("  ");
            printf("Then:\n");
            print_ast(node->child[1], depth + 2);
            for (int i = 0; i < depth+1; i++) printf("  ");
            printf("Else:\n");
            print_ast(node->child[2], depth + 2);
            return;
        case NODE_WHILE:
            printf("While at line %d\n", node->line);
            for (int i = 0; i < depth+1; i++) printf("  ");
            printf("Condition:\n");
            print_ast(node->child[0], depth + 2);
            for (int i = 0; i < depth+1; i++) printf("  ");
            printf("Body:\n");
            print_ast(node->child[1], depth + 2);
            return;
        case NODE_PRINT:
            printf("Print [%s] at line %d\n", node->name, node->line);
            return;
        case NODE_BLOCK:
            printf("Block\n");
            break;
        case NODE_BINOP:
            printf("BinaryOp [%s] (type: %s)\n", node->op, type_name(node->data_type));
            break;
        case NODE_UNOP:
            printf("UnaryOp [%s]\n", node->op);
            break;
        case NODE_IDENT:
            printf("Identifier [%s] (type: %s)\n", node->name, type_name(node->data_type));
            return;
        case NODE_INT_LIT:
            printf("IntLiteral [%d]\n", node->ival);
            return;
        case NODE_FLOAT_LIT:
            printf("FloatLiteral [%.4f]\n", node->fval);
            return;
        case NODE_BOOL_LIT:
            printf("BoolLiteral [%s]\n", node->bval ? "true" : "false");
            return;
        default:
            printf("UnknownNode\n");
            return;
    }

    /* Recurse into children */
    for (int i = 0; i < 3; i++) {
        print_ast(node->child[i], depth + 1);
    }
}

/* ================================================================
   PART B: SYMBOL TABLE
   ================================================================

   HOW TO EXPLAIN:
     "The symbol table is a stack of scopes.
      Think of it as a stack of notebooks.
      When we enter a { block }, we push a new notebook.
      When we exit the } block, we throw the notebook away.
      Every variable we declare gets written into the current
      (top) notebook. When we look up a variable, we search
      from the newest notebook to the oldest."

   IMPLEMENTATION:
     - MAX_SCOPES  = max nesting depth
     - MAX_SYMBOLS = max vars per scope
     - Each scope is an array of SymbolEntry structs
     - scope_top = index of current scope (starts at 0)
   ================================================================ */

#define MAX_SCOPES  64    /* max nesting depth                */
#define MAX_SYMBOLS 256   /* max variables per scope          */

/* One entry in the symbol table */
typedef struct {
    char     name[64];   /* variable name                    */
    DataType type;       /* int, float, or bool              */
    int      line;       /* line where it was declared       */
    int      used;       /* 1 if the variable has been used  */
} SymbolEntry;

/* One scope = an array of SymbolEntry */
typedef struct {
    SymbolEntry entries[MAX_SYMBOLS];
    int         count;    /* how many entries in this scope   */
} Scope;

/* The stack of scopes */
Scope scope_stack[MAX_SCOPES];
int   scope_top = -1;   /* -1 means no scope is open        */

/* Has any semantic error occurred? */
int semantic_error_count = 0;

/* ---- Symbol Table Operations --------------------------------- */

/* Push a new empty scope onto the stack */
void enter_scope() {
    scope_top++;
    if (scope_top >= MAX_SCOPES) {
        fprintf(stderr, "Internal Error: scope nesting too deep.\n");
        exit(1);
    }
    scope_stack[scope_top].count = 0;
}

/* Pop the current scope off the stack */
void exit_scope() {
    if (scope_top < 0) {
        fprintf(stderr, "Internal Error: scope underflow.\n");
        return;
    }
    scope_top--;
}

/* Declare a variable in the CURRENT scope.
   Returns 0 on success, -1 if already declared in this scope. */
int declare_var(const char *name, DataType type, int line) {
    Scope *current = &scope_stack[scope_top];

    /* Check for redeclaration in the SAME scope */
    for (int i = 0; i < current->count; i++) {
        if (strcmp(current->entries[i].name, name) == 0) {
            fprintf(stderr,
                "Semantic Error [Line %d]: Variable '%s' already declared "
                "in this scope (first declared at line %d).\n",
                line, name, current->entries[i].line);
            semantic_error_count++;
            return -1;
        }
    }

    /* Add to current scope */
    if (current->count >= MAX_SYMBOLS) {
        fprintf(stderr, "Internal Error: too many variables in scope.\n");
        return -1;
    }
    strncpy(current->entries[current->count].name, name, 63);
    current->entries[current->count].type = type;
    current->entries[current->count].line = line;
    current->entries[current->count].used = 0;
    current->count++;
    return 0;
}

/* Look up a variable — search from current scope OUTWARD.
   Returns the SymbolEntry pointer, or NULL if not found. */
SymbolEntry* lookup_var(const char *name) {
    /* Search from top (innermost) to bottom (outermost) */
    for (int s = scope_top; s >= 0; s--) {
        for (int i = 0; i < scope_stack[s].count; i++) {
            if (strcmp(scope_stack[s].entries[i].name, name) == 0) {
                scope_stack[s].entries[i].used = 1;
                return &scope_stack[s].entries[i];
            }
        }
    }
    return NULL;  /* not found */
}

/* Print the entire symbol table (all scopes) */
void print_symbol_table() {
    printf("\n==================== SYMBOL TABLE ====================\n");
    if (scope_top < 0) {
        printf("  (empty)\n");
        return;
    }
    for (int s = 0; s <= scope_top; s++) {
        printf("  Scope %d:\n", s);
        if (scope_stack[s].count == 0) {
            printf("    (no variables)\n");
        }
        for (int i = 0; i < scope_stack[s].count; i++) {
            printf("    %-20s | %-6s | declared at line %d\n",
                   scope_stack[s].entries[i].name,
                   type_name(scope_stack[s].entries[i].type),
                   scope_stack[s].entries[i].line);
        }
    }
}

/* ================================================================
   PART C: THREE ADDRESS CODE (TAC) GENERATOR
   ================================================================

   HOW TO EXPLAIN:
     "Three Address Code (TAC) is the final output of our compiler.
      Each instruction does exactly ONE simple operation:
        - Assignment: x = 5
        - Binary op:  t1 = a + b
        - Conditional jump: if_false t1 goto L0
        - Unconditional jump: goto L0
        - Label: L0:
        - Print: print x

      We store all TAC instructions in a list (array of strings)
      and print them at the end.

      Temporary variables are named t1, t2, t3, ...
      Labels are named L0, L1, L2, ..."

   ================================================================ */

#define MAX_TAC_LINES 4096
#define MAX_LINE_LEN  256

char  tac_code[MAX_TAC_LINES][MAX_LINE_LEN];
int   tac_count = 0;   /* how many TAC instructions so far */
int   temp_count = 0;  /* counter for temp variables: t1, t2, ... */
int   label_count = 0; /* counter for labels: L0, L1, ...         */

/* Add one line of TAC */
void emit(const char *line) {
    if (tac_count < MAX_TAC_LINES) {
        strncpy(tac_code[tac_count++], line, MAX_LINE_LEN - 1);
    }
}

/* Generate a new unique temp variable name: t1, t2, ... */
char* new_temp() {
    static char buf[16];
    snprintf(buf, sizeof(buf), "t%d", ++temp_count);
    return buf;
}

/* Generate a new unique label name: L0, L1, ... */
char* new_label() {
    static char buf[16];
    snprintf(buf, sizeof(buf), "L%d", label_count++);
    return buf;
}

/* Print all collected TAC instructions */
void print_tac() {
    printf("\n==================== THREE ADDRESS CODE ====================\n");
    if (tac_count == 0) {
        printf("  (no code generated)\n");
        return;
    }
    for (int i = 0; i < tac_count; i++) {
        printf("%s\n", tac_code[i]);
    }
}

/* ================================================================
   PART D: SEMANTIC ANALYSIS + TAC GENERATION (one combined pass)
   ================================================================

   HOW TO EXPLAIN:
     "We have one function: gen_code(node, result_var).
      It walks the AST recursively.
      For each node type, it:
        1) Checks semantics (types, declarations)
        2) Generates TAC instructions
        3) Returns the variable name holding the result
           (so the parent node can use it)"
   ================================================================ */

/* Forward declaration (gen_code calls itself recursively) */
char* gen_code(ASTNode *node);

/* Helper: parse type string to DataType enum */
DataType str_to_type(const char *s) {
    if (strcmp(s, "int")   == 0) return TYPE_INT;
    if (strcmp(s, "float") == 0) return TYPE_FLOAT;
    if (strcmp(s, "bool")  == 0) return TYPE_BOOL;
    return TYPE_UNKNOWN;
}

/* Helper: determine result type of binary operation */
DataType binop_result_type(DataType left, DataType right, const char *op) {
    /* Relational operators always return bool */
    if (strcmp(op,"<")==0 || strcmp(op,">")==0 ||
        strcmp(op,"<=")==0 || strcmp(op,">=")==0 ||
        strcmp(op,"==")==0 || strcmp(op,"!=")==0) {
        return TYPE_BOOL;
    }
    /* Logical operators need bool operands, return bool */
    if (strcmp(op,"&&")==0 || strcmp(op,"||")==0) {
        if (left == TYPE_BOOL && right == TYPE_BOOL) return TYPE_BOOL;
        return TYPE_UNKNOWN; /* error — handled elsewhere */
    }
    /* Arithmetic operators */
    if (left == TYPE_FLOAT || right == TYPE_FLOAT) return TYPE_FLOAT;
    if (left == TYPE_INT   && right == TYPE_INT)   return TYPE_INT;
    return TYPE_UNKNOWN;
}

/* Check if two types are compatible for assignment */
int types_compatible(DataType target, DataType value) {
    if (target == value) return 1;
    /* int = float or float = int is a mismatch in our strict language */
    return 0;
}

/* ----------------------------------------------------------------
   gen_code — the combined semantic + TAC pass.
   Takes an AST node, returns the name of the variable/temp
   that holds the result (or NULL for statements).
   ---------------------------------------------------------------- */
char* gen_code(ASTNode *node) {
    if (!node) return NULL;

    char buf[MAX_LINE_LEN];
    char *left_var, *right_var;
    char *t, *Lstart, *Lend;
    SymbolEntry *entry;

    switch (node->type) {

    /* ----------------------------------------------------------
       PROGRAM and STATEMENT LIST: just recurse into children
       ---------------------------------------------------------- */
    case NODE_PROGRAM:
    case NODE_STMT_LIST:
    case NODE_BLOCK:
        gen_code(node->child[0]);
        gen_code(node->child[1]);
        gen_code(node->child[2]);
        return NULL;

    /* ----------------------------------------------------------
       DECLARATION:  int x;
       - Declare in symbol table
       - No TAC needed (declaration alone allocates no code)
       ---------------------------------------------------------- */
    case NODE_DECL: {
        DataType dtype = str_to_type(node->name);
        /* node->name = type string ("int","float","bool")
           node->child[0]->name = variable name */
        const char *varname = node->child[0] ? node->child[0]->name : "";
        declare_var(varname, dtype, node->line);
        /* Emit a comment in TAC so it's visible */
        snprintf(buf, sizeof(buf), "  ; declare %s %s", node->name, varname);
        emit(buf);
        return NULL;
    }

    /* ----------------------------------------------------------
       ASSIGNMENT:  x = expr;
       1) Generate code for the right-hand expression
       2) Check that the variable exists
       3) Check that types match
       4) Emit:  x = <rhs_var>
       ---------------------------------------------------------- */
    case NODE_ASSIGN: {
        right_var = gen_code(node->child[0]);  /* evaluate rhs */
        entry = lookup_var(node->name);
        if (!entry) {
            fprintf(stderr,
                "Semantic Error [Line %d]: Variable '%s' used before declaration.\n",
                node->line, node->name);
            semantic_error_count++;
            return NULL;
        }
        /* Type check */
        DataType rhs_type = node->child[0] ? node->child[0]->data_type : TYPE_UNKNOWN;
        if (!types_compatible(entry->type, rhs_type)) {
            fprintf(stderr,
                "Semantic Error [Line %d]: Type mismatch — cannot assign %s to %s variable '%s'.\n",
                node->line, type_name(rhs_type), type_name(entry->type), node->name);
            semantic_error_count++;
        }
        if (right_var) {
            snprintf(buf, sizeof(buf), "  %s = %s", node->name, right_var);
            emit(buf);
        }
        return NULL;
    }

    /* ----------------------------------------------------------
       IF statement:  if (cond) { body }
       TAC pattern:
           <cond code>
           if_false <cond_var> goto Lend
           <body code>
         Lend:
       ---------------------------------------------------------- */
    case NODE_IF: {
        left_var = gen_code(node->child[0]);  /* condition */
        Lend = strdup(new_label());

        snprintf(buf, sizeof(buf), "  if_false %s goto %s", left_var, Lend);
        emit(buf);

        enter_scope();
        gen_code(node->child[1]);  /* then-body */
        exit_scope();

        snprintf(buf, sizeof(buf), "%s:", Lend);
        emit(buf);
        free(Lend);
        return NULL;
    }

    /* ----------------------------------------------------------
       IF-ELSE statement:  if (cond) { then } else { else }
       TAC pattern:
           <cond code>
           if_false <cond_var> goto Lelse
           <then code>
           goto Lend
         Lelse:
           <else code>
         Lend:
       ---------------------------------------------------------- */
    case NODE_IF_ELSE: {
        left_var = gen_code(node->child[0]);  /* condition */
        char *Lelse = strdup(new_label());
        Lend        = strdup(new_label());

        snprintf(buf, sizeof(buf), "  if_false %s goto %s", left_var, Lelse);
        emit(buf);

        enter_scope();
        gen_code(node->child[1]);  /* then-body */
        exit_scope();

        snprintf(buf, sizeof(buf), "  goto %s", Lend);
        emit(buf);
        snprintf(buf, sizeof(buf), "%s:", Lelse);
        emit(buf);

        enter_scope();
        gen_code(node->child[2]);  /* else-body */
        exit_scope();

        snprintf(buf, sizeof(buf), "%s:", Lend);
        emit(buf);
        free(Lelse);
        free(Lend);
        return NULL;
    }

    /* ----------------------------------------------------------
       WHILE loop:  while (cond) { body }
       TAC pattern:
         Lstart:
           <cond code>
           if_false <cond_var> goto Lend
           <body code>
           goto Lstart
         Lend:
       ---------------------------------------------------------- */
    case NODE_WHILE: {
        Lstart = strdup(new_label());
        Lend   = strdup(new_label());

        snprintf(buf, sizeof(buf), "%s:", Lstart);
        emit(buf);

        left_var = gen_code(node->child[0]);  /* condition */

        snprintf(buf, sizeof(buf), "  if_false %s goto %s", left_var, Lend);
        emit(buf);

        enter_scope();
        gen_code(node->child[1]);  /* loop body */
        exit_scope();

        snprintf(buf, sizeof(buf), "  goto %s", Lstart);
        emit(buf);
        snprintf(buf, sizeof(buf), "%s:", Lend);
        emit(buf);
        free(Lstart);
        free(Lend);
        return NULL;
    }

    /* ----------------------------------------------------------
       PRINT statement:  print x;
       TAC: print x
       ---------------------------------------------------------- */
    case NODE_PRINT: {
        entry = lookup_var(node->name);
        if (!entry) {
            fprintf(stderr,
                "Semantic Error [Line %d]: Variable '%s' used before declaration.\n",
                node->line, node->name);
            semantic_error_count++;
        }
        snprintf(buf, sizeof(buf), "  print %s", node->name);
        emit(buf);
        return NULL;
    }

    /* ----------------------------------------------------------
       BINARY OPERATION:  left OP right
       1) Generate code for left and right
       2) Check types
       3) Create a temp variable
       4) Emit: t1 = left OP right
       ---------------------------------------------------------- */
    case NODE_BINOP: {
        left_var  = gen_code(node->child[0]);
        right_var = gen_code(node->child[1]);

        DataType lt = node->child[0] ? node->child[0]->data_type : TYPE_UNKNOWN;
        DataType rt = node->child[1] ? node->child[1]->data_type : TYPE_UNKNOWN;
        DataType result_type = binop_result_type(lt, rt, node->op);

        /* Check logical operators: operands must be bool */
        if ((strcmp(node->op,"&&")==0 || strcmp(node->op,"||")==0)) {
            if (lt != TYPE_BOOL || rt != TYPE_BOOL) {
                fprintf(stderr,
                    "Semantic Error [Line %d]: Logical operator '%s' requires bool operands.\n",
                    node->line, node->op);
                semantic_error_count++;
            }
        }

        node->data_type = result_type;

        t = strdup(new_temp());
        snprintf(buf, sizeof(buf), "  %s = %s %s %s", t, left_var, node->op, right_var);
        emit(buf);
        return t;
    }

    /* ----------------------------------------------------------
       UNARY OPERATION:  !expr
       ---------------------------------------------------------- */
    case NODE_UNOP: {
        left_var = gen_code(node->child[0]);
        DataType lt = node->child[0] ? node->child[0]->data_type : TYPE_UNKNOWN;
        if (strcmp(node->op, "!") == 0 && lt != TYPE_BOOL) {
            fprintf(stderr,
                "Semantic Error [Line %d]: '!' operator requires a bool operand.\n",
                node->line);
            semantic_error_count++;
        }
        node->data_type = TYPE_BOOL;
        t = strdup(new_temp());
        snprintf(buf, sizeof(buf), "  %s = !%s", t, left_var);
        emit(buf);
        return t;
    }

    /* ----------------------------------------------------------
       IDENTIFIER:  just look it up, return its name
       ---------------------------------------------------------- */
    case NODE_IDENT: {
        entry = lookup_var(node->name);
        if (!entry) {
            fprintf(stderr,
                "Semantic Error [Line %d]: Variable '%s' used before declaration.\n",
                node->line, node->name);
            semantic_error_count++;
            node->data_type = TYPE_UNKNOWN;
        } else {
            node->data_type = entry->type;
        }
        return node->name;
    }

    /* ----------------------------------------------------------
       LITERALS: return their string representation
       ---------------------------------------------------------- */
    case NODE_INT_LIT: {
        node->data_type = TYPE_INT;
        static char ibuf[32];
        snprintf(ibuf, sizeof(ibuf), "%d", node->ival);
        return ibuf;
    }

    case NODE_FLOAT_LIT: {
        node->data_type = TYPE_FLOAT;
        static char fbuf[32];
        snprintf(fbuf, sizeof(fbuf), "%.4f", node->fval);
        return fbuf;
    }

    case NODE_BOOL_LIT: {
        node->data_type = TYPE_BOOL;
        return node->bval ? "true" : "false";
    }

    default:
        return NULL;
    }
}

/* ================================================================
   The root AST node — set by the grammar's top-level rule
   ================================================================ */
ASTNode *ast_root = NULL;

%}

/* ================================================================
   BISON DECLARATIONS
   ================================================================ */

%code requires {
    typedef struct ASTNode ASTNode;
}

/* Tell Bison what types yylval can hold */
%union {
    int      ival;    /* integer literal value   */
    double   fval;    /* float literal value     */
    int      bval;    /* boolean literal value   */
    char    *sval;    /* string (identifier name)*/
    ASTNode *node;    /* AST node pointer        */
}

/* Token types — must match what lexer.l returns */
%token <sval>  T_IDENT
%token <ival>  T_INT_LIT
%token <fval>  T_FLOAT_LIT
%token <bval>  T_BOOL_LIT
%token T_INT T_FLOAT T_BOOL
%token T_IF T_ELSE T_WHILE T_PRINT
%token T_ASSIGN
%token T_PLUS T_MINUS T_STAR T_SLASH T_PERCENT
%token T_LT T_GT T_LE T_GE T_EQ T_NEQ
%token T_AND T_OR T_NOT
%token T_LBRACE T_RBRACE T_LPAREN T_RPAREN T_SEMI

/* Grammar rules return AST nodes */
%type <node> program stmt_list stmt decl assign if_stmt
%type <node> while_stmt print_stmt block expr type_spec

/* Operator precedence (low to high — bottom = lowest) */
%left  T_OR
%left  T_AND
%left  T_EQ T_NEQ
%left  T_LT T_GT T_LE T_GE
%left  T_PLUS T_MINUS
%left  T_STAR T_SLASH T_PERCENT
%right T_NOT
%right UMINUS

/* Start symbol */
%start program

%%

/* ================================================================
   GRAMMAR RULES
   ================================================================

   Each rule has:
     left_side : right_side_tokens  { action code }

   The action code (in { }) runs when this rule is matched.
   It builds an AST node and stores it in $$ (the result).
   $1, $2, $3 refer to the matched tokens/rules' values.

   ================================================================ */

/* The entire program is a list of statements */
program
    : stmt_list
        {
            ASTNode *root = make_node(NODE_PROGRAM, 1);
            root->child[0] = $1;
            ast_root = root;
            $$ = root;
        }
    ;

/* A statement list is zero or more statements */
stmt_list
    : /* empty */
        { $$ = NULL; }
    | stmt_list stmt
        {
            /* Chain statements: left child = previous list,
               right child = new statement */
            ASTNode *n = make_node(NODE_STMT_LIST, yylineno);
            n->child[0] = $1;
            n->child[1] = $2;
            $$ = n;
        }
    ;

/* A statement is one of: decl, assign, if, while, print, or block */
stmt
    : decl      { $$ = $1; }
    | assign    { $$ = $1; }
    | if_stmt   { $$ = $1; }
    | while_stmt{ $$ = $1; }
    | print_stmt{ $$ = $1; }
    | block     { $$ = $1; }
    | error T_SEMI
        {
            /* Error recovery: skip to next semicolon */
            fprintf(stderr,
                "Syntax Error [Line %d]: Unexpected token. Skipping to ';'.\n",
                yylineno);
            $$ = NULL;
        }
    ;

/* Variable declaration:  int x; */
decl
    : type_spec T_IDENT T_SEMI
        {
            ASTNode *n = make_node(NODE_DECL, yylineno);
            n->name = $1->name;          /* type name: "int","float","bool" */
            n->child[0] = make_node(NODE_IDENT, yylineno);
            n->child[0]->name = $2;      /* variable name */
            $$ = n;
        }
    ;

/* Type keywords */
type_spec
    : T_INT
        {
            ASTNode *n = make_node(NODE_IDENT, yylineno);
            n->name = strdup("int");
            $$ = n;
        }
    | T_FLOAT
        {
            ASTNode *n = make_node(NODE_IDENT, yylineno);
            n->name = strdup("float");
            $$ = n;
        }
    | T_BOOL
        {
            ASTNode *n = make_node(NODE_IDENT, yylineno);
            n->name = strdup("bool");
            $$ = n;
        }
    ;

/* Assignment:  x = expr; */
assign
    : T_IDENT T_ASSIGN expr T_SEMI
        {
            ASTNode *n = make_node(NODE_ASSIGN, yylineno);
            n->name = $1;        /* variable name */
            n->child[0] = $3;   /* rhs expression */
            $$ = n;
        }
    ;

/* If statement (with and without else) */
if_stmt
    : T_IF T_LPAREN expr T_RPAREN block
        {
            ASTNode *n = make_node(NODE_IF, yylineno);
            n->child[0] = $3;   /* condition */
            n->child[1] = $5;   /* then-body */
            $$ = n;
        }
    | T_IF T_LPAREN expr T_RPAREN block T_ELSE block
        {
            ASTNode *n = make_node(NODE_IF_ELSE, yylineno);
            n->child[0] = $3;   /* condition */
            n->child[1] = $5;   /* then-body */
            n->child[2] = $7;   /* else-body */
            $$ = n;
        }
    ;

/* While loop */
while_stmt
    : T_WHILE T_LPAREN expr T_RPAREN block
        {
            ASTNode *n = make_node(NODE_WHILE, yylineno);
            n->child[0] = $3;   /* condition */
            n->child[1] = $5;   /* body      */
            $$ = n;
        }
    ;

/* Print statement */
print_stmt
    : T_PRINT T_IDENT T_SEMI
        {
            ASTNode *n = make_node(NODE_PRINT, yylineno);
            n->name = $2;
            $$ = n;
        }
    ;

/* A block is { statement_list } */
block
    : T_LBRACE stmt_list T_RBRACE
        {
            ASTNode *n = make_node(NODE_BLOCK, yylineno);
            n->child[0] = $2;
            $$ = n;
        }
    ;

/* Expressions (recursive) — operator precedence handled by %left/%right above */
expr
    : expr T_PLUS   expr { ASTNode *n=make_node(NODE_BINOP,yylineno); strcpy(n->op,"+");  n->child[0]=$1; n->child[1]=$3; $$=n; }
    | expr T_MINUS  expr { ASTNode *n=make_node(NODE_BINOP,yylineno); strcpy(n->op,"-");  n->child[0]=$1; n->child[1]=$3; $$=n; }
    | expr T_STAR   expr { ASTNode *n=make_node(NODE_BINOP,yylineno); strcpy(n->op,"*");  n->child[0]=$1; n->child[1]=$3; $$=n; }
    | expr T_SLASH  expr { ASTNode *n=make_node(NODE_BINOP,yylineno); strcpy(n->op,"/");  n->child[0]=$1; n->child[1]=$3; $$=n; }
    | expr T_PERCENT expr{ ASTNode *n=make_node(NODE_BINOP,yylineno); strcpy(n->op,"%");  n->child[0]=$1; n->child[1]=$3; $$=n; }
    | expr T_LT     expr { ASTNode *n=make_node(NODE_BINOP,yylineno); strcpy(n->op,"<");  n->child[0]=$1; n->child[1]=$3; $$=n; }
    | expr T_GT     expr { ASTNode *n=make_node(NODE_BINOP,yylineno); strcpy(n->op,">");  n->child[0]=$1; n->child[1]=$3; $$=n; }
    | expr T_LE     expr { ASTNode *n=make_node(NODE_BINOP,yylineno); strcpy(n->op,"<="); n->child[0]=$1; n->child[1]=$3; $$=n; }
    | expr T_GE     expr { ASTNode *n=make_node(NODE_BINOP,yylineno); strcpy(n->op,">="); n->child[0]=$1; n->child[1]=$3; $$=n; }
    | expr T_EQ     expr { ASTNode *n=make_node(NODE_BINOP,yylineno); strcpy(n->op,"=="); n->child[0]=$1; n->child[1]=$3; $$=n; }
    | expr T_NEQ    expr { ASTNode *n=make_node(NODE_BINOP,yylineno); strcpy(n->op,"!="); n->child[0]=$1; n->child[1]=$3; $$=n; }
    | expr T_AND    expr { ASTNode *n=make_node(NODE_BINOP,yylineno); strcpy(n->op,"&&"); n->child[0]=$1; n->child[1]=$3; $$=n; }
    | expr T_OR     expr { ASTNode *n=make_node(NODE_BINOP,yylineno); strcpy(n->op,"||"); n->child[0]=$1; n->child[1]=$3; $$=n; }
    | T_NOT expr         { ASTNode *n=make_node(NODE_UNOP, yylineno); strcpy(n->op,"!");  n->child[0]=$2;                 $$=n; }
    | T_MINUS expr %prec UMINUS
                         { ASTNode *n=make_node(NODE_UNOP, yylineno); strcpy(n->op,"-");  n->child[0]=$2;                 $$=n; }
    | T_LPAREN expr T_RPAREN { $$ = $2; }
    | T_IDENT
        {
            ASTNode *n = make_node(NODE_IDENT, yylineno);
            n->name = $1;
            $$ = n;
        }
    | T_INT_LIT
        {
            ASTNode *n = make_node(NODE_INT_LIT, yylineno);
            n->ival = $1;
            $$ = n;
        }
    | T_FLOAT_LIT
        {
            ASTNode *n = make_node(NODE_FLOAT_LIT, yylineno);
            n->fval = $1;
            $$ = n;
        }
    | T_BOOL_LIT
        {
            ASTNode *n = make_node(NODE_BOOL_LIT, yylineno);
            n->bval = $1;
            $$ = n;
        }
    ;

%%

/* ================================================================
   ERROR FUNCTION — called by Bison when a syntax error occurs
   ================================================================ */
void yyerror(const char *msg) {
    fprintf(stderr, "Syntax Error [Line %d]: %s near '%s'\n",
            yylineno, msg, yytext);
}
