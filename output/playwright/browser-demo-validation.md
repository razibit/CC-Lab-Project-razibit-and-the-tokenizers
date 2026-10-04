# Browser demo validation — 2026-10-04

## Result

Built and ran the actual Flex/Bison/C compiler as WebAssembly in headed Chrome.
The static site was served at:

http://127.0.0.1:3212/CC-Lab-Project-razibit-and-the-tokenizers/

Only a Python static HTTP server was running for this demo. Flask and the native
compiler service were not started. The static application made **zero `/compile`
API requests**. The repository subpath matched the intended GitHub Pages path.

## Checks passed

- All nine existing `.mc` fixtures: four valid programs succeeded; five invalid
  programs produced lexical, syntax or semantic error diagnostics as expected.
- Built-in sample generated control-flow TAC. Its inferred AST types and global
  symbols were populated. Tokens, AST, symbols, TAC and errors tabs worked.
- Compile button, Ctrl+Enter, sample loading, clear and empty input handling.
- Failed-to-valid compilation reset errors and variables between fresh workers.
- 64 KiB source limit (including UTF-8 byte counting), null-byte rejection,
  escaped diagnostics for HTML-like invalid code.
- A deliberately nonresponsive worker was terminated after 10 seconds.
- Missing WebAssembly asset produced an actionable error; retry succeeded after
  restoring the asset. Compile controls remained usable.
- Missing browser JS runtime and an unexpected runtime exception produced errors
  without falling back to Flask or making `/compile` requests.
- Desktop 1440×900, tablet 834×1112, mobile 390×844: compiling and tab interactions
  worked; editor/output remained usable; no horizontal document overflow.
- No uncaught page JavaScript exceptions during functional checks.
- Shared Flask GUI's original POST `/compile` JSON contract remained functional
  with a mocked response. This was a contract regression check, not a native
  backend execution test.
- Build script completed with Emscripten 4.0.23 and WinFlexBison 2.5.25. The YAML
  parsed correctly; upload artifact path is exclusively `build/browser`.
- `git diff --check` passed.

## Screenshots

- `mini-compiler-browser-desktop.png`: sample code and generated TAC.
- `mini-compiler-browser-tokens.png`: lexer output.
- `mini-compiler-browser-symbols.png`: populated global symbol table.
- `mini-compiler-browser-errors.png`: type mismatch diagnostic.
- `mini-compiler-browser-tablet.png` and `mini-compiler-browser-mobile.png`.

## Publication status and boundaries

The repository's Pages endpoint returned HTTP 404 during read-only inspection;
this task did not create a public Pages deployment. No Git/GitHub writes were
performed. The existing workspace branch was retained.

The deployment workflow and static ZIP are prepared locally. The workflow uses
the existing default branch `main` for automatic builds and permits manual
dispatch. Selecting the Pages source, making the workflow available on the
appropriate publishing ref and executing deployment remain owner-controlled
Git/GitHub operations under the standing instructions.

The browser entry point prints the AST and global symbols after the existing
combined semantic/TAC pass. Diagnostics also determine failure, because the
original lexer/parser can recover with a zero exit status. Original lexer,
grammar, semantic checks and TAC generation are otherwise unchanged.

This is a compiler demo that generates TAC. It does not execute a submitted
program. Native compiler limitations are preserved, including discarded local
scopes in the displayed table. GitHub-hosted workflow execution and public
browser behavior remain unverified until publication.
