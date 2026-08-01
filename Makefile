# =============================================================
# Makefile  —  Build System for the Mini Compiler
# Course:  Compiler Construction Lab
# Team:    Razibit and The Tokenizers
#
# HOW IT WORKS (explain to teacher):
#   "make" runs all build steps automatically.
#   Step 1: flex converts lexer.l  → lex.yy.c
#   Step 2: bison converts parser.y → parser.tab.c + parser.tab.h
#   Step 3: gcc compiles all .c files into one executable: ./compiler
#
# USAGE:
#   make          → build the compiler
#   make clean    → remove all generated files
#   make run      → build and run on the sample program
# =============================================================

# Compiler and flags
CC      = gcc
CFLAGS  = -Wall -g

# Output executable name
TARGET  = compiler

# Source directories
LEXER_DIR  = src/lexer
PARSER_DIR = src/parser
SRC_DIR    = src

# Generated file names
LEX_C      = $(LEXER_DIR)/lex.yy.c
PARSER_C   = $(PARSER_DIR)/parser.tab.c
PARSER_H   = $(PARSER_DIR)/parser.tab.h

# Source files to compile
SOURCES    = $(LEX_C) $(PARSER_C) $(SRC_DIR)/main.c

# Default target: build the compiler
all: $(TARGET)

# Step 1: Run Flex to generate the lexer C file from lexer.l
$(LEX_C): $(LEXER_DIR)/lexer.l $(PARSER_H)
	flex -o $(LEX_C) $(LEXER_DIR)/lexer.l

# Step 2: Run Bison to generate the parser C file and header from parser.y
# -d flag generates the .tab.h header file (needed by the lexer)
$(PARSER_C) $(PARSER_H): $(PARSER_DIR)/parser.y
	bison -d -o $(PARSER_C) $(PARSER_DIR)/parser.y

# Step 3: Compile everything together into one executable
$(TARGET): $(SOURCES)
	$(CC) $(CFLAGS) -I$(PARSER_DIR) $(SOURCES) -o $(TARGET) -lfl

# ---------------------------------------------------------------
# Convenience targets
# ---------------------------------------------------------------

# Run the compiler on the sample valid program
run: $(TARGET)
	./$(TARGET) examples/valid/sample.mc

# Run on an invalid program (to test error detection)
run-invalid: $(TARGET)
	./$(TARGET) examples/invalid/sample.mc

# Remove all generated and compiled files
clean:
	rm -f $(LEX_C) $(PARSER_C) $(PARSER_H) $(TARGET)
	rm -f $(PARSER_DIR)/parser.tab.c $(PARSER_DIR)/parser.tab.h

# Show this help message
help:
	@echo "Mini Compiler — Razibit and The Tokenizers"
	@echo ""
	@echo "  make          Build the compiler"
	@echo "  make run      Build and run on examples/valid/sample.mc"
	@echo "  make run-invalid  Build and run on examples/invalid/sample.mc"
	@echo "  make clean    Remove all generated files"
	@echo ""
	@echo "  Usage: ./compiler <source_file.mc>"

.PHONY: all clean run run-invalid help

# Non-functional note: this comment does not change build behavior.
