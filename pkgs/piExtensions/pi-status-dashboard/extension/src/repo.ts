import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { basename } from "node:path";
import type { DiffStats, RepoState } from "./types";

function parseNumstat(stdout: string): DiffStats {
  let added = 0;
  let removed = 0;

  for (const line of stdout.split("\n")) {
    if (!line.trim()) continue;
    const [rawAdded, rawRemoved] = line.split("\t");
    if (!rawAdded || !rawRemoved) continue;
    if (rawAdded !== "-") added += Number(rawAdded) || 0;
    if (rawRemoved !== "-") removed += Number(rawRemoved) || 0;
  }

  return { added, removed };
}

async function getGitBranch(pi: ExtensionAPI, cwd: string): Promise<string | null> {
  const result = await pi.exec("git", ["branch", "--show-current"], { cwd, timeout: 5000 });
  if (result.code !== 0) return null;
  const branch = result.stdout.trim();
  return branch.length > 0 ? branch : null;
}

async function getWorktreeName(pi: ExtensionAPI, cwd: string): Promise<string | null> {
  const rootResult = await pi.exec("git", ["rev-parse", "--show-toplevel"], { cwd, timeout: 5000 });
  if (rootResult.code !== 0) return null;

  const repoRoot = rootResult.stdout.trim();
  if (!repoRoot) return null;

  const listResult = await pi.exec("git", ["worktree", "list", "--porcelain"], { cwd, timeout: 5000 });
  if (listResult.code !== 0) return null;

  const worktreePaths = listResult.stdout
    .split("\n")
    .filter((line) => line.startsWith("worktree "))
    .map((line) => line.slice("worktree ".length).trim())
    .filter(Boolean);

  if (worktreePaths.length <= 1) return null;

  const matchedPath = worktreePaths.find((path) => cwd === path || cwd.startsWith(`${path}/`));
  if (!matchedPath) return null;
  if (matchedPath === repoRoot) return null;

  return basename(matchedPath);
}

async function getDiffStats(pi: ExtensionAPI, cwd: string): Promise<DiffStats | null> {
  const headResult = await pi.exec("git", ["rev-parse", "--verify", "HEAD"], { cwd, timeout: 5000 });
  if (headResult.code !== 0) return null;

  const result = await pi.exec("git", ["diff", "--numstat", "HEAD"], { cwd, timeout: 5000 });
  if (result.code !== 0) return null;
  return parseNumstat(result.stdout);
}

export async function loadRepoState(pi: ExtensionAPI, cwd: string): Promise<RepoState> {
  const insideWorkTree = await pi.exec("git", ["rev-parse", "--is-inside-work-tree"], { cwd, timeout: 5000 });
  if (insideWorkTree.code !== 0 || insideWorkTree.stdout.trim() !== "true") {
    return { kind: "no-git" };
  }

  const [branch, worktreeName, diff] = await Promise.all([
    getGitBranch(pi, cwd),
    getWorktreeName(pi, cwd),
    getDiffStats(pi, cwd),
  ]);

  return {
    kind: "git",
    branch,
    worktreeName,
    diff,
  };
}
