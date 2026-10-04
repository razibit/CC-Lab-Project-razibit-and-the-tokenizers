"""Build only the browser demo. Requires Flex, Bison and Emscripten 4.0.23."""
import argparse
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bison', default='bison')
    parser.add_argument('--flex', default='flex')
    parser.add_argument('--emcc', default='emcc')
    parser.add_argument('--output', type=Path, default=ROOT / 'build' / 'browser')
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='mini-compiler-') as temporary:
        generated = Path(temporary)
        (generated / 'parser').mkdir()
        (generated / 'lexer').mkdir()
        parser_c = generated / 'parser/parser.tab.c'
        lexer_c = generated / 'lexer/lex.yy.c'
        subprocess.run([args.bison, '-d', '-o', str(parser_c), str(ROOT / 'src/parser/parser.y')], check=True)
        # Target is WASM/POSIX even when WinFlexBison runs on Windows.
        subprocess.run([args.flex, '-o', str(lexer_c), str(ROOT / 'src/lexer/lexer.l')], check=True)
        subprocess.run([
            args.emcc, str(parser_c), str(lexer_c), str(ROOT / 'browser/main.c'),
            '-I' + str(generated / 'parser'), '-O2',
            '-sMODULARIZE=1', '-sEXPORT_NAME=createMiniCompiler',
            '-sEXPORTED_RUNTIME_METHODS=FS,callMain', '-sINVOKE_RUN=0',
            '-sEXIT_RUNTIME=1', '-sENVIRONMENT=worker', '-sALLOW_MEMORY_GROWTH=1',
            '-sMAXIMUM_MEMORY=134217728', '-sSTACK_SIZE=1048576',
            '-o', str(output / 'compiler.js')
        ], check=True)
    html = (ROOT / 'gui/index.html').read_text(encoding='utf-8')
    html = html.replace('<html lang="en">', '<html lang="en" data-compiler-mode="browser">')
    html = html.replace('</head>', '  <link rel="icon" href="./favicon.svg" type="image/svg+xml" />\n'
                        '  <link rel="stylesheet" href="./browser.css" />\n'
                        '  <script src="./browser-runtime.js"></script>\n</head>')
    notice = '''<aside class="browser-notice" aria-label="About this demo">
    <span><strong>Browser demo</strong> · Compile .mc code to Three Address Code. Runs locally in your browser.</span>
    <a href="https://github.com/razibit/CC-Lab-Project-razibit-and-the-tokenizers" target="_blank" rel="noopener noreferrer">Source on GitHub ↗</a>
  </aside>'''
    html = html.replace('<main id="main-layout">', notice + '\n  <main id="main-layout">')
    (output / 'index.html').write_text(html, encoding='utf-8')
    shutil.copy2(ROOT / 'gui/style.css', output / 'style.css')
    for name in ('browser-runtime.js', 'compiler-worker.js', 'browser.css', 'favicon.svg'):
        shutil.copy2(ROOT / 'browser' / name, output / name)
    shutil.copy2(ROOT / 'LICENSE', output / 'LICENSE.txt')
    (output / '.nojekyll').touch()
    print(f'Browser-only site built at {output}')


if __name__ == '__main__':
    main()
