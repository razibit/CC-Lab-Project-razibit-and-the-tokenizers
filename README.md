# Mini Compiler for a Custom Programming Language

A compiler front-end for a small custom language built with Flex, Bison, and C. The project parses source programs, performs basic semantic checks, and produces Three Address Code (TAC) output.

This repository also includes a lightweight web-based GUI for compiling and viewing compiler output in the browser.

---

## Features

- Lexical analysis with Flex
- Parsing and AST construction with Bison
- Symbol table management with lexical scope support
- Semantic checks for declarations, redeclarations, and type issues
- Three Address Code generation
- Browser-based GUI for compilation and result viewing
- Sample valid and invalid programs for demonstration and testing

---

## Technologies Used

- C
- Flex
- Bison
- Python + Flask (for the web server)
- HTML/CSS (for the GUI)
- Make

---

## Installation

### Prerequisites

On Ubuntu or WSL:

```bash
sudo apt update
sudo apt install build-essential flex bison
```

For the web GUI, install Flask:

```bash
pip install flask
```

### Clone the Repository

```bash
git clone <repository-url>
cd CC-Lab-Project-razibit-and-the-tokenizers
```

### Build the Compiler

```bash
make
```

This will generate the compiler binary at:

```bash
./compiler
```

---

## Usage

### Run the Compiler

```bash
./compiler examples/valid/sample.mc
```

The compiler prints:
- Tokens
- Abstract Syntax Tree
- Symbol Table
- Three Address Code
- Compilation Summary

### Run the Web GUI

```bash
python server.py
```

Then open:

```text
http://localhost:5000
```

---

## Example Programs

### Valid Example

```c
int x;
int y;

x = 10;
y = x + 5;

print y;
```

### Invalid Example

```c
int x;

x = true;
```

---

## Screenshots

The GUI includes a terminal-inspired interface with:
- a code editor panel
- tabbed output panels for tokens, AST, symbol table, and TAC
- a pipeline visualization for the compiler stages

![GUI Preview](gui/index.html)

> Replace this placeholder with an actual screenshot image file if you want to include a real image in the repository.

---

## Project Structure

```text
.
├── examples/
│   ├── invalid/
│   └── valid/
├── gui/
│   ├── index.html
│   └── style.css
├── src/
│   ├── lexer/
│   │   └── lexer.l
│   ├── parser/
│   │   └── parser.y
│   └── main.c
├── tests/
│   ├── invalid/
│   └── valid/
├── Makefile
├── README.md
├── server.py
└── LICENSE
```

---

## Testing

You can try the provided sample programs:

```bash
./compiler examples/valid/sample.mc
./compiler examples/invalid/sample.mc
```

---

## Notes

This project is intended for educational and lab purposes and demonstrates the core stages of a compiler front-end.

| `flex: command not found` | `sudo apt install flex` |
| `bison: command not found` | `sudo apt install bison` |
| `gcc: command not found` | `sudo apt install build-essential` |
| `Permission denied: ./compiler` | `chmod +x compiler` |
| `flask: module not found` | `pip install flask` |

---

*Submission Deadline: 31 July 2026 — Metropolitan University, Bangladesh*

<!-- Test commit marker - no functional changes -->

Note: This repository update is intentionally non-functional.
