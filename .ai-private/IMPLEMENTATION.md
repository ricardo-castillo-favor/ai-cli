# CACHE-2418 — Implementation Summary

Adds the missing "are you sure you want to edit your delivery schedule?" confirmation when a
customer changes the time and/or frequency of an existing **recurring** order series from
recurring-order management, per `PLANNING.md`. No backend change; `PATCH /bffrecurring` and
`useUpdateRecurringOrder` are untouched.

## Deviation from PLANNING.md — how the confirmation is shown

The plan's own R2 risk called out possible modal-stacking/close-ordering issues but left the
resolution open ("if ambiguous, close the picker first then open the confirmation"). During
implementation this turned out to be load-bearing, not a corner case:

- `common/modules/Modals/index.tsx`'s `Modals` component renders **every** modal in the
  `modals` array, but only passes `isCurrentModal={index === 0}` to the oldest one; that flag is
  what feeds `CSSTransition`'s `in` prop. Verified against `react-transition-group`'s
  `Transition.js`: when `in` starts `false` and `unmountOnExit` is set (both true here), the
  component's initial status is `UNMOUNTED` and `render()` returns `null` — it never mounts at
  all until it becomes index 0. In other words, **only the first-opened modal is ever visible**;
  later ones in the array queue invisibly behind it.
- That means the plan's literal suggestion — `dispatch(openModal({name: 'SimpleConfirmation', ...}))`
  while `DeliveryTimeModal` (the picker) is still open — would silently queue the confirmation
  behind the still-open picker and never show it.
- This exact problem, and its fix, already exist three times in this same area of the codebase:
  `ChooseLocation/index.tsx` (comment: *"Close the picker first so the confirmation isn't stacked
  behind it"*), and `DeliveryTime/useGetItNowFlow.ts` / `useSkipOnceFlow.ts` (both call
  `onCloseParent?.()` before dispatching the `SimpleConfirmation`). All three close the modal that's
  currently open before opening the confirmation, rather than trying to layer it on top.

Implementation follows that proven, already-tested pattern: `handleConfirm` closes the
`DeliveryTimeModal` picker (`handleClose()`) and *then* dispatches the `SimpleConfirmation`, which
becomes the new (only) modal and is shown immediately. Per AC #3's own wording ("...the user is
returned to the delivery-time picker **(or the management screen)** with their edit intact/discarded
**per design**"), landing back on the recurring-management screen with the edit discarded on cancel
is an explicitly sanctioned outcome — not a compromise.

`onConfirmScheduledOrder` (captured in the confirmation's `onClick`) still runs correctly after the
picker unmounts: it only touches Redux (`dispatch(setDeliveryTime(...))`) and the caller's `onConfirm`
prop (a plain function reference, not tied to the picker's component instance) for the recurring
branch — no state update on the now-unmounted picker is required for correctness (the harmless
`setIsLoadingConfirm(false)` after unmount is the same class of no-op the codebase already tolerates
in the pre-existing merchant-closed-announcement branch of the same function).

## Change detection

`hasScheduleChanged` (local to `handleConfirm`) compares the in-progress selection against the
currently-saved schedule already in scope:

```ts
const hasScheduleChanged =
  activeChoice?.start_time !== currentDeliveryTime.window?.start_time ||
  (selectedFrequency?.id ?? '') !== (currentDeliveryTime.initial_cadence_id ?? '')
```

The confirmation only fires when `isFromRecurringManagement && hasScheduleChanged` — a no-op confirm
(nothing changed) persists immediately exactly as before, so the prompt only appears "when a user
makes changes," matching the AC wording. Time-only, frequency-only, and both-changed cases all take
the confirmation branch.

No `scheduleTab === 'recurring'` check was added alongside `isFromRecurringManagement`: when
`isFromRecurringManagement` is true, `HeaderScheduledOrder` hides the one-time/recurring tab switcher
entirely (`!isFromRecurringManagement && <tabs-container>`), so `scheduleTab` can never leave
`'recurring'` in this mode — the extra check would be dead code.

## Files Modified

- `app/common/constants.ts` — added `EDIT_RECURRING_SCHEDULE_TITLE`, `_MESSAGE`, `_CONFIRM`,
  `_CANCEL` with the exact copy confirmed in `PLANNING.md` §7 ("Are you sure you want to edit your
  delivery schedule?" / "This will update the delivery schedule for your next order and all
  following orders." / "Update schedule" / "No thanks"). No feature flag was added, per the
  explicit instruction in `PLANNING.md` §7 to gate solely on the existing
  `isFromRecurringManagement` condition.
- `app/common/modules/Modals/containers/DeliveryTime/index.tsx` — `handleConfirm`: after the
  existing merchant-closed and item-availability checks pass, computes `hasScheduleChanged` and,
  when `isFromRecurringManagement` is also true, closes the picker and opens a `SimpleConfirmation`
  (`id: 'edit-recurring-schedule-confirmation'`) whose primary button (`onClick`) runs the existing
  `onConfirmScheduledOrder()`. The secondary button intentionally has no `onSecondaryButtonClick`,
  so it falls through to `SimpleConfirmation`'s default (just closes the confirmation) — nothing
  extra needs to run on cancel since the edit was never persisted. All non-recurring-management and
  unchanged-schedule paths fall through to the original `handleClose(); onConfirmScheduledOrder()`
  unchanged. `handleConfirm`'s dependency array gained `isFromRecurringManagement`,
  `currentDeliveryTime.window?.start_time`, and `currentDeliveryTime.initial_cadence_id`.
- `app/common/modules/Modals/containers/DeliveryTime/__tests__/index.test.tsx` — added a
  `describe('DeliveryTimeModal — recurring-management edit confirmation (CACHE-2418)', ...)` block
  (5 cases, asserting directly against the real Redux `modals` slice returned by
  `render()`'s `store`, no mocking of `@store/Modals/actions` needed):
  1. Changed time + frequency → opens the `SimpleConfirmation` with the exact AC copy; `setDeliveryTime`
     and the `onConfirm` prop have **not** fired yet.
  2. Invoking the dispatched modal's `onClick` runs the edit (`setDeliveryTime` dispatched with the
     new window/cadence, `onConfirm` prop called).
  3. Unchanged schedule → no modal opened, edit proceeds directly (regression).
  4. Frequency-only change (same time, different cadence) → still prompts (R5 from the plan).
  5. One-time / non-recurring-management confirm → never opens the confirmation modal (regression).

## Not implemented (out of scope / ops tasks)

- **Analytics** — none added, per explicit instruction in `PLANNING.md` §7 ("No analytic data,
  please").
- **Playwright E2E** — not added in this session; the plan's suggested scenario (open recurring
  management → change time → confirm → assert `SimpleConfirmation` → confirm → assert the PATCH)
  needs a HAR recording session, which isn't achievable here. The existing recurring-management
  Playwright coverage is unaffected since this change is purely additive UI gated on an existing,
  already-true prop.
- **Figma-exact visual QA** — copy was taken verbatim from the user's answers in `PLANNING.md` §7
  rather than re-fetched from Figma; no visual/styling changes were made to `SimpleConfirmation`
  itself.

## Verification

- `npx tsc --noEmit -p tsconfig.json` — no errors.
- `npx eslint common/constants.ts common/modules/Modals/containers/DeliveryTime/index.tsx` — 0
  errors; the only warnings present are pre-existing ones in untouched lines of the same file
  (`consistent-type-assertions`, `set-state-in-effect` in unrelated `useEffect`s further up the
  file), confirmed unrelated to this change.
- `npx prettier --check` on all touched files — clean.
- `npx jest common/modules/Modals common/containers/Drawers/RecurringOrderEditDrawer` — **22 test
  suites / 162 tests, all passing**, including the 5 new CACHE-2418 cases and all pre-existing
  `DeliveryTimeModal` / `RecurringOrderEditDrawer` / `CartComponent` coverage unchanged.
