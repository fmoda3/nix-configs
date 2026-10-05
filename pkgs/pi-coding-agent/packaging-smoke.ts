// Copied into dist/bun/ and compiled with the CLI's explicit worker entrypoints.
// This executable is only used during installCheck; it is not installed.
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { Worker } from "node:worker_threads";
import { CodemodeSandbox, loadQuickJSWasm } from "@earendil-works/pi-codemode";
import quickjsWasmPath from "quickjs-wasi/quickjs.wasm";
import { getCodemodeWorkerSpecifier, getQuickJSWasmPath, setEmbeddedQuickJSWasmPath } from "../config.js";
import type { ResizedImage } from "../utils/image-resize.js";

// Start the worker directly: resizeImage() would silently fall back to in-process
// resizing if the compiled worker were missing, hiding a packaging regression.
const worker = new Worker("./src/utils/image-resize-worker.ts");
try {
  const result = await new Promise<{ result?: ResizedImage | null; error?: string }>((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error("Image worker timed out")), 30_000);
    const finish = (callback: () => void) => {
      clearTimeout(timeout);
      callback();
    };
    worker.once("message", (message) => finish(() => resolve(message)));
    worker.once("error", (error) => finish(() => reject(error)));
    worker.once("exit", (code) => finish(() => reject(new Error(`Image worker exited: ${code}`))));
    worker.postMessage({
      inputBytes: new Uint8Array(readFileSync(join(process.env.PI_PACKAGE_DIR!, "assets", "clankolas.png"))),
      mimeType: "image/png",
      options: { maxWidth: 1, maxHeight: 1 },
    });
  });
  assert.equal(result.error, undefined);
  assert.ok(result.result, "Photon WASM did not load or resize the fixture");
  assert.equal(result.result.width, 1);
  assert.equal(result.result.height, 1);
  assert.equal(result.result.wasResized, true);
} finally {
  await worker.terminate();
}

setEmbeddedQuickJSWasmPath(quickjsWasmPath);
const sandbox = new CodemodeSandbox({
  wasm: loadQuickJSWasm(getQuickJSWasmPath()),
  workerUrl: getCodemodeWorkerSpecifier(),
  timeoutMs: 30_000,
});
try {
  const result = await sandbox.execute("return 6 * 7;");
  assert.ok(result.ok, JSON.stringify(result));
  assert.equal(result.value, 42);
} finally {
  await sandbox.close();
}
console.log("Image worker/Photon WASM and codemode worker/QuickJS WASM passed");
