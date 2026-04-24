export const RESET = "\x1b[0m";

export const CATPPUCCIN = {
  rosewater: "38;2;242;213;207",
  flamingo: "38;2;238;190;190",
  pink: "38;2;244;184;228",
  mauve: "38;2;202;158;230",
  red: "38;2;231;130;132",
  maroon: "38;2;234;153;156",
  peach: "38;2;239;159;118",
  yellow: "38;2;229;200;144",
  green: "38;2;166;209;137",
  teal: "38;2;129;200;190",
  sky: "38;2;153;209;219",
  sapphire: "38;2;133;193;220",
  blue: "38;2;140;170;238",
  lavender: "38;2;186;187;241",
  text: "38;2;198;208;245",
  subtext1: "38;2;181;191;226",
  subtext0: "38;2;165;173;206",
  overlay2: "38;2;148;156;187",
  overlay1: "38;2;131;139;167",
  overlay0: "38;2;115;121;148",
  surface2: "38;2;98;104;128",
  surface1: "38;2;81;87;109",
  surface0: "38;2;65;69;89",
  base: "38;2;48;52;70",
  mantle: "38;2;41;44;60",
  crust: "38;2;35;38;52",
} as const;

export function fg(code: string, text: string): string {
  return `\x1b[${code}m${text}${RESET}`;
}
