"""Generic batch RPC dispatch via function introspection.

Functions with 'ctx' as first parameter are auto-discovered from modules.
No decorators needed - write a function, it becomes a method.
"""
import inspect
from typing import Any


def discover_methods(module) -> dict[str, callable]:
    """Find all public functions with 'ctx' as first parameter.

    Convention: function_name -> method-name (underscores to hyphens)
    """
    methods = {}
    for name, func in inspect.getmembers(module, inspect.isfunction):
        if name.startswith("_"):
            continue
        sig = inspect.signature(func)
        params = list(sig.parameters.keys())
        if params and params[0] == "ctx":
            method_name = name.replace("_", "-")
            methods[method_name] = func
    return methods


def extract_params(func) -> tuple[set[str], dict[str, Any]]:
    """Extract required/optional params from function signature.

    Skips first param (ctx). Returns (required_set, optional_dict).
    """
    sig = inspect.signature(func)
    required, optional = set(), {}
    for pname, param in list(sig.parameters.items())[1:]:
        if param.default is inspect.Parameter.empty:
            required.add(pname)
        else:
            optional[pname] = param.default
    return required, optional


def dispatch(methods: dict, method: str, params: dict, ctx) -> Any:
    """Dispatch single RPC call. Returns result or raises."""
    if method not in methods:
        raise ValueError(f"Unknown method: {method}. Available: {sorted(methods.keys())}")

    func = methods[method]
    required, optional = extract_params(func)

    missing = required - set(params.keys())
    if missing:
        raise ValueError(f"Missing required params: {sorted(missing)}")

    # Build kwargs: start with optional defaults, override with provided params
    kwargs = {k: params.get(k, v) for k, v in optional.items()}
    kwargs.update({k: params[k] for k in required if k in params})
    # Also include any extra optional params that were provided
    for k in params:
        if k not in kwargs:
            kwargs[k] = params[k]

    return func(ctx, **kwargs)


def batch(methods: dict, requests: list[dict], ctx) -> list[dict]:
    """Execute batch of RPC requests sequentially.

    Each request: {"method": str, "params": dict, "id": any}
    Each response: {"id": any, "result": any} or {"id": any, "error": {...}}
    """
    results = []
    for req in requests:
        req_id = req.get("id")
        method = req.get("method", "")
        params = req.get("params", {})

        try:
            result = dispatch(methods, method, params, ctx)
            results.append({"id": req_id, "result": result})
        except Exception as e:
            results.append({
                "id": req_id,
                "error": {"code": -32000, "message": str(e)}
            })
    return results


def list_methods(methods: dict) -> dict[str, dict]:
    """Return method signatures for discoverability."""
    result = {}
    for name, func in methods.items():
        required, optional = extract_params(func)
        doc = func.__doc__.split('\n')[0] if func.__doc__ else ""
        result[name] = {
            "required": sorted(required),
            "optional": sorted(optional.keys()),
            "description": doc,
        }
    return result
