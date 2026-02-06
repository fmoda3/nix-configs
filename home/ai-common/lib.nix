{ lib }:
let
  inherit (lib) optionalString optionalAttrs;
  inherit (builtins) readFile;

  # Get body content from either body attribute or bodyFile
  getBody = item:
    if item ? body && item.body != null then item.body
    else if item ? bodyFile && item.bodyFile != null then readFile item.bodyFile
    else "";

  # Get rule text from source or text attribute
  getRuleText = rule:
    if rule ? source then readFile rule.source
    else rule.text or "";

  # Concatenate all rules into a single text block
  rulesToText = rules:
    lib.concatStringsSep "\n\n" (lib.attrValues (builtins.mapAttrs (name: getRuleText) rules));

  # Get memory text from source or text attribute
  getMemoryText = memory:
    if memory ? source then readFile memory.source
    else memory.text or "";

  # Helper to check if an entry is a command (has description) or a namespace (contains commands)
  isCommand = entry: entry ? description;

  # ============ Agent Markdown Generators ============

  # claude-code: name, description, color, model, tools
  toClaudeCodeAgentMarkdown = agent: ''
    ---
    name: ${agent.name}
    description: ${agent.description}
    ${optionalString (agent ? color) "color: ${agent.color}"}
    ${optionalString (agent ? model) "model: ${agent.model}"}
    ${optionalString (agent ? tools) "tools: ${agent.tools}"}
    ${optionalString (agent ? disallowedTools) "disallowedTools: ${agent.disallowedTools}"}
    ${optionalString (agent ? permissionMode) "permissionMode: ${agent.permissionMode}"}
    ${optionalString (agent ? skills) "skills: ${agent.skills}"}
    ---

    ${getBody agent}
  '';

  # opencode: name, description, model, temperature, maxSteps, tools, permission
  toOpencodeAgentMarkdown = agent: ''
    ---
    description: "${lib.escape ["\"" "\\"] agent.description}"
    ${optionalString (agent ? model) "model: ${agent.model}"}
    ${optionalString (agent ? temperature) "temperature: ${toString agent.temperature}"}
    ${optionalString (agent ? maxSteps) "maxSteps: ${toString agent.maxSteps}"}
    ${optionalString (agent ? disable) "disable: ${toString agent.disable}"}
    ${optionalString (agent ? mode) "mode: ${agent.mode}"}
    ${optionalString (agent ? hidden) "hidden: ${agent.hidden}"}
    ---

    ${getBody agent}
  '';

  # ============ Command Markdown Generator ============

  toClaudeCodeCommandMarkdown = cmd: ''
    ---
    description: ${cmd.description}
    ${optionalString (cmd ? allowed-tools) "allowed-tools: ${cmd.allowed-tools}"}
    ${optionalString (cmd ? argumentHint) "argument-hint: ${cmd.argumentHint}"}
    ${optionalString (cmd ? context) "context: ${cmd.context}"}
    ${optionalString (cmd ? agent) "agent: ${cmd.agent}"}
    ${optionalString (cmd ? model) "model: ${cmd.model}"}
    ${optionalString (cmd ? disable-model-invocation) "disable-model-invocation: ${cmd.disable-model-invocation}"}
    ---

    ${getBody cmd}
  '';

  toOpencodeCommandMarkdown = cmd: ''
    ---
    description: "${lib.escape ["\"" "\\"] cmd.description}"
    ${optionalString (cmd ? agent) "agent: ${cmd.agent}"}
    ${optionalString (cmd ? model) "model: ${cmd.model}"}
    ${optionalString (cmd ? subtask) "subtask: ${cmd.subtask}"}
    ---

    ${getBody cmd}
  '';

  toCodexCommandMarkdown = cmd: ''
    ---
    description: ${cmd.description}
    ${optionalString (cmd ? argumentHint) "argument-hint: ${cmd.argumentHint}"}
    ---

    ${getBody cmd}
  '';

  # ============ Skill Markdown Generator ============

  toClaudeCodeSkillMarkdown = skill: ''
    ---
    name: ${skill.name}
    description: ${skill.description}
    ${optionalString (skill ? allowed-tools) "allowed-tools: ${skill.allowed-tools}"}
    ${optionalString (skill ? model) "model: ${skill.model}"}
    ${optionalString (skill ? context) "context: ${skill.context}"}
    ${optionalString (skill ? agent) "agent: ${skill.agent}"}
    ${optionalString (skill ? user-invocable) "user-invocable: ${skill.user-invocable}"}
    ---

    ${getBody skill}
  '';

  toOpencodeSkillMarkdown = skill: ''
    ---
    name: ${skill.name}
    description: ${skill.description}
    ${optionalString (skill ? license) "license: ${skill.license}"}
    ${optionalString (skill ? compatibility) "compatibility: ${skill.compatibility}"}
    ---

    ${getBody skill}
  '';

  toCodexSkillMarkdown = skill: ''
    ---
    name: ${skill.name}
    description: ${skill.description}
    ---

    ${getBody skill}
  '';

  # claude-code: name, description, color, model, tools
  toClaudeCodeOutputStyleMarkdown = style: ''
    ---
    name: ${style.name}
    description: ${style.description}
    ---

    ${getBody style}
  '';
in
{
  # ============ MCP Servers ============

  # claude-code: type (http/sse) or command/args (stdio)
  toClaudeCodeMcpServers = servers:
    builtins.mapAttrs
      (name: srv:
        if srv.transport == "stdio" then
          { inherit (srv) command; args = srv.args or [ ]; }
          // optionalAttrs (srv ? env) { inherit (srv) env; }
        else
          { type = srv.transport; inherit (srv) url; }
          // optionalAttrs (srv ? env) { inherit (srv) env; }
      )
      servers;

  # opencode: local (command) or remote (url)
  toOpencodeMcp = servers:
    builtins.mapAttrs
      (name: srv:
        if srv.transport == "stdio" || srv.transport == "local" then
          { type = "local"; command = [ srv.command ] ++ (srv.args or [ ]); }
          // optionalAttrs (srv ? env) { environment = srv.env; }
          // optionalAttrs (srv ? timeout) { inherit (srv) timeout; }
        else
          { type = "remote"; inherit (srv) url; }
          // optionalAttrs (srv ? headers) { inherit (srv) headers; }
          // optionalAttrs (srv ? timeout) { inherit (srv) timeout; }
      )
      servers;

  # codex: command/args (stdio) or url (http)
  toCodexMcpServers = servers:
    builtins.mapAttrs
      (name: srv:
        if srv.transport == "stdio" then
          { inherit (srv) command; }
          // optionalAttrs (srv ? args) { inherit (srv) args; }
          // optionalAttrs (srv ? env) { inherit (srv) env; }
        else
          { inherit (srv) url; }
          // optionalAttrs (srv ? headers) { http_headers = srv.headers; }
      )
      servers;

  # ============ Agents ============

  toClaudeCodeAgents = agents: builtins.mapAttrs (n: toClaudeCodeAgentMarkdown) agents;
  toOpencodeAgents = agents: builtins.mapAttrs (n: toOpencodeAgentMarkdown) agents;

  # ============ Commands ============

  # claude-code: supports both top-level commands and namespaced (tasks/create_plan -> "tasks/create_plan")
  toClaudeCodeCommands = commands:
    lib.foldl'
      (acc: name:
        let entry = commands.${name}; in
        if isCommand entry then
        # Top-level command
          acc // { ${name} = toClaudeCodeCommandMarkdown entry; }
        else
        # Namespace containing commands
          acc // lib.mapAttrs'
            (cmdName: cmd: lib.nameValuePair "${name}/${cmdName}" (toClaudeCodeCommandMarkdown cmd))
            entry
      )
      { }
      (lib.attrNames commands);

  # opencode: supports both top-level commands and namespaced (tasks/create_plan -> "tasks_create_plan")
  toOpencodeCommands = commands:
    lib.foldl'
      (acc: name:
        let entry = commands.${name}; in
        if isCommand entry then
        # Top-level command
          acc // { ${name} = toOpencodeCommandMarkdown entry; }
        else
        # Namespace containing commands
          acc // lib.mapAttrs'
            (cmdName: cmd: lib.nameValuePair "${name}_${cmdName}" (toOpencodeCommandMarkdown cmd))
            entry
      )
      { }
      (lib.attrNames commands);

  # codex: supports both top-level commands and namespaced (tasks/create_plan -> "tasks_create_plan")
  toCodexPrompts = commands:
    lib.foldl'
      (acc: name:
        let entry = commands.${name}; in
        if isCommand entry then
        # Top-level command
          acc // { ${name} = toCodexCommandMarkdown entry; }
        else
        # Namespace containing commands
          acc // lib.mapAttrs'
            (cmdName: cmd: lib.nameValuePair "${name}_${cmdName}" (toCodexCommandMarkdown cmd))
            entry
      )
      { }
      (lib.attrNames commands);

  # ============ Skills ============

  toClaudeCodeSkills = skills: builtins.mapAttrs (n: toClaudeCodeSkillMarkdown) skills;
  toOpencodeSkills = skills: builtins.mapAttrs (n: toOpencodeSkillMarkdown) skills;
  toCodexSkills = skills: builtins.mapAttrs (n: toCodexSkillMarkdown) skills;

  # ======== Output Styles =========

  toClaudeCodeOutputStyles = styles: builtins.mapAttrs (n: toClaudeCodeOutputStyleMarkdown) styles;

  # ============ Memory ============

  inherit getMemoryText;

  # ============ Rules ============

  # claude-code: rules as attrset mapping name -> source path
  toClaudeCodeRules = rules:
    builtins.mapAttrs
      (name: rule:
        if rule ? source then { inherit (rule) source; }
        else { text = rule.text or ""; }
      )
      rules;

  # opencode/codex: concatenate memory + rules into single text
  getMemoryWithRules = memory: rules:
    let
      memoryText = getMemoryText memory;
      rulesText = rulesToText rules;
    in
    if rulesText == "" then memoryText
    else if memoryText == "" then rulesText
    else "${memoryText}\n\n${rulesText}";
}
