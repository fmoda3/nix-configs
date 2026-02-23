---
description: Check for package updates
---

# Check Package Updates

Check all custom Nix packages in the `pkgs/` directory for available updates.

## Instructions

### Step 1: Discover All Packages

Explore the `pkgs/` directory to find all package definitions. Look for:
- `default.nix` files in subdirectories (including nested ones like `pkgs/category/package/default.nix`)
- Package definitions that specify versions

For each package found, extract:
1. **Package name** (from directory name or pname attribute)
2. **Current version** (from version attribute)
3. **Source information**:
   - For `fetchFromGitHub`: owner, repo, rev/tag
   - For `fetchurl`/`fetchzip`: URL pattern
   - For npm packages: package name from URL
   - For git sources: URL and revision

### Step 2: Categorize Packages

Group packages by source type:
- **GitHub releases** - packages using tags like `v1.2.3`
- **GitHub commits** - packages tracking a branch's HEAD
- **NPM registry** - packages from npmjs.org
- **Internal/private** - skip these (internal company repos, local scripts)
- **Other sources** - JetBrains, binary distributions, etc.

### Step 3: Check Latest Versions

For each package category, use appropriate methods:

**GitHub releases:**
```bash
gh api repos/{owner}/{repo}/releases/latest --jq '.tag_name'
```

**GitHub commits (tracking main/master):**
```bash
gh api repos/{owner}/{repo}/commits/main --jq '.sha'
gh api repos/{owner}/{repo}/commits/main --jq '.commit.committer.date'
```

**NPM packages:**
```bash
npm view {package-name} version
```

**Kotlin LSP** (from JetBrains):
```bash
gh api repos/Kotlin/kotlin-lsp/releases/latest --jq '.tag_name'
```
Note: The version in the nix file should be the tag without the `kotlin-lsp/v` prefix (e.g., tag `kotlin-lsp/v261.13587.0` → version `261.13587.0`)

### Step 4: Compare and Report

Create a summary table with columns:
| Package | Current | Latest | Status |

Status should be one of:
- **Up to date** - versions match
- **Outdated** - newer version available (show both versions)
- **Could not verify** - unable to check upstream
- **N/A** - internal/local packages

### Step 5: Provide Update Recommendations

For any outdated packages:
1. List the file path that needs updating
2. Show the specific attributes to change (version, rev, hash)
3. Note if hash updates are needed (fetchFromGitHub sources require new hash)

Offer to update the outdated packages if any are found.

## Notes

- Skip packages from internal/private repositories (e.g., `github.toasttab.com`, internal artifactory)
- Skip local shell script wrappers with no upstream
- For commit-based packages, compare both SHA and date
- When checking npm packages, use the exact package name from the source URL

$ARGUMENTS
