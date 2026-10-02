import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { registerAutoRouter } from "./src/auto-router.ts";

export default function (pi: ExtensionAPI) {
  registerAutoRouter(pi);
}
