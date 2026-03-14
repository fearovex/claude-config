# Technical Design: Orchestrator Visibility

Date: 2026-03-14
Proposal: openspec/changes/2026-03-14-orchestrator-visibility/proposal.md

## General Approach

Implement three complementary visibility signals to make the SDD Orchestrator's behavior transparent to users:

1. **Session-start banner** in CLAUDE.md system prompt confirming orchestrator is active
2. **Intent classification signal** injected into response headers before every free-form message classification
3. **`/orchestrator-status` skill** providing on-demand state queries about active SDD changes and loaded orchestrator rules

These signals provide confidence feedback at three time scales: session start (banner), per-response (signal), and on-demand (status command).

---

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|----------------|
| Banner placement | New H2 section in CLAUDE.md right after "Always-On Orchestrator — Intent Classification" title, before "Intent Classes and Routing" | 1. Inline comment in CLAUDE.md frontmatter 2. Separate file (banner.txt) 3. System prompt hook | H2 section is discoverable by users, semantically part of the Orchestrator documentation, and follows CLAUDE.md conventions. Avoids external file indirection. |
| Banner display mechanism | Orchestrator reads from CLAUDE.md at session start; text is static markdown that Claude displays verbatim to user | 1. Dynamic banner generated from state 2. Hardcoded in system prompt 3. Separate banner skill | Orchestrator already reads CLAUDE.md for intent classification rules. Reuse that read. Banner is static descriptive text, not computed state. |
| Intent signal format | Prefix response with `**Intent classification: <Class>**` (bold markdown) on a new line before any other content | 1. `[Class]` in square brackets 2. Emoji indicator (🎯 etc.) 3. Inline in first sentence 4. Hidden in system-internal metadata | Bold markdown is visible, unmissable, follows CLAUDE.md's own style (already uses bold for section markers and emphasis). Square brackets are less prominent. Emojis contradict project conventions (no emojis in output). Internal metadata is invisible to users. |
| Signal injection scope | Only for free-form user messages that go through intent classification. Slash commands and SDD sub-agent responses do NOT show the signal. | 1. Signal for all messages including slash commands 2. Signal only in SDD responses 3. No signal at all (status quo) | Slash commands skip classification entirely (defined in CLAUDE.md). SDD sub-agent responses are delegated work, not orchestrator decisions. Free-form classification is where user uncertainty lies — signal it there. |
| `/orchestrator-status` implementation | Procedural skill at `~/.claude/skills/orchestrator-status/SKILL.md` — reads CLAUDE.md, openspec/config.yaml, and .claude/ directory structure to gather state | 1. Slash command inline in CLAUDE.md 2. Stored in CLAUDE.md as a read-only reference section 3. Built into orchestrator logic (not separate) | Skills are the standard extension point in this system. Procedural skill allows fresh context injection and file I/O. Avoids polluting CLAUDE.md with procedural logic. Follows the existing skill architecture pattern. |
| Status data structure | Return a JSON block displaying: (a) orchestrator state (classification enabled/disabled, rules count), (b) active SDD changes (list from openspec/changes/), (c) loaded orchestrator skills (from CLAUDE.md registry) | 1. Plain text summary 2. HTML table 3. YAML structure | JSON is structured, parseable, and consistent with other SDD output. Markdown rendering of JSON blocks is readable in Claude UI. Avoids HTML (not part of project tech stack). |
| Status placement in output | Markdown code block with ` ```json ` fence, followed by a prose "Interpretation" section that explains what the user is seeing | 1. Bare JSON object (no fence) 2. Table format 3. Just the prose, no structured data | Code fence makes it scannable and hints at structure. Prose explanation prevents user confusion about what "enabled" vs. "proposed" means. |

---

## Data Flow

```
User sends free-form message
         ↓
Orchestrator reads CLAUDE.md (Intent Classification section)
         ↓
Classification logic applied (keyword matching, routing rules)
         ↓
Intent class assigned (Change Request | Exploration | Question | Meta-Command)
         ↓
Response preamble built: **Intent classification: [Class]**
         ↓
User sees signal + rest of response
         ↓
(If user invokes /orchestrator-status)
         ↓
orchestrator-status skill reads:
   - CLAUDE.md (rules count, classification enabled/disabled)
   - openspec/changes/ (active change list)
   - CLAUDE.md Skills Registry (loaded skills)
         ↓
JSON state block + prose interpretation
         ↓
User sees current orchestrator state
```

**Session-start banner flow:**

```
New session starts
         ↓
Claude system prompt loads CLAUDE.md
         ↓
Orchestrator reads banner section from CLAUDE.md
         ↓
Banner text displayed to user at start of first response
         ↓
User sees: "This session is running the SDD Orchestrator..."
```

---

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `CLAUDE.md` | Modify | Add "## Orchestrator Session Banner" section after "Always-On Orchestrator — Intent Classification" title; banner displays on every new session |
| `CLAUDE.md` | Modify | Add `/orchestrator-status` to "Available Commands" table in "Meta-tools — Project Management" section |
| `CLAUDE.md` | Modify | Add `/orchestrator-status` to "How I Execute Commands" → "Meta-tools" mapping table |
| `~/.claude/skills/orchestrator-status/SKILL.md` | Create | New procedural skill: reads state and returns structured JSON + interpretation |
| `docs/orchestrator-examples.md` (new file, optional) | Create | Documentation showing example orchestrator signals and their meanings |

**Note:** Banner will be displayed by Claude at session start automatically; no code changes needed to the orchestrator itself. The signal injection happens inline via the orchestrator's response construction (that is, in the user's system prompt at runtime).

---

## Interfaces and Contracts

### 1. CLAUDE.md Banner Section

**Location:** Right after the "## Always-On Orchestrator — Intent Classification" heading (line 12), before "### Intent Classes and Routing" heading (line 16).

**Text to insert:**

```markdown
### Orchestrator Session Banner

> **Status**: This session is running the SDD Orchestrator.
>
> The orchestrator automatically classifies your intent and routes requests:
> - **Change Request** (fix, add, implement, etc.) → recommends `/sdd-ff <slug>`
> - **Exploration** (review, analyze, examine, etc.) → launches `sdd-explore` via Task
> - **Question** (what is, how does, etc.) → answered directly
> - **Meta-Command** (starts with `/`) → executed immediately
>
> Each response will show the intent class in **bold** for transparency. You can also check `/orchestrator-status` to see active changes and loaded rules.

---
```

### 2. Intent Signal Format

**When injected into response:** Before any other response content, the orchestrator outputs:

```
**Intent classification: Change Request**
```

Or:

```
**Intent classification: Question**
```

**Example user message:** "I want to add a retry mechanism to the payment service."

**Orchestrator response starts with:**

```
**Intent classification: Change Request**

Understood. I'll recommend the fast-forward SDD cycle for this. Let me infer a slug from your description...
```

### 3. `/orchestrator-status` Return Data

**Call:** `GET /orchestrator-status` (or via `/orchestrator-status` slash command)

**Return structure:**

```json
{
  "orchestrator_state": {
    "classification_enabled": true,
    "unbreakable_rules_count": 5,
    "session_start": "2026-03-14T10:23:45Z",
    "configuration_source": "C:/Users/juanp/claude-config/CLAUDE.md"
  },
  "active_sdd_changes": [
    {
      "name": "2026-03-14-orchestrator-visibility",
      "status": "in-progress",
      "artifacts": ["proposal.md", "design.md"]
    }
  ],
  "loaded_orchestrator_skills": [
    "sdd-ff",
    "sdd-new",
    "sdd-explore",
    "sdd-propose",
    "sdd-spec",
    "sdd-design",
    "sdd-tasks",
    "sdd-apply",
    "sdd-verify",
    "sdd-archive",
    "sdd-status"
  ],
  "skills_registry_count": 51
}
```

**Interpretation (prose):**

```
Orchestrator Status (2026-03-14 10:23:45 UTC)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Orchestrator: ENABLED
  Rules loaded: 5 unbreakable rules from CLAUDE.md
  Configuration: C:/Users/juanp/claude-config/CLAUDE.md

Active SDD Changes: 1
  • 2026-03-14-orchestrator-visibility (in-progress)
    Artifacts: proposal.md, design.md

Loaded Skills: 11 orchestrator + SDD phase skills
  Core: sdd-ff, sdd-new, sdd-status
  Phases: sdd-explore, sdd-propose, sdd-spec, sdd-design,
          sdd-tasks, sdd-apply, sdd-verify, sdd-archive
  Project catalog: 51 total skills

Ready to accept: /sdd-ff <slug> | /sdd-explore <topic> | /sdd-new <change>
```

---

## Testing Strategy

| Layer | What to test | Method |
|-------|--------------|--------|
| Unit | Banner text displays at session start (no errors) | Manual: start new session, look for banner in first response |
| Unit | Signal injection works for each intent class (Change Request, Exploration, Question, Meta-Command) | Manual: send 4 test messages, verify each shows correct class prefix |
| Unit | `/orchestrator-status` reads CLAUDE.md without errors | Manual: run `/orchestrator-status`, verify JSON is valid |
| Integration | Signal does NOT appear for slash commands | Manual: run `/project-audit`, verify no intent class line appears |
| Integration | Signal does NOT appear for SDD sub-agent responses | Manual: run `/sdd-ff test-change`, observe sdd-propose sub-agent output has no signal |
| Integration | Banner appears exactly once per session | Manual: multi-turn conversation, banner only in first response |
| E2E | User sees clear intent classification feedback within 1 interaction | Manual: new session, ask a question, verify signal + answer appears |

---

## Migration Plan

No data migration required. This change is purely additive:
- New section in CLAUDE.md (documentation)
- New skill file (doesn't affect existing code)
- New response signal (informational only, does not change routing logic)

Rollback is non-destructive (remove sections from CLAUDE.md, delete skill directory).

---

## Open Questions

None. The proposal clearly specifies all three components, and the implementation is straightforward CLAUDE.md editing + new skill creation.

---

## ADR Candidate Analysis

**Scan of Technical Decisions table for architectural significance:**

Looking for keywords: `pattern`, `convention`, `cross-cutting`, `replaces`, `introduces`, `architecture`, `global`, `system-wide`, `breaking`

**Matches found:**
- Row 2 (Banner display mechanism): contains "system prompt" — potential cross-cutting concern
- Row 4 (Signal injection scope): contains "orchestrator" and describes behavior scope — architectural
- Row 5 (`/orchestrator-status` implementation): contains "standard extension point" and "skill architecture pattern"

**Decision:** These decisions are implementation-level refinements of the existing intent classification system (ADR-029: orchestrator-always-on-intent-classification). They do not introduce a new architecture pattern or replace an existing one. **ADR generation is NOT triggered.** The changes are coherent extensions of the existing orchestrator architecture.

---

## Summary for Orchestrator

**Design: Orchestrator Visibility**
- **Affected files:** CLAUDE.md (2 modifications), new skill orchestrator-status
- **Approach:** Session banner (static), intent signal injection (per-response), on-demand status skill
- **Risks:** None identified — changes are purely additive and non-breaking
- **Rollback:** Remove banner section, delete skill, remove signal injection (all reversible)

**Next phase:** `sdd-tasks` — break down the 3 implementation tasks (banner, signal, skill)
