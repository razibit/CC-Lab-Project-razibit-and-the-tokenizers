"""
server.py  —  Flask Web Server (GUI Bonus Feature)
Course:  Compiler Construction Lab
Team:    Razibit and The Tokenizers
University: Metropolitan University, Bangladesh

HOW IT WORKS (explain to teacher):
  This is a tiny Python web server (about 20 lines of real logic).
  When the user clicks "Compile" in the browser:
    1) The browser sends the source code as a POST request to /compile
    2) Flask writes the code to a temporary file
    3) Flask runs our compiler binary (./compiler temp_file)
    4) Flask captures the compiler's output (stdout + stderr)
    5) Flask sends the output back to the browser as JSON
    6) The browser's JavaScript displays it in the tabbed output panel

  This bridge pattern is called a "REST API":
    Browser ──POST /compile──▶ Flask ──subprocess──▶ ./compiler
    Browser ◀──JSON response── Flask ◀──stdout/stderr──
"""

from flask import Flask, request, jsonify, send_from_directory
import os
import platform
import subprocess
import tempfile

MAX_SOURCE_LENGTH = 64 * 1024
MAX_OUTPUT_LENGTH = 1_000_000

# Create the Flask app.
# static_folder='gui' tells Flask to serve files from the gui/ directory.
app = Flask(__name__, static_folder='gui', static_url_path='')
app.config['MAX_CONTENT_LENGTH'] = MAX_SOURCE_LENGTH


@app.route('/')
def index():
    """Serve the main HTML page."""
    return send_from_directory('gui', 'index.html')


def _load_source_code():
    """Extract and validate the source code from the request payload."""
    data = request.get_json(silent=True)

    if not isinstance(data, dict) or 'code' not in data or not isinstance(data['code'], str):
        return None, (jsonify({'error': 'No code provided'}), 400)

    source_code = data['code']
    if len(source_code.encode('utf-8')) > MAX_SOURCE_LENGTH:
        return None, (jsonify({'error': 'Source code exceeds the size limit.'}), 413)

    if '\x00' in source_code:
        return None, (jsonify({'error': 'Null bytes are not allowed.'}), 400)

    return source_code, None


def _build_compile_command(filename: str):
    """Build the subprocess command for the current platform."""
    root_dir = os.path.dirname(os.path.abspath(__file__))
    compiler_path = os.path.join(root_dir, 'compiler')

    # Windows uses the Linux compiler through WSL, while Unix-like systems can run it directly.
    if platform.system() == 'Windows':
        return ['wsl', compiler_path, filename]
    return [compiler_path, filename]


def _collect_error_lines(stdout: str, stderr: str):
    """Collect human-readable error lines from compiler output."""
    error_lines = []
    seen = set()

    for source in (stderr, stdout):
        for line in source.splitlines():
            stripped = line.strip()
            if not stripped:
                continue
            lowered = stripped.lower()
            if 'error' in lowered and stripped not in seen:
                error_lines.append(stripped)
                seen.add(stripped)

    return error_lines


def _cleanup_temp_file(tmp_path):
    """Delete the temporary source file if it still exists."""
    if tmp_path and os.path.exists(tmp_path):
        os.unlink(tmp_path)


@app.route('/compile', methods=['POST'])
def compile_code():
    """
    Receive source code, run the compiler, return structured output.

    Request body (JSON):
        { "code": "int x;\nx = 5;\nprint x;\n" }

    Response (JSON):
        {
            "tokens":       "... token lines ...",
            "ast":          "... AST lines ...",
            "symbol_table": "... symbol table ...",
            "tac":          "... three address code ...",
            "errors":       "... error messages ...",
            "summary":      "SUCCESS / FAILED",
            "success":      true / false
        }
    """
    source_code, error_response = _load_source_code()
    if error_response is not None:
        return error_response

    tmp_path = None
    try:
        root_dir = os.path.dirname(os.path.abspath(__file__))
        with tempfile.NamedTemporaryFile(
            dir=root_dir,
            prefix='compile_',
            suffix='.mc',
            delete=False,
            mode='w',
            encoding='utf-8'
        ) as handle:
            handle.write(source_code)
            tmp_path = handle.name

        filename = os.path.basename(tmp_path)
        cmd = _build_compile_command(filename)

        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=10,
            cwd=root_dir,
            stdin=subprocess.DEVNULL,
            check=False
        )

        stdout = result.stdout
        stderr = result.stderr
        total_output = len(stdout.encode('utf-8')) + len(stderr.encode('utf-8'))
        if total_output > MAX_OUTPUT_LENGTH:
            return jsonify({
                'error': 'Compiler output exceeded the size limit.',
                'success': False
            })

        full_output = stdout + ('\n' + stderr if stderr.strip() else '')
        sections = parse_output_sections(full_output)
        error_lines = _collect_error_lines(stdout, stderr)
        success = result.returncode == 0

        return jsonify({
            'tokens':       sections.get('TOKENS', ''),
            'ast':          sections.get('ABSTRACT SYNTAX TREE', ''),
            'symbol_table': sections.get('SYMBOL TABLE', ''),
            'tac':          sections.get('THREE ADDRESS CODE', ''),
            'summary':      sections.get('COMPILATION SUMMARY', ''),
            'errors':       '\n'.join(error_lines),
            'success':      success,
            'raw':          full_output
        })

    except subprocess.TimeoutExpired:
        return jsonify({
            'error': 'Compilation timed out (possible infinite loop in source code)',
            'success': False
        })
    except FileNotFoundError:
        return jsonify({
            'error': (
                'Compiler binary not found. '
                'Please run "make" first to build the compiler.'
            ),
            'success': False
        })
    finally:
        _cleanup_temp_file(tmp_path)


@app.errorhandler(413)
def request_too_large(_):
    """Return a clear response when the request body is too large."""
    return jsonify({'error': 'Request body is too large.', 'success': False}), 413


def parse_output_sections(output: str) -> dict:
    """
    Split the compiler's stdout into named sections.

    The compiler outputs sections like:
        ==================== TOKENS ====================
        ... content ...
        ==================== AST ====================
        ... content ...

    This function splits on those headers and returns a dict.
    """
    sections = {}
    current_section = None
    current_lines = []

    for line in output.splitlines():
        stripped = line.strip()
        # Check if this line is a section header (matches ==...== TITLE ==...==)
        if stripped.startswith('==') and stripped.endswith('=='):
            # Save previous section
            if current_section:
                sections[current_section] = '\n'.join(current_lines).strip()
            # Start new section — extract the title from between the =='s
            title = stripped.strip('=').strip()
            current_section = title
            current_lines = []
        elif current_section:
            current_lines.append(line)

    # Save last section
    if current_section:
        sections[current_section] = '\n'.join(current_lines).strip()

    return sections


if __name__ == '__main__':
    print("=" * 60)
    print("  Mini Compiler Web GUI — Razibit and The Tokenizers")
    print("  Metropolitan University, Bangladesh")
    print("=" * 60)
    print()
    print("  Starting server at http://localhost:5000")
    print("  Open your browser and go to:  http://localhost:5000")
    print()
    print("  Make sure you have built the compiler first:")
    print("    make")
    print()
    print("  Press Ctrl+C to stop the server.")
    print()

    app.run(host='0.0.0.0', port=5000, debug=False)
