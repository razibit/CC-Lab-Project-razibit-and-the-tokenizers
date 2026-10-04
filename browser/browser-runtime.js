(() => {
  // Resolve from this script, not from the domain root (GitHub Pages project path).
  const workerUrl = new URL('./compiler-worker.js', document.currentScript.src);
  const headers = {
    TOKENS: 'tokens', 'ABSTRACT SYNTAX TREE': 'ast',
    'SYMBOL TABLE': 'symbol_table', 'THREE ADDRESS CODE': 'tac',
    'COMPILATION SUMMARY': 'summary'
  };
  function parseOutput({ stdout, stderr, exitCode }) {
    const result = { tokens: '', ast: '', symbol_table: '', tac: '', summary: '', errors: stderr };
    let section;
    for (const line of stdout.split('\n')) {
      const heading = line.match(/^=+\s*(.*?)\s*=+$/);
      if (heading) section = headers[heading[1]];
      else if (section) result[section] += line + '\n';
    }
    // The original lexer and recovered syntax errors can return zero; respect diagnostics.
    result.success = exitCode === 0 && !/\b(?:error|failed)\b/i.test(stderr);
    if (!result.success) result.summary = 'Result: FAILED — see Errors for diagnostics.';
    for (const key of Object.values(headers)) result[key] = result[key].trim();
    return result;
  }
  window.MiniCompilerBrowser = {
    compile(code) {
      if (!code.trim()) return Promise.resolve({ error: 'Please enter some code first.' });
      if (code.includes('\0')) return Promise.resolve({ error: 'Source code must not contain null bytes.' });
      if (new TextEncoder().encode(code).length > 64 * 1024)
        return Promise.resolve({ error: 'Source code exceeds the 64 KiB limit.' });
      if (typeof Worker === 'undefined' || typeof WebAssembly === 'undefined')
        return Promise.resolve({ error: 'Use a modern browser with WebAssembly and Web Worker support.' });
      return new Promise((resolve) => {
        let worker, timer;
        const finish = (result) => {
          clearTimeout(timer);
          worker?.terminate();
          resolve(result);
        };
        try {
          worker = new Worker(workerUrl);
          timer = setTimeout(() => finish({ error: 'Compilation exceeded the 10 second limit. Try a smaller program.' }), 10000);
          worker.onmessage = ({ data }) => finish(data.error ? data : parseOutput(data));
          worker.onerror = (event) => {
            event.preventDefault();
            finish({ error: 'Unable to load the browser compiler. Reload the page and try again.' });
          };
          worker.postMessage({ code });
        } catch (error) {
          finish({ error: error.message || 'Unable to start the browser compiler.' });
        }
      });
    }
  };
})();
