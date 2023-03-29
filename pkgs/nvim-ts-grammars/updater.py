#! /usr/bin/env nix-shell
#! nix-shell -i python3
#! nix-shell -p cacert python3 nix nix-prefetch-git

import json, re, os, subprocess
from urllib.request import urlopen

grammars_path = os.path.join(os.getcwd(), "grammars")
nix_prefetch_cmd = ["nix-prefetch-git", "--quiet", "--no-deepClone"]

lockfile_url = "https://raw.githubusercontent.com/nvim-treesitter/nvim-treesitter/63e4a3a40a494e76ef7613f127b31919eebd47d1/lockfile.json"
lockfile_body = urlopen(lockfile_url).read()
lockfile_data = json.loads(lockfile_body.decode("utf-8"))

parsers_url = "https://raw.githubusercontent.com/nvim-treesitter/nvim-treesitter/63e4a3a40a494e76ef7613f127b31919eebd47d1/lua/nvim-treesitter/parsers.lua"
parsers_re = re.compile(r'list.(\w+)\s=.*\s.*\s*url\s=\s([^,]+),',
                        re.MULTILINE)
parsers_body = urlopen(parsers_url).read()
parsers_code = parsers_body.decode("utf-8")

# contains parser name, and repo
parsers_data = parsers_re.findall(parsers_code)

grammars_file_path = os.path.join(grammars_path, "default.nix")
grammars_file = open(grammars_file_path, "w")

grammars_file.write("{\n")

count = len(parsers_data)
for idx, data in enumerate(parsers_data):
    parser_name, parser_repo = data
    parser_repo = parser_repo.lstrip('\"').rstrip('\"')
    parser_rev = lockfile_data[parser_name]['revision']
    parser_file_path = os.path.join(grammars_path,
                                    f"tree-sitter-{parser_name}.json")
    print(f"Updating {parser_name} ({idx+1} of {count})")
    grammars_file.write(f"  tree-sitter-{parser_name} = "
            + "builtins.fromJSON ("
            + f"builtins.readFile ./tree-sitter-{parser_name}.json"
            + ");\n")

    nix_prefetch_args = ["--url", parser_repo, "--rev", parser_rev]
    with open(parser_file_path, "w") as f:
        subprocess.run(nix_prefetch_cmd + nix_prefetch_args, stdout=f)

grammars_file.write("}")
grammars_file.close()
