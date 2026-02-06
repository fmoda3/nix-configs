"""Fluent builder API for constructing AST nodes.

Usage:
    from skills.lib.workflow.ast import W, render, XMLRenderer, TextNode

    doc = W.el("step_header", TextNode("Title"),
               script="myskill", step="1").build()
    output = render(doc, XMLRenderer())

W.el(tag, *children, **attrs) is the primary method. All specialized builder
methods were removed because skills use W.el() exclusively.
"""

from skills.lib.workflow.ast.nodes import Node, Document, ElementNode


class ASTBuilder:
    """Immutable builder for constructing AST documents.

    Each method returns a NEW builder instance with the accumulated node.
    Call .build() at the end to collect accumulated nodes into Document.

    Example:
        W.el("step_header", TextNode("Action"), script="x", step="1").build()
        -> Document(children=[ElementNode("step_header", {...}, [TextNode("Action")])])
    """

    def __init__(self, nodes: list[Node] | None = None):
        """Initialize builder with optional accumulated nodes."""
        self._nodes = nodes if nodes is not None else []

    def el(self, tag: str, *children: Node, **attrs: str) -> 'ASTBuilder':
        """Add element node and return new builder.

        Args:
            tag: XML tag name
            *children: Child nodes (varargs)
            **attrs: Element attributes (kwargs)
        """
        return ASTBuilder(self._nodes + [ElementNode(tag, attrs, list(children))])

    def build(self) -> Document:
        """Collect accumulated nodes into Document."""
        return Document(children=self._nodes)

    def node(self) -> Node:
        """Return the single accumulated node.

        Convenience method for W.el(...).node() pattern replacing .build().children[0].
        Raises ValueError if builder contains != 1 node.
        """
        if len(self._nodes) != 1:
            raise ValueError(f"node() requires exactly 1 node, got {len(self._nodes)}")
        return self._nodes[0]


W = ASTBuilder()
