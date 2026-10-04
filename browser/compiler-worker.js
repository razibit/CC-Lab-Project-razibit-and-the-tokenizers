/* One new worker per compilation resets C globals and releases WASM memory. */
importScripts('./compiler.js');

self.onmessage = async ({ data: { code } }) => {
  const stdout = [], stderr = [];
  let bytes = 0;
  const capture = (lines) => (line) => {
    bytes += new TextEncoder().encode(line).length + 1;
    if (bytes > 1024 * 1024) throw new Error('Compiler output exceeded the 1 MiB limit.');
    lines.push(line);
  };
  try {
    const module = await createMiniCompiler({
      noInitialRun: true,
      print: capture(stdout),
      printErr: capture(stderr),
      locateFile: (file) => new URL(file, self.location.href).href
    });
    module.FS.writeFile('/input.mc', code);
    let exitCode = 0;
    try {
      exitCode = module.callMain(['/input.mc']);
    } catch (error) {
      if (typeof error.status === 'number') exitCode = error.status;
      else throw error;
    }
    self.postMessage({ stdout: stdout.join('\n'), stderr: stderr.join('\n'), exitCode });
  } catch (error) {
    self.postMessage({ error: error.message || 'The browser compiler could not run.' });
  }
};
