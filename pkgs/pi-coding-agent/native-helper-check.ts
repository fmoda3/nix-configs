// Loaded by the installed CLI to check its real native-helper discovery path.
// No display connection is opened; only the native module's exports are checked.
import assert from "node:assert/strict";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { getNativeClipboard } from "@earendil-works/pi-tui";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", () => {
    const helper = getNativeClipboard();
    assert.equal(typeof helper?.getText, "function");
    assert.equal(typeof helper?.getImage, "function");
    console.log("PACKAGING_NATIVE_HELPER_OK");
  });
}
