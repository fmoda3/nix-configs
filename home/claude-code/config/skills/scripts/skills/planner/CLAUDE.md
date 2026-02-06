# planner/

Planning and execution workflows with QR gates, TW passes, and Dev execution. State files managed by LLM agents for session continuity.

## Files

| File        | What                                                | When to read                                     |
| ----------- | --------------------------------------------------- | ------------------------------------------------ |
| `README.md` | Architecture, data flow, QR gates, design decisions | Understanding planner architecture, QR workflows |

## Shared Files

| File                    | What                                           | When to read                         |
| ----------------------- | ---------------------------------------------- | ------------------------------------ |
| `shared/schema.py`      | Pydantic schemas (context, plan, qr) and       | Understanding state file schemas,    |
|                         | validate_state() function                      | modifying schema definitions         |
| `shared/constraints.py` | Orchestrator constraint AST builders               | Building planner/executor prompts,   |
|                         | (`build_orchestrator_constraint`,                  | composing reusable constraint blocks |
|                         | `build_step_header`, `build_state_banner`)         |                                      |
| `shared/gates.py`       | Unified gate output builder                    | Understanding QR gate logic,         |
|                         | (`build_gate_output`)                          | modifying gate behavior              |

## Subdirectories

| Directory           | What                                   | When to read                               |
| ------------------- | -------------------------------------- | ------------------------------------------ |
| `orchestrator/`     | Main workflows (planner, executor)     | Creating/executing plans                   |
| `architect/`        | Plan design sub-agent                  | Understanding planning workflow            |
| `developer/`        | Code filling and implementation        | Dev execution, diff creation               |
| `technical_writer/` | Documentation scrubbing and generation | TW passes, temporal cleanup                |
| `quality_reviewer/` | QR modules for all phases              | QR logic, validation, understanding gates  |
| `shared/`           | Shared resources, schemas, conventions | Accessing conventions, resource management |

## State Files

All plan state lives in plan.json. Context captured separately in context.json. See README.md for full schemas.

| File              | What                                    | Mutability          | When to read                   |
| ----------------- | --------------------------------------- | ------------------- | ------------------------------ |
| `plan.json`       | Complete plan state (milestones, diffs, | mutable -> frozen   | All planning phases            |
|                   | code_intents, code_changes, docs)       |                     |                                |
| `context.json`    | User-provided planning context          | frozen after step 2 | Sub-agent context handover     |
| `qr-{phase}.json` | QA items for specific phase (ephemeral) | ephemeral           | QA decomposition, verification |
