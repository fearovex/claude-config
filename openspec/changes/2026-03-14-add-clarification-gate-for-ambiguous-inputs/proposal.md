# Proposal: Add Clarification Gate for Ambiguous Inputs

**Date**: 2026-03-14
**Status**: Draft
**Priority**: Medium
**Scope**: Orchestrator — Intent Classification

---

## Problem Statement

The orchestrator's classification system defaults ambiguous single-word or phrase-only inputs to `Question` and responds directly. This sometimes misses the user's actual intent when the input could reasonably be either:
- **Change Request**: `"auth"` might mean "fix the auth system"
- **Exploration**: `"auth"` might mean "show me how auth works"
- **Question**: `"auth"` might mean "what is auth?"

Defaulting to Question causes missed opportunities for clarification. The user then has to re-specify their intent explicitly, requiring an extra interaction.

**Observed pattern**: Inputs with no clear intent verb (`"refactor"`, `"login"`, `"auth"`) or missing target (`"refactor"` without "what") are the most prone to misclassification.

---

## Proposed Solution

Add a **clarification gate** in the orchestrator that intercepts ambiguous inputs **before** defaulting to Question. When an input matches the ambiguity pattern, ask a single focused clarifying question instead of assuming:

```
User: "refactor"

Orchestrator: I'm not sure what you'd like me to do with "refactor".
Are you looking to:
  1. Refactor some specific code (change request)
  2. Explore refactoring patterns in the codebase (exploration)
  3. Learn what refactoring is (information)

Just reply with 1, 2, 3, or clarify in your own words.
```

Once clarified, route to the correct class and proceed.

---

## Benefits

1. **Fewer misdirected cycles**: Users won't accidentally trigger `/sdd-ff` when they just want an explanation
2. **Better UX**: Single prompt is faster than: unclear response → user re-asks → correct routing
3. **Clear traceability**: We know the user's actual intent, not a guess
4. **Handles edge cases**: "fix and explain" becomes explicit instead of silently defaulting to Change Request

---

## Scope

**In scope**:
- Add ambiguity detection logic to the Classification Decision Table
- Define the gate question(s) and routing after user answers

**Out of scope**:
- Changing classification for non-ambiguous inputs (e.g., `"fix the login bug"` still immediately routes to Change Request)
- Adding new intent classes (still 4 classes)
- Modifying CLAUDE.md structure (gate is procedural, not table structure)

---

## Success Criteria

1. ✅ Ambiguous single-word inputs (`"auth"`, `"login"`, `"refactor"`) trigger a clarification prompt
2. ✅ Clarification prompt offers 3 options aligned to the top 3 intent classes
3. ✅ After user picks an option, routing proceeds to the correct class
4. ✅ Non-ambiguous inputs are **not** affected (no performance degradation)
5. ✅ Verification: Manual testing in 2 independent sessions with edge case inputs confirms correct routing

---

## Timeline

- **Explore**: Understand current classification logic and identify all ambiguity patterns
- **Propose**: Define the gate question template and classification logic
- **Spec**: Write requirements for ambiguity detection and gate prompt
- **Design**: Choose where in the orchestrator to insert the gate, design the decision tree
- **Tasks**: Implement gate prompt and routing logic
- **Verify**: Test with edge cases, confirm non-ambiguous inputs unaffected

---

## Open Questions

1. Should we cache clarifications per session so the same user doesn't get asked twice about `"auth"`?
2. Should ambiguous inputs _always_ trigger a gate, or only when confidence is below a threshold?
3. Where in the orchestrator should the gate logic live — in the decision table comment block or in the "unbreakable rules" section?

---

## Related Changes

- **Previous**: `2026-03-14-orchestrator-classification-edge-cases` — added edge case examples to help detect ambiguity
- **Depends on**: None
- **Blocks**: None
