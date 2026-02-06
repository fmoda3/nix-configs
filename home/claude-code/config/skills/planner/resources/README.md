# Planner Resources

## Overview

Templates injected by planner scripts at runtime. Scripts load these via direct
Path resolution, not through `get_resource()` from `shared/resources.py`.

## Loading Mechanism

Resources are loaded inline in each script that needs them:

```python
# planner.py:168
format_path = Path(__file__).parent.parent / "resources" / "plan-format.md"

# explore.py:52
format_path = Path(__file__).parent.parent / "resources" / "explore-output-format.md"
```

The `get_resource()` function in `shared/resources.py` exists but is unused for
these files. Scripts prefer inline Path resolution for explicitness.
