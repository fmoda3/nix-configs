"""Pure Python TeX preprocessing utilities.

Handles \input{} expansion and encoding normalization without external tools.
"""

import re
from pathlib import Path


def expand_inputs(tex_content: str, base_dir: Path, seen: set = None) -> str:
    """Recursively expand \\input{} and \\include{} statements.

    Args:
        tex_content: TeX source content
        base_dir: Directory to resolve relative paths from
        seen: Set of already-processed files (circular reference detection)

    Returns:
        TeX content with all inputs expanded inline
    """
    if seen is None:
        seen = set()

    def replace_input(match):
        filename = match.group(1).strip()
        # \input{foo} -> foo.tex if no extension
        if not filename.endswith(".tex"):
            filename = filename + ".tex"

        filepath = base_dir / filename
        resolved = filepath.resolve()

        if resolved in seen:
            return f"% [CIRCULAR REFERENCE: {filename}]"
        seen.add(resolved)

        if resolved.exists():
            try:
                content = resolved.read_text(encoding="utf-8", errors="replace")
                # Recursively expand from the included file's directory
                return expand_inputs(content, resolved.parent, seen)
            except Exception as e:
                return f"% [READ ERROR: {filename}: {e}]"
        return f"% [MISSING FILE: {filename}]"

    # Match \input{file} and \include{file}, handling whitespace
    pattern = r"\\(?:input|include)\s*\{([^}]+)\}"
    return re.sub(pattern, replace_input, tex_content)


def normalize_encoding(content: str) -> str:
    """Normalize content to valid UTF-8.

    Args:
        content: String content (may have encoding issues)

    Returns:
        Clean UTF-8 string with replacement chars for invalid sequences
    """
    return content.encode("utf-8", errors="replace").decode("utf-8")


def strip_comments(tex_content: str) -> str:
    """Remove TeX comments (lines starting with %).

    Preserves escaped percent signs (\\%).

    Args:
        tex_content: TeX source content

    Returns:
        Content with comments removed
    """
    lines = []
    for line in tex_content.split("\n"):
        # Find first unescaped % and truncate
        result = []
        i = 0
        while i < len(line):
            if line[i] == "%" and (i == 0 or line[i - 1] != "\\"):
                break
            result.append(line[i])
            i += 1
        lines.append("".join(result).rstrip())
    return "\n".join(lines)


def extract_abstract(tex_content: str) -> str:
    """Convert abstract environment to a section pandoc will render.

    Transforms \\begin{abstract}...\\end{abstract} into a proper section.

    Args:
        tex_content: TeX source content

    Returns:
        Content with abstract converted to section
    """
    pattern = r"\\begin\{abstract\}(.*?)\\end\{abstract\}"

    def replace_abstract(m):
        abstract_text = m.group(1).strip()
        return f"\\section*{{Abstract}}\n{abstract_text}"

    return re.sub(pattern, replace_abstract, tex_content, flags=re.DOTALL)


def convert_bold_headers(tex_content: str) -> str:
    """Convert bold-text pseudo-headers to proper subsections.

    Many papers use {\\bf Title} or \\textbf{Title} instead of \\subsubsection{}.
    This detects standalone bold patterns and converts them.

    Heuristic: inline labels typically end with punctuation (period, colon),
    while section headers don't. We only convert non-punctuated bold text.

    Args:
        tex_content: TeX source content

    Returns:
        Content with bold headers converted to subsubsections
    """
    # Pattern: \noindent {\bf Title} or \noindent \textbf{Title}
    # Only convert if the title does NOT end with punctuation (., :, ?)
    # to avoid converting inline definition labels.

    def make_subsubsection(m, title_group=1):
        title = m.group(title_group).strip()
        # Skip if ends with punctuation (inline label, not header)
        if title and title[-1] in ".,:;?!":
            return m.group(0)  # Return unchanged
        return f"\\subsubsection*{{{title}}}"

    # {\bf ...} style with \noindent
    tex_content = re.sub(
        r"\\noindent\s*\{\\bf\s+([^}]+)\}",
        lambda m: make_subsubsection(m, 1),
        tex_content,
    )

    # \textbf{...} style with \noindent
    tex_content = re.sub(
        r"\\noindent\s*\\textbf\{([^}]+)\}",
        lambda m: make_subsubsection(m, 1),
        tex_content,
    )

    # Standalone {\bf ...} at line start (no \noindent)
    tex_content = re.sub(
        r"^(\s*)\{\\bf\s+([^}]+)\}\s*$",
        lambda m: (
            m.group(0)
            if m.group(2).strip()[-1:] in ".,:;?!"
            else f"{m.group(1)}\\subsubsection*{{{m.group(2)}}}"
        ),
        tex_content,
        flags=re.MULTILINE,
    )

    return tex_content


def inline_bibliography(tex_content: str, base_dir: Path) -> str:
    """Inline .bbl bibliography file if available.

    Replaces \\bibliography{...} command with contents of compiled .bbl file.
    This allows pandoc to see the expanded bibliography entries.

    Args:
        tex_content: TeX source content
        base_dir: Directory containing the .bbl file

    Returns:
        Content with bibliography inlined (or unchanged if no .bbl found)
    """
    # Find .bbl files in the directory
    bbl_files = list(base_dir.glob("*.bbl"))
    if not bbl_files:
        return tex_content

    # Use the first .bbl file found
    bbl_path = bbl_files[0]
    try:
        bbl_content = bbl_path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return tex_content

    # Replace \bibliography{...} with the .bbl contents
    # The .bbl file contains \begin{thebibliography}...\end{thebibliography}
    pattern = r"\\bibliography\s*\{[^}]*\}"

    if re.search(pattern, tex_content):
        # Use lambda to avoid backslash interpretation in replacement string
        return re.sub(pattern, lambda _: bbl_content, tex_content)

    # If no \bibliography command but \end{document} exists, insert before it
    if r"\end{document}" in tex_content and bbl_content.strip():
        return tex_content.replace(
            r"\end{document}", f"\n{bbl_content}\n\\end{{document}}"
        )

    return tex_content


def preprocess_tex(main_tex_path: str) -> str:
    """Main preprocessing entry point.

    Reads main .tex file, expands inputs, normalizes encoding,
    and transforms problematic LaTeX patterns for pandoc.

    Args:
        main_tex_path: Path to main .tex file

    Returns:
        Path to preprocessed.tex output file
    """
    path = Path(main_tex_path)
    if not path.exists():
        raise FileNotFoundError(f"Main TeX file not found: {main_tex_path}")

    content = path.read_text(encoding="utf-8", errors="replace")

    # Expand \input{} and \include{} recursively
    expanded = expand_inputs(content, path.parent)

    # Inline .bbl bibliography if available
    with_bib = inline_bibliography(expanded, path.parent)

    # Convert abstract environment to section (pandoc strips it otherwise)
    with_abstract = extract_abstract(with_bib)

    # Convert bold pseudo-headers to proper subsubsections
    with_headers = convert_bold_headers(with_abstract)

    # Normalize to clean UTF-8
    normalized = normalize_encoding(with_headers)

    # Write preprocessed output
    output_path = path.parent / "preprocessed.tex"
    output_path.write_text(normalized, encoding="utf-8")

    return str(output_path)
