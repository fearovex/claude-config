# ADR-036: Model Routing Convention — Three-Level Priority Chain for Orchestrator Task Calls

## Status

Proposed

## Context

All SDD sub-agent Task calls in `sdd-ff` and `sdd-new` hardcode `model: sonnet`. Phases like `sdd-design` and `sdd-explore` involve complex reasoning and architectural judgment where a higher-capability model (Claude Opus) would produce meaningfully better output. Users had no mechanism to opt into Opus for individual phases or for an entire orchestrator session without manually editing skill files.

Two approaches were available: (A) a CLI flag that overrides all phases for a session (`--opus` / `--power`), and (B) a per-phase config key in `openspec/config.yaml` under a new `model_routing.phases` map. Both are useful at different granularities and are not mutually exclusive. The resolution order between them — and relative to the existing Sonnet default — must be defined as a system-wide convention so all future orchestrators apply the same logic consistently.

## Decision

We will implement a three-level model resolution priority chain in `sdd-ff` and `sdd-new`:

1. **CLI flag** (`--opus` or `--power` in `$ARGUMENTS`) — highest priority; sets `use_opus = true` and overrides all phases for the session.
2. **Per-phase config** (`openspec/config.yaml → model_routing.phases.<phase>`) — overrides the default for the named phase; ignored when the CLI flag is active.
3. **Sonnet default** (`claude-sonnet-4-5`) — lowest priority; preserves existing behavior when neither flag nor config entry is present.

The flag is extracted at Step 0 before slug inference, so it does not pollute the slug algorithm. Phase skills (`sdd-explore`, `sdd-propose`, etc.) are not modified; they remain model-agnostic and execute inside Tasks whose model parameter is set by the orchestrator. The `model_routing` key is a new optional top-level section in `openspec/config.yaml`, consistent with the `verify:` grouping pattern (ADR 035).

## Consequences

**Positive:**

- Users can opt into Opus for reasoning-intensive phases without editing any skill file
- The CLI flag provides a single-invocation override; the config key provides persistent per-phase defaults
- Existing behavior (Sonnet for all phases, no flag, no config) is fully preserved as the lowest-priority fallback
- The resolution logic is inline in the orchestrators — no new file-read skill or external dependency required
- Phase skills remain model-agnostic, preserving single-responsibility: orchestrator selects model, phase executes within it

**Negative:**

- Two-file duplication of the resolution sub-step (`sdd-ff` and `sdd-new`) — divergence risk mitigated by this ADR serving as the authoritative spec
- `use_opus` / `phase_map` are in-session variables; they do not persist across invocations or from `sdd-ff` to a later standalone `/sdd-verify`
- Standalone phase invocations (`/sdd-apply --opus`, `/sdd-verify --opus`) cannot inherit the CLI flag — config-driven `model_routing.phases` is the only mechanism for standalone phases (explicitly out of scope for V1)
- The full model ID (`claude-opus-4-5`) must be kept current as Claude model identifiers evolve
