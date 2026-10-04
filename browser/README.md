# Browser-only Mini Compiler demo

This is the project's actual Flex/Bison/C compiler compiled to WebAssembly, with
the existing terminal interface. Visitors edit a `.mc` program and press **COMPILE**
(or Ctrl/Command+Enter) to inspect tokens, the AST, global symbols, TAC and errors.
There is no Flask process, API, database, account or server-side compiler in the
published site. Source code stays in the browser. Compilation produces textual
Three Address Code; this demo does not execute that code or produce machine code.

## Local build and preview

Install Flex, Bison and [Emscripten 4.0.23](https://emscripten.org/docs/getting_started/downloads.html),
then activate the SDK for the current shell. From the repository root:

```sh
python tools/build_browser.py
python -m http.server 3212 --bind 127.0.0.1 --directory build/browser
```

Open `http://127.0.0.1:3212/`. Use an HTTP server rather than opening `index.html`
as a local file: Web Workers and the WebAssembly fetch need an HTTP origin.

The build script supports explicit tool paths (`--flex`, `--bison`, `--emcc`)
and an output directory (`--output`). On Windows, WinFlexBison is supported.
Build tools are required only to build the site, not to use the published demo.

## GitHub Pages

Expected URL:

https://razibit.github.io/CC-Lab-Project-razibit-and-the-tokenizers/

The prepared `.github/workflows/browser-pages.yml` builds and deploys **only
`build/browser`**, not the entire repository or the Flask application. All asset
and worker URLs are relative, so this project subpath works without a custom
domain or changes to the account's main portfolio site.

The repository owner must make the prepared files available in the repository,
choose **Settings → Pages → Source → GitHub Actions**, and run the workflow from
the intended publishing ref. It supports manual dispatch, plus automatic rebuilds
when relevant files change on the repository's existing default branch `main`.
No branch creation is required by the build script. Committing, pushing, changing
Pages settings and dispatching the workflow are separate owner-controlled actions.

## Runtime and behavior

- A fresh Web Worker and WASM instance per compile reset global C state and release
  memory after each request. Input has a 64 KiB UTF-8 limit; compiler output has a
  1 MiB limit; the worker is terminated after 10 seconds; WASM memory is capped
  at 128 MiB. Expensive or invalid input does not run on the UI thread.
- The lexer and parser sources are unchanged. `browser/main.c` prints the AST and
  global symbol table **after** semantic analysis, making inferred types and
  declared variables visible. Local scopes are discarded by the original compiler
  when exited; the displayed table is not a history of every nested scope.
- The original lexer and Bison error recovery can emit errors while returning
  zero. The browser adapter treats error diagnostics as a failed compile as well
  as checking the exit code. It does not present such a compile as successful.
- The browser demo retains the original language rules and limitations. It is
  an educational compiler, not a complete C implementation. It supports `int`,
  `float`, `bool`, declarations, assignment, expressions, block-based `if`/`else`,
  `while` and `print identifier;`.
- The shared GUI still uses `/compile` when served by `server.py`; only the static
  build injects the browser runtime. The build never includes `server.py`.
- Fira Code is loaded from Google Fonts when available. System monospace fonts
  provide a fallback; compiler execution does not depend on that network request.

## Validation

See `output/playwright/browser-demo-validation.md` for local browser checks and
screenshots. Local build/browser checks do not establish that GitHub Pages is
already published.
