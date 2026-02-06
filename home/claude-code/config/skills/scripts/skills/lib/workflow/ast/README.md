# AST Module

Type-safe AST representation for workflow output with builder API and pluggable renderers.

## Architecture

```
Skills (26 call sites)
       |
       v
+------------------+
| Builder API      |
| W.header()       |
| W.text_output()  |
+------------------+
       |
       v
+----------------------------------------+
|              AST Nodes                 |
| TextNode | HeaderNode | DispatchNode   |
| CodeNode | ActionsNode | RoutingNode   |
| RawNode  | CommandNode | GuidanceNode  |
| ElementNode | TextOutputNode           |
+----------------------------------------+
       |
       v
+------------------+     +------------------+
| XMLRenderer      |     | PlainTextRenderer|
| (primary)        |     | (future)         |
+------------------+     +------------------+
       |
       v
    str output
```

## Data Flow

```
Skill step handler
       |
       | calls W.header(script="x", step=1, total=5)
       v
ASTBuilder accumulates nodes
       |
       | .build() returns Document
       v
Document(children=[HeaderNode, ActionsNode, ...])
       |
       | render(doc, XMLRenderer())
       v
XMLRenderer.render() matches each node type
       |
       | recursively renders children
       v
"<step_header script='x' step='1' total='5'>...</step_header>"
```

## Why This Structure

### Module Organization

- **nodes.py**: Node definitions isolated from construction logic. Enables importing types without builder dependency.
- **builder.py**: Fluent API separate from types. Builder can evolve (add convenience methods) without changing node structure.
- **renderer.py**: Rendering decoupled from AST. Multiple renderers (XML, plain text, JSON) implement same interface.
- **(deleted) compat.py**: Was transitional shim during migration. Removed after all skills migrated to W.\* builder API.

### Design Choices

**Frozen Dataclasses**: Immutability aligns with FP style, prevents accidental mutation, and enables safe sharing of nodes between renders and caching.

**Flat Union**: Workflow output is sequential composition (Header + Actions + Command), not nested prose. Flat union with `children: list[Node]` matches actual patterns better than layered inline/block distinction.

**Separate Dataclass Per Type**: Type-safe field access with IDE autocomplete. More explicit than shared attrs dict. Standard Python pattern for discriminated unions.

**Builder API**: Direct construction requires knowing field names and types. Builder provides fluent API with autocomplete, reducing cognitive load for skill authors.

**Immutable Builder Pattern**: Each builder method returns NEW builder instance with accumulated node. No mutable state shared between calls. Functional style aligns with user preference for clean FP.

**External render() Function**: Separation of concerns - Document doesn't need to know about renderers. Easier to add new renderers without modifying Document class. Multiple dispatch without coupling nodes to renderer interface.

## Invariants

Core invariants enforced by the AST module:

1. **Node types are frozen dataclasses**: Immutable after construction. No field mutation allowed.
2. **Node = Union of 11 dataclass types**: Discriminated by class type, not field. Match statement provides exhaustiveness.
3. **children is always list[Node], never None**: Empty list for leaf nodes. Simplifies rendering logic.
4. **RawNode.content is never empty**: Use TextNode for intentional empty strings. RawNode is escape hatch for unstructured content.
5. **Renderer must handle all 11 node types**: Match exhaustiveness enforced via assertNever pattern.
6. **Builder methods return NEW builder instances**: Immutable chain. Final .build() returns Document.

## Tradeoffs

### Flat union vs typed children

**Chose**: Flat `children: list[Node]` over `children: list[InlineNode]`.

**Why**: Loses compile-time nesting enforcement but simplifies API. Workflow output is sequential composition, not nested prose. Runtime validation can catch invalid nesting if needed.

### Builder vs direct construction

**Chose**: Builder adds indirection but improves ergonomics.

**Why**: Skill authors use `W.header()` not `HeaderNode(type=NodeType.HEADER, ...)`. Fluent API with autocomplete reduces cognitive load. Direct construction exposes implementation details.

### Compatibility shim vs immediate migration

**Chose**: Shim adds temporary code but enables gradual rollout.

**Why**: Worth the short-term complexity for risk reduction. Strangler Fig pattern isolates risk per-skill. No coordinated deployment required. Big bang rewrite would affect all 26 call sites simultaneously.

## RawNode Escape Hatch

RawNode distinguishes "couldn't structure this" from intentional text (TextNode). Tracking `raw_nodes/total_nodes` ratio identifies when AST needs extension.

**Threshold**: Extend AST if >20% of nodes are RawNode. This signals a design gap where new node types are needed.

## Extending the AST

To add a new node type:

1. Add frozen dataclass to `nodes.py` with typed fields
2. Add to `Node` union type
3. Add builder method to `ASTBuilder` in `builder.py`
4. Add render method to `XMLRenderer` in `renderer.py`
5. Add case to `_render_node()` match statement
6. Update tests to cover new node type for exhaustiveness

The match statement will catch missing cases at runtime if a case is not handled.
