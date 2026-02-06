# ast/

Simplified AST module for workflow XML generation.

## Files

| File                   | What                                             | When to read                    |
| ---------------------- | ------------------------------------------------ | ------------------------------- |
| `nodes.py`             | Node types (TextNode, CodeNode, ElementNode)     | Understanding node structure    |
| `builder.py`           | Fluent builder API (W.el())                      | Constructing AST nodes          |
| `renderer.py`          | XMLRenderer and render() function                | Rendering AST to XML output     |
| `dispatch.py`          | Dispatch node types (Subagent, Template, Roster) | Subagent orchestration patterns |
| `dispatch_renderer.py` | Render functions for dispatch nodes              | Rendering dispatch XML          |
| `__init__.py`          | Public API exports                               | Importing AST types             |

## Usage

```python
from skills.lib.workflow.ast import W, render, XMLRenderer, TextNode

# Build step header
doc = W.el("step_header", TextNode("Title"),
           script="myskill", step="1", total="5").build()
output = render(doc, XMLRenderer())

# Build current_action block
action_nodes = [TextNode(a) for a in actions]
doc = W.el("current_action", *action_nodes).build()

# Build invoke_after
doc = W.el("invoke_after", TextNode(next_command)).build()
```

## Node Types

| Type          | Purpose                           |
| ------------- | --------------------------------- |
| `TextNode`    | Plain text content                |
| `CodeNode`    | Code block with optional language |
| `ElementNode` | Generic XML element (via W.el())  |

All specialized nodes (HeaderNode, ActionsNode, etc.) were removed. Skills use
`W.el("tag_name", ...)` for all XML generation.

## Dispatch Node Types

| Type                   | Pattern | Use case                                     |
| ---------------------- | ------- | -------------------------------------------- |
| `SubagentDispatchNode` | Single  | Sequential workflows (plan -> dev -> QR)     |
| `TemplateDispatchNode` | SIMD    | Same template, N targets ($var substitution) |
| `RosterDispatchNode`   | MIMD    | Shared context, unique prompts per agent     |

```python
from skills.lib.workflow.ast import (
    TemplateDispatchNode, render_template_dispatch,
    RosterDispatchNode, render_roster_dispatch,
)

# Template dispatch: $var substituted per-target
node = TemplateDispatchNode(
    agent_type="general-purpose",
    template="Explore $category in $mode mode",
    targets=({"category": "Naming", "mode": "code"}, ...),
    command='python3 -m skills.explore --category $category',
    model="haiku",
)
xml = render_template_dispatch(node)

# Roster dispatch: unique prompts, fixed command
node = RosterDispatchNode(
    agent_type="general-purpose",
    shared_context="Background...",
    agents=("Task 1...", "Task 2...", "Task 3..."),
    command='python3 -m skills.subagent --step 1',
    model="sonnet",
)
xml = render_roster_dispatch(node)
```
