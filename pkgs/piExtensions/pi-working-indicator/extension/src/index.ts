import type {
  ExtensionAPI,
  ExtensionContext,
  ThemeColor,
  WorkingIndicatorOptions,
} from "@earendil-works/pi-coding-agent";
import { SPINNER_VERBS } from "./verbs";

const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"] as const;
const SHIMMER_INTERVAL_MS = 90;
const ANSI_RESET_FG = "\x1b[39m";
const SHIMMER_LIGHTEN_AMOUNTS = [0, 0.12, 0.24, 0.36] as const;

type NonEmptyArray<T> = readonly [T, ...T[]];
type ThinkingLevel = "off" | "minimal" | "low" | "medium" | "high" | "xhigh" | "max";
type Rgb = Readonly<{ r: number; g: number; b: number }>;

const THINKING_COLORS: Readonly<Record<ThinkingLevel, ThemeColor>> = {
  off: "thinkingOff",
  minimal: "thinkingMinimal",
  low: "thinkingLow",
  medium: "thinkingMedium",
  high: "thinkingHigh",
  xhigh: "thinkingXhigh",
  max: "thinkingMax",
};

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
  return `${ansiColor}${text}${ANSI_RESET_FG}`;
}

function parseRgb(ansiColor: string): Rgb | undefined {
  const match = ansiColor.match(/\x1b\[38;2;(\d+);(\d+);(\d+)m/);
  if (!match) return undefined;

  return {
    r: Number(match[1]),
    g: Number(match[2]),
    b: Number(match[3]),
  };
}

function lighten(color: Rgb, amount: number): Rgb {
  const lightenChannel = (channel: number) => Math.round(channel + (255 - channel) * amount);
  return {
    r: lightenChannel(color.r),
    g: lightenChannel(color.g),
    b: lightenChannel(color.b),
  };
}

function toAnsiColor(color: Rgb): string {
  return `\x1b[38;2;${color.r};${color.g};${color.b}m`;
}

function buildShimmerTones(baseAnsiColor: string): NonEmptyArray<string> {
  const baseColor = parseRgb(baseAnsiColor);
  if (!baseColor) return [baseAnsiColor];

  const lighterTones = SHIMMER_LIGHTEN_AMOUNTS.slice(1).map((amount) => toAnsiColor(lighten(baseColor, amount)));
  return [baseAnsiColor, ...lighterTones];
}

function shimmerWord(word: string, shimmerFrame: number, tones: NonEmptyArray<string>): string {
  const characters = Array.from(word);
  const toneCount = tones.length;

  return characters
    .map((character, index) => {
      if (character.trim().length === 0) return character;

      const distance = Math.abs(index - shimmerFrame);
      const toneIndex = Math.min(distance, toneCount - 1);
      const color = tones[toneCount - 1 - toneIndex]!;
      return colorize(character, color);
    })
    .join("");
}

function buildIndicator(word: string, baseAnsiColor: string): WorkingIndicatorOptions {
  const tones = buildShimmerTones(baseAnsiColor);
  const shimmerFrames = Math.max(Array.from(word).filter((character) => character.trim().length > 0).length, 1);
  const frameCount = lcm(SPINNER_FRAMES.length, shimmerFrames);
  const frames = Array.from({ length: frameCount }, (_, frameIndex) => {
    const spinner = SPINNER_FRAMES[frameIndex % SPINNER_FRAMES.length]!;
    const shimmerFrame = frameIndex % shimmerFrames;
    return `${colorize(spinner, baseAnsiColor)} ${shimmerWord(word, shimmerFrame, tones)}`;
  });

  return {
    frames,
    intervalMs: SHIMMER_INTERVAL_MS,
  };
}

function createIndicatorSpec(ctx: ExtensionContext, word = `${chooseVerb(VERBS)}...`): IndicatorSpec {
  const thinkingColor = THINKING_COLORS[ctx.thinkingLevel ?? "off"];
  const baseAnsiColor = ctx.ui.theme.getFgAnsi(thinkingColor);
  return {
    word,
    indicator: buildIndicator(word, baseAnsiColor),
  };
}

export default function (pi: ExtensionAPI) {
  let current: IndicatorSpec | undefined;

  const applyIndicator = (ctx: ExtensionContext, word?: string) => {
    current = createIndicatorSpec(ctx, word);
    ctx.ui.setWorkingIndicator(current.indicator);
    ctx.ui.setWorkingMessage("\u200B");
  };

  pi.on("session_start", async (_event, ctx) => {
    applyIndicator(ctx);
  });

  pi.on("agent_start", async (_event, ctx) => {
    applyIndicator(ctx);
  });

  pi.on("thinking_level_select", async (_event, ctx) => {
    applyIndicator(ctx, current?.word);
  });
}
