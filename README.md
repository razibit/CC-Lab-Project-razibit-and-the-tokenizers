# Mini Programming Language Compiler

**Design and Implement a Mini Programming Language Compiler using Flex and Bison**

Department of Computer Science and Engineering
Metropolitan University, Bangladesh
Compiler Construction Lab — 2026

---

## Team: Razibit and The Tokenizers

| Member | GitHub |
|--------|--------|
| Rajib Dab (231-115-103) | [razibit](https://github.com/razibit) |
| Md Monsur Alam (231-115-104) | [mdmonsuralam](https://github.com/mdmonsuralam) |

---

## Project Overview

This project implements a complete compiler **front-end** for a custom mini programming language. The compiler takes source code as input and produces Three Address Code (TAC) as output, passing it through all required phases:

```
Source Code (.mc)
      │
      ▼
┌─────────────┐
│   LEXER     │  Flex — tokenizes source code
│  (lexer.l)  │
└──────┬──────┘
       │ Token Stream
       ▼
┌─────────────┐
│   PARSER    │  Bison — validates grammar, builds AST
│ (parser.y)  │
└──────┬──────┘
       │ Abstract Syntax Tree
       ▼
┌─────────────┐
│  SYMBOL     │  Scoped stack — tracks variables & types
│   TABLE     │
└──────┬──────┘
       │ Validated AST
       ▼
┌─────────────┐
│  SEMANTIC   │  Type checking, scope validation
│  ANALYZER   │
└──────┬──────┘
       │ Annotated AST
       ▼
┌─────────────┐
│  TAC GEN.   │  Three Address Code generation
└──────┬──────┘
       │
       ▼
Three Address Code Output
```

---

## Quick Start

### Requirements

- WSL (Windows Subsystem for Linux) with Ubuntu, OR Linux
- Flex, Bison, GCC, Make installed

```bash
sudo apt update
sudo apt install build-essential flex bison
```

### Build

```bash
make
```

This runs 3 steps automatically:
1. `flex lexer.l` → generates `lex.yy.c`
2. `bison -d parser.y` → generates `parser.tab.c` + `parser.tab.h`
3. `gcc` links everything into `./compiler`

### Run the Compiler

```bash
./compiler examples/valid/sample.mc
```

### Run the Web GUI (Bonus Feature)

```bash
# Install Flask (one-time)
pip install flask

# Start the web server
python server.py
```

Then open your browser at: **http://localhost:5000**

---

## Project Structure

```
project-root/
├── src/
│   ├── lexer/
│   │   └── lexer.l          ← Flex lexer (tokenizes source)
│   ├── parser/
│   │   └── parser.y         ← Bison parser (grammar + AST + semantic + TAC)
│   └── main.c               ← Entry point
├── gui/
│   ├── index.html           ← Web GUI (terminal-style, dark green)
│   └── style.css            ← Terminal aesthetic stylesheet
├── server.py                ← Flask bridge (~30 lines)
├── docs/
│   └── project_report.md    ← Project report
├── tests/
│   ├── valid/               ← Programs that should compile cleanly
│   └── invalid/             ← Programs that should produce errors
├── examples/
│   ├── valid/sample.mc      ← Demo program (valid)
│   └── invalid/sample.mc    ← Demo program (with errors)
├── Makefile
└── README.md
```

---

## What the Compiler Outputs

Running `./compiler source.mc` prints **5 labeled sections**:

```
==================== TOKENS ====================
  [Line   1]  KEYWORD               int
  [Line   1]  IDENTIFIER            x
  ...

==================== ABSTRACT SYNTAX TREE ====================
Program
  Declare [int x] at line 1
  While at line 4
    Condition:
      BinaryOp [>]
        Identifier [x]
        IntLiteral [0]
    Body:
      ...

==================== SYMBOL TABLE ====================
  Scope 0:
    x            | int    | declared at line 1
    y            | int    | declared at line 2

==================== THREE ADDRESS CODE ====================
  ; declare int x
  x = 10
  y = 0
L0:
  t1 = x > 0
  if_false t1 goto L1
  ...

==================== COMPILATION SUMMARY ====================
  Result: SUCCESS — No errors found.
```

---

## Language Specification

### Data Types
| Type | Description |
|------|-------------|
| `int` | Signed integer |
| `float` | Floating-point number |
| `bool` | Boolean (`true`/`false`) |

### Operators
| Category | Operators |
|----------|-----------|
| Arithmetic | `+  -  *  /  %` |
| Relational | `<  >  <=  >=  ==  !=` |
| Logical | `&&  \|\|  !` |

### Sample Program

```
int x;
int y;
bool flag;

x = 10;
y = 0;
flag = true;

while (x > 0) {
    y = y + x;
    x = x - 1;
}

if (flag == true) {
    print y;
} else {
    print x;
}
```

---

## Test Cases

| Test File | Category | What It Demonstrates |
|-----------|----------|----------------------|
| `tests/valid/test_arithmetic.mc` | Valid | Arithmetic & operator precedence |
| `tests/valid/test_while.mc` | Valid | While loop, scope |
| `tests/valid/test_if_else.mc` | Valid | If-else, booleans |
| `tests/valid/test_nested_scopes.mc` | Valid | Nested scope visibility |
| `tests/invalid/test_lexical_error.mc` | Invalid | Lexical errors (`@`, `#`) |
| `tests/invalid/test_syntax_error.mc` | Invalid | Syntax errors (missing `;`, `)`) |
| `tests/invalid/test_undeclared.mc` | Invalid | Undeclared variable errors |
| `tests/invalid/test_redeclaration.mc` | Invalid | Redeclaration errors |
| `tests/invalid/test_type_mismatch.mc` | Invalid | Type mismatch errors |

Run all tests:

```bash
for f in tests/valid/*.mc;   do echo "--- $f ---"; ./compiler "$f"; done
for f in tests/invalid/*.mc; do echo "--- $f ---"; ./compiler "$f"; done
```

---

## Web GUI (Extra Feature)

The project includes a browser-based GUI with a **Matrix terminal aesthetic** (dark green on black).

Features:
- **Left panel**: Code editor with line numbers, tab support, sample program pre-loaded
- **Right panel**: Tabbed output — Tokens | AST | Symbol Table | TAC | Errors
- **Pipeline diagram**: Animates each compiler stage as it processes
- **Syntax highlighting**: Different colors for keywords, labels, errors, etc.
- **Ctrl+Enter** shortcut to compile

---

## AI Usage

AI tools were used for development assistance per the course AI usage policy (Section 10). Every team member understands every line of submitted code and can explain it during the viva.

---

## Build/Run Troubleshooting

| Problem | Fix |
|---------|-----|
| `flex: command not found` | `sudo apt install flex` |
| `bison: command not found` | `sudo apt install bison` |
| `gcc: command not found` | `sudo apt install build-essential` |
| `Permission denied: ./compiler` | `chmod +x compiler` |
| `flask: module not found` | `pip install flask` |

---

*Submission Deadline: 31 July 2026 — Metropolitan University, Bangladesh*

<!-- Test commit marker - no functional changes -->

Note: This repository update is intentionally non-functional.
