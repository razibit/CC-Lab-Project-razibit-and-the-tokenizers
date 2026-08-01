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
import subprocess
import tempfile
import os
import re
import platform

from backend_feature import AnalysisStore, FeatureAnalyzer

# Create the Flask app.
# static_folder='gui' tells Flask to serve files from the gui/ directory.
app = Flask(__name__, static_folder='gui', static_url_path='')

analysis_store = AnalysisStore(max_items=20)
feature_analyzer = FeatureAnalyzer(store=analysis_store)


@app.route('/')
def index():
    """Serve the main HTML page."""
    return send_from_directory('gui', 'index.html')


@app.route('/analyze', methods=['POST'])
def analyze_code():
    """Run the experimental backend analysis feature on source code."""
    data = request.get_json()
    if not data or 'code' not in data:
        return jsonify({'error': 'No code provided'}), 400

    source_code = data['code']
    result = feature_analyzer.analyze(source_code)
    return jsonify({
        'analysis': result,
        'history': analysis_store.history(),
        'feature_enabled': True
    })


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
    data = request.get_json()
    if not data or 'code' not in data:
        return jsonify({'error': 'No code provided'}), 400

    source_code = data['code']

    # Write the source code to a temporary file in the CURRENT directory
    # This makes it easy for WSL to find without complex path translation
    with tempfile.NamedTemporaryFile(
        dir='.', suffix='.mc', delete=False, mode='w', encoding='utf-8'
    ) as f:
        f.write(source_code)
        tmp_path = f.name

    filename = os.path.basename(tmp_path)

    try:
        # If running on Windows, execute the Linux binary via WSL
        if platform.system() == "Windows":
            cmd = ['wsl', './compiler', filename]
        else:
            cmd = ['./compiler', filename]

        # Run the compiler binary
        # timeout=10 prevents infinite loops from hanging the server
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=10
        )

        stdout = result.stdout
        stderr = result.stderr
        full_output = stdout + ('\n' + stderr if stderr.strip() else '')

        # Parse the output into sections
        # Each section is between "=== HEADER ===" markers
        sections = parse_output_sections(full_output)

        # Collect error lines (from stderr + any "Error" lines in stdout)
        error_lines = []
        if stderr.strip():
            error_lines.extend(stderr.strip().splitlines())
        for line in stdout.splitlines():
            if 'Error' in line or 'error' in line:
                if line not in error_lines:
                    error_lines.append(line)

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
        # Always delete the temporary file
        os.unlink(tmp_path)


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
        # Check if this line is a section header (matches ==...== TITLE ==...==)
        if line.startswith('==') and line.strip().endswith('=='):
            # Save previous section
            if current_section:
                sections[current_section] = '\n'.join(current_lines).strip()
            # Start new section — extract title from between the =='s
            title = re.sub(r'=+', '', line).strip()
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
