---
name: react-review-bug-hunting
description: Use this review context when reviewing large-scale React applications to find and correct bugs, regressions, architectural risks, and missing safeguards.
---

# React Review Bug-Hunting Skill

Use this context when performing a code review for a React application, especially in large or long-lived codebases. The review goal is not only to comment on style, but to identify bugs, regressions, fragile behavior, unnecessary complexity, and missing safeguards. Prefer actionable findings with a concrete fix or refactor path.

## Review Mindset

When reviewing React code, prioritize behavior over aesthetics. Look for places where the code can break under realistic user flows, async timing, stale data, large datasets, changed props, slow networks, permissions, localization, feature flags, or backend contract changes.

Lead with bugs and risks. Style, naming, and minor preference comments should only appear when they affect readability, maintainability, or future correctness.

For every finding, try to answer:

- What user-visible bug or developer risk can this cause?
- Under what condition does it happen?
- Is there an existing test that would catch it?
- What is the smallest safe correction?
- Does the fix match the local architecture and patterns?

## High-Priority Bug Patterns

### 1. Incorrect `useEffect` Usage

`useEffect` is often the source of subtle bugs in large React apps. Review every effect and ask whether it represents a real side effect: API calls, subscriptions, DOM coordination, timers, logging, or integration with external systems.

Watch for:

- Derived state being synchronized through `useEffect` instead of being computed during render.
- Missing dependencies that create stale closures.
- Excessive dependencies that cause repeated fetches, loops, or flickering.
- Effects that update state unconditionally.
- Effects that should be event handlers instead.
- Effects that duplicate logic already handled by a data-fetching library.
- Effects without cleanup for subscriptions, listeners, timers, observers, or pending async flows.

Prefer fixes such as:

- Compute derived values directly or with `useMemo` when computation is expensive.
- Move user-triggered logic into handlers.
- Extract a focused custom hook only when it clarifies lifecycle ownership.
- Abort or ignore stale async requests.
- Respect `react-hooks/exhaustive-deps`; if it fights the code, redesign the data flow.

### 2. Server State Mixed With UI State

Server state should not be managed like local UI state. Data from APIs has cache lifetime, loading state, error state, invalidation, deduplication, and refetch behavior. UI state is usually ephemeral: modals, selected tabs, expanded rows, input text, filters, and local drafts.

Watch for:

- API data copied into local state without a clear reason.
- Manual loading, error, cache, and retry logic duplicated across components.
- Multiple components fetching the same resource independently.
- UI bugs after mutation because cached data is not invalidated or updated.
- Backend data stored in Redux, Zustand, or Context without a cache strategy.
- Local component state used as the source of truth after the server changes.

Prefer fixes such as:

- Use the project’s established server-state solution, such as React Query, SWR, Relay, Apollo, or local data hooks.
- Keep UI-only state local where possible.
- Invalidate or update cached queries after mutations.
- Add explicit loading, error, empty, and success states for async views.
- Introduce API-to-UI mappers when backend contracts are noisy or unstable.

### 3. Oversized Components

Large components hide bugs because they mix rendering, fetching, transformation, permissions, form state, table behavior, feature flags, analytics, and modal orchestration in one place.

Watch for:

- Components that are difficult to scan top-to-bottom.
- Several unrelated responsibilities in one file.
- Deeply nested JSX with business logic inline.
- Repeated conditional rendering branches.
- Local helper functions that depend on too much component state.
- Forms, tables, or modals where state changes are hard to trace.

Prefer fixes such as:

- Extract pure presentational components.
- Extract data-loading or orchestration logic into a container or hook.
- Move pure transformations to named helper functions.
- Keep extraction local to the feature before creating shared abstractions.
- Add focused tests around the behavior being protected.

### 4. Global State Overuse

Global state increases coupling. It should represent state that is truly shared across distant parts of the app or needs centralized lifecycle control.

Watch for:

- Local UI details stored globally.
- Redux, Zustand, or Context used as a dumping ground.
- State that never resets when navigating away.
- Components depending on broad state slices and re-rendering too often.
- Selectors that return new object or array references every render.
- Actions that update several unrelated domains at once.

Prefer fixes such as:

- Move state closer to where it is used.
- Split stores, reducers, providers, or selectors by domain.
- Use stable selectors and memoized derived data when needed.
- Keep Context for stable configuration or narrow state boundaries.
- Avoid storing server state globally unless the project deliberately does so.

### 5. Fragile List Rendering

Lists are a common source of visual and state bugs.

Watch for:

- `index` used as a key for dynamic lists.
- Non-stable generated keys such as `Math.random()` or `Date.now()`.
- Stateful child components whose state can move to another row after insert, delete, sort, or filter.
- Large lists rendered without pagination, virtualization, or lazy loading.
- Inline callbacks and objects passed into many repeated children without need.

Prefer fixes such as:

- Use stable IDs from data.
- Add or expose a stable ID in the data model when missing.
- Use virtualization for large lists and tables.
- Keep row components pure when possible.
- Add tests for insert, delete, sort, and filter behavior when the list is critical.

### 6. Direct State Mutation

React depends on immutable updates for reliable rendering and predictable state transitions.

Watch for:

- Arrays mutated with `push`, `splice`, `sort`, or `reverse` directly on state.
- Objects mutated before calling a setter.
- Nested state updates that reuse mutated references.
- Reducers that mutate state unless the project uses Immer intentionally.
- Date, Map, Set, or class instance mutation that React cannot observe clearly.

Prefer fixes such as:

- Return new arrays and objects.
- Use Immer only when already part of the project pattern.
- Normalize complex entities by ID.
- Avoid deeply nested component state when updates become error-prone.

### 7. Missing Async States

Every async view should define what happens while loading, when empty, when failed, and when successful.

Watch for:

- Components assuming data is always present.
- Optional chaining that hides a broken state instead of handling it.
- Blank screens during fetches.
- Errors swallowed in `catch` blocks.
- Retry paths missing for recoverable failures.
- Empty states that look like successful data.
- Loading spinners that block existing usable content unnecessarily.

Prefer fixes such as:

- Add explicit loading, error, empty, and success branches.
- Preserve previous data during background refetches when appropriate.
- Surface recoverable errors with retry actions.
- Add error boundaries for route-level or feature-level crashes.

### 8. Weak Type Contracts

TypeScript should make illegal states hard to represent. Weak typing often hides real production bugs.

Watch for:

- `any`, broad `unknown`, or unsafe casts used as routine escapes.
- Props typed loosely even though exact shape is known.
- Backend DTOs used directly as UI models everywhere.
- Optional fields treated as required.
- Union states modeled as many independent booleans.
- Missing return types on shared hooks, selectors, or utilities.

Prefer fixes such as:

- Model real DTOs, domain entities, and UI view models.
- Use discriminated unions for async and variant states.
- Validate external data at boundaries when the project has a schema library.
- Keep casts close to integration boundaries and explain why they are safe.

### 9. Poor Form Strategy

Forms accumulate bugs quickly because they combine local state, validation, formatting, async submission, error display, and accessibility.

Watch for:

- Form values duplicated across several states.
- Validation split across handlers, effects, and submit logic.
- Submit buttons enabled during pending requests.
- Server validation errors not mapped to fields.
- Inputs without labels, names, or accessible error messaging.
- Controlled and uncontrolled inputs mixed accidentally.
- Reset behavior that loses user input unexpectedly.

Prefer fixes such as:

- Use the project’s standard form library and schema validation approach.
- Centralize validation rules.
- Disable or guard duplicate submissions.
- Map API errors into user-visible field or form errors.
- Test critical form flows from the user perspective.

### 10. Error Handling Gaps

Large apps need predictable failure behavior.

Watch for:

- Promise rejections not handled.
- Errors logged but not shown when the user needs to act.
- Error boundaries missing around risky feature areas.
- Generic fallbacks that hide actionable details.
- Analytics or logging calls that can break the main flow.
- Retry loops without limits.

Prefer fixes such as:

- Add localized error boundaries.
- Separate developer logging from user-facing recovery.
- Make non-critical side effects fail-safe.
- Include tests for failure paths, not only success paths.

## Architecture And Maintainability Risks

### Component Boundaries

Review whether components have one clear reason to change. Components may be presentational, connected to data, form-focused, layout-focused, or orchestration-focused, but mixing all of these roles makes bugs harder to isolate.

Look for:

- Presentation components importing API clients or global stores.
- Data hooks returning JSX.
- Feature modules importing across unrelated domains.
- Shared components containing product-specific rules.

### Abstraction Timing

Premature abstractions are a major source of complexity in React codebases.

Look for:

- Reusable components with many boolean props.
- Generic hooks that hide important business behavior.
- Shared helpers used by only one feature.
- Components that support many variants but are hard to test.

Prefer duplication until a real pattern appears. Extract only when the abstraction reduces complexity and has a stable contract.

### Folder And Module Consistency

Large projects need predictable file placement.

Look for:

- Similar features organized differently.
- Hooks, components, tests, and utilities scattered without convention.
- Barrels that create circular dependencies.
- Shared folders becoming unowned junk drawers.

Prefer the existing project convention over inventing a new structure during review.

## Performance Review Checklist

Do not ask for memoization everywhere. Ask whether the code creates measurable or plausible performance risk.

Watch for:

- Heavy computations during render.
- Large tables or lists rendered in full.
- Context values recreated on every render.
- Providers wrapping too much of the tree.
- Expensive child components receiving unstable props.
- Repeated parsing, formatting, filtering, or sorting on every render.
- Bundle growth from large imports or missing code splitting.

Prefer fixes such as:

- Move heavy computations behind `useMemo` when inputs are stable.
- Memoize expensive repeated children when props are stable.
- Split Context providers or memoize provider values.
- Use lazy loading for route-level or heavy feature code.
- Use virtualization or pagination for large collections.
- Measure with React Profiler or bundle analysis when the impact is uncertain.

## Accessibility And UX Bugs

Accessibility issues are product bugs. They frequently affect keyboard users, screen reader users, mobile users, and users under poor conditions.

Watch for:

- Clickable `div` or `span` elements instead of semantic buttons or links.
- Missing labels on inputs.
- Modals without focus management or escape behavior.
- Menus and popovers that cannot be used with the keyboard.
- Errors not associated with fields.
- Color-only status indicators.
- Focus lost after async updates.
- Disabled controls without explanation when the next action is unclear.

Prefer semantic HTML first. Add ARIA only when native elements cannot express the interaction.

## Testing Review Checklist

React tests should protect behavior, not implementation details.

Watch for:

- Critical user flows with no tests.
- Tests that assert internal state, private functions, or implementation details.
- Mock-heavy tests that cannot catch integration bugs.
- Async tests that do not wait for visible outcomes.
- Tests that only cover success paths.
- Snapshot tests used as a substitute for behavior tests.
- Missing regression tests for the bug being fixed.

Prefer fixes such as:

- Test visible behavior with React Testing Library.
- Add integration tests for important flows.
- Add E2E coverage for critical cross-page or backend-dependent journeys.
- Use realistic mocks at the network boundary.
- Test loading, error, empty, and permission states.

## Code Review Output Format

When providing a review, lead with findings ordered by severity. Each finding should include:

- Severity: blocker, high, medium, or low.
- Location: file and line when available.
- Problem: what can break and why.
- Scenario: when the bug appears.
- Suggested fix: concise and concrete.
- Test gap: what test would catch it, if missing.

Use this shape:

```md
## Findings

### High - Stale data after mutation
Location: `src/features/orders/OrderActions.tsx`

The mutation succeeds but the orders query is not invalidated, so the list can keep showing the old status until a full reload. This can mislead the user after approving or canceling an order.

Suggested fix: invalidate or update the relevant orders query after the mutation settles.

Test gap: add a test that performs the action and verifies the updated status appears without reloading.
```

If there are no findings, say so clearly and mention any remaining test gaps or residual risks.

## Quick Review Checklist

Use this short checklist before finishing:

- Are `useEffect` dependencies correct and necessary?
- Is server state handled by the project’s cache/data layer?
- Are loading, error, empty, and success states explicit?
- Are list keys stable under insert, delete, sort, and filter?
- Is state updated immutably?
- Are global stores used only for truly shared state?
- Are component responsibilities clear?
- Are form validation, submission, and server errors handled consistently?
- Are async failures user-visible when needed?
- Are TypeScript contracts strong enough to prevent invalid states?
- Are performance risks present in large lists, tables, providers, or expensive renders?
- Are interactions accessible by keyboard and screen reader?
- Do tests cover behavior, failure paths, and the regression risk?

## Senior Reviewer Rule

Do not request complexity as a default. A good review should make the code easier to reason about, safer to change, and closer to the project’s existing architecture. The best correction is usually the smallest one that removes the bug and leaves the next reader with fewer surprises.
