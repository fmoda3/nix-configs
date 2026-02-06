# Claude Prompt Engineering: Long Context Handling

**Source:** Anthropic Documentation (docs.anthropic.com)

---

## Document Placement

For long context (20K+ tokens), placement significantly affects accuracy:

**Rule:** Documents at TOP, query at BOTTOM.

This yields ~30% improvement on complex multi-document tasks compared to
query-first placement.

```xml
<documents>
  <document index="1">
    <source>report.pdf</source>
    <document_content>{{CONTENT}}</document_content>
  </document>
  <document index="2">
    <source>analysis.pdf</source>
    <document_content>{{CONTENT}}</document_content>
  </document>
</documents>

Analyze the documents above. First, quote relevant passages in <quotes>,
then answer the following question: {{QUERY}}
```

---

## Grounding with Quotes

Force attention to source material before synthesis by requiring quotes:

```
First, quote relevant passages in <quotes>, then answer.
```

This grounding step:

- Prevents hallucination by anchoring to source text
- Makes reasoning transparent and verifiable
- Forces the model to locate evidence before synthesizing

**Pattern:**

1. Present documents (with index/source metadata)
2. Request quotes extraction first
3. Then request analysis/answer

---

## Why This Works

Claude's attention mechanism processes context sequentially. Placing documents
first allows the model to:

1. Build internal representations of document content
2. Have full document context available when processing the query
3. Attend back to relevant passages during answer generation

Query-first placement forces the model to hold the query in working memory while
processing documents, reducing effective attention to document content.
