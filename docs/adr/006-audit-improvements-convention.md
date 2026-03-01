# ADR-006: Audit Improvements Convention

## Status

Proposed

## Context

New audit dimensions introduced by the `audit-improvements` change (D12 ADR Coverage, D13 Spec Coverage) needed a scoring approach. Two alternatives were available: add the new dimensions to the existing 100-point pool, or follow the established pattern of informational-only dimensions (D9, D10, D11 — no score deduction). Adding new dimensions to the 100-point pool shifts all existing project baselines, which the proposal rated as a HIGH-probability, MEDIUM-impact risk. The informational-only pattern is already used for three dimensions and is the convention for new audit coverage that is not yet stable.

## Decision

We will add new audit dimensions as informational-only (scoring: N/A) following the same pattern established by D9, D10, and D11. New dimensions are only activated when the relevant artifacts are present in the project (conditional skip with N/A when absent). This convention applies to any future audit dimension until it is explicitly promoted to scored status by a dedicated change.

## Consequences

**Positive:**

- Existing project baselines are not disrupted when new audit dimensions are added
- New dimensions can be introduced incrementally without requiring all projects to immediately satisfy them
- The pattern is already familiar to anyone reading the existing audit skill

**Negative:**

- New dimensions have no score incentive — projects may ignore findings indefinitely without audit score degradation
- Promoting a dimension from informational to scored requires a separate change and baseline re-evaluation for all projects
