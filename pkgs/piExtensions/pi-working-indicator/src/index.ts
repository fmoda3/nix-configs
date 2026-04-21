import type { ExtensionAPI, ExtensionContext, WorkingIndicatorOptions } from "@mariozechner/pi-coding-agent";
import { SPINNER_VERBS } from "./verbs";

const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"] as const;
const SHIMMER_INTERVAL_MS = 90;
const ANSI_RESET = "\x1b[0m";
const FRAPPE_TONES = [
  "\x1b[38;2;140;170;238m", // blue
  "\x1b[38;2;133;193;220m", // sapphire
  "\x1b[38;2;153;209;219m", // sky
  "\x1b[38;2;129;200;190m", // teal
] as const;

type NonEmptyArray<T> = readonly [T, ...T[]];

type IndicatorSpec = Readonly<{
  word: string;
  indicator: WorkingIndicatorOptions;
}>;

const VERBS = [...SPINNER_VERBS] as NonEmptyArray<string>;

function randomIndex(length: number): number {
  return Math.floor(Math.random() * length);
}

function chooseVerb(verbs: NonEmptyArray<string>): string {
  return verbs[randomIndex(verbs.length)]!;
}

function gcd(a: number, b: number): number {
  return b === 0 ? a : gcd(b, a % b);
}

function lcm(a: number, b: number): number {
  return (a * b) / gcd(a, b);
}

function colorize(text: string, ansiColor: string): string {
  return `${ansiColor}${text}${ANSI_RESET}`;
}

function shimmerWord(word: string, shimmerFrame: number): string {
  const characters = Array.from(word);
  const toneCount = FRAPPE_TONES.length;

  return characters
    .map((character, index) => {
      if (character.trim().length === 0) return character;

      const distance = Math.abs(index - shimmerFrame);
      const toneIndex = Math.min(distance, toneCount - 1);
      const color = FRAPPE_TONES[toneCount - 1 - toneIndex]!;
      return colorize(character, color);
    })
    .join("");
}

function buildIndicator(word: string): WorkingIndicatorOptions {
  const shimmerFrames = Math.max(Array.from(word).filter((character) => character.trim().length > 0).length, 1);
  const frameCount = lcm(SPINNER_FRAMES.length, shimmerFrames);
  const frames = Array.from({ length: frameCount }, (_, frameIndex) => {
    const spinner = SPINNER_FRAMES[frameIndex % SPINNER_FRAMES.length]!;
    const shimmerFrame = frameIndex % shimmerFrames;
    return `${colorize(spinner, FRAPPE_TONES[0])} ${shimmerWord(word, shimmerFrame)}`;
  });

  return {
    frames,
    intervalMs: SHIMMER_INTERVAL_MS,
  };
}

function createIndicatorSpec(): IndicatorSpec {
  const word = `${chooseVerb(VERBS)}...`;
  return {
    word,
    indicator: buildIndicator(word),
  };
}

export default function (pi: ExtensionAPI) {
  let current = createIndicatorSpec();

  const applyIndicator = (ctx: ExtensionContext) => {
    ctx.ui.setWorkingIndicator(current.indicator);
    ctx.ui.setWorkingMessage("\u200B");
  };

  pi.on("session_start", async (_event, ctx) => {
    current = createIndicatorSpec();
    applyIndicator(ctx);
  });

  pi.on("agent_start", async (_event, ctx) => {
    current = createIndicatorSpec();
    applyIndicator(ctx);
  });
}
