# Plan: Show model-load progress on the example home

## Goal

While the example home awaits open, a user sees the locked Opening… text, the exact English label Loading the model, and an indeterminate progress meter. Idle mounts still show none of that chrome. Open failure behaviour and public library call shapes stay as they are today.

## Approach

Keep the existing opening-flag branch on the example home as the only gate for opening chrome. Inside that branch, leave Opening… in place and add two siblings: the fixed label Loading the model, and a progress control configured as indeterminate so it never shows a fraction and never depends on a timer inventing one.

Extend the example widget and source tests so they lock the additive chrome without weakening the idle absence check, the Opening… source lock, the failure prefix, or success-only Snake navigation. Do not touch library open or predict entry points, checkpoint download, or session create.

Verification stays in the example VM test surface. Per the macOS ONNX session-sandbox solution, VM flutter test is not session-load proof; this slice does not add or claim a native session-load check.

## Why this approach

Research compared an indeterminate meter, replacing Opening…, download byte fractions, an optional progress callback, discrete phase markers, and a fake percentage on a timer. An indeterminate meter plus the new label inside the existing opening branch was chosen because neither download nor session create exposes a numeric fraction, and on a complete cache the remaining wait is the opaque session create. The minutes-long emulator duration is unverified and is not required for that choice. Replacing Opening… was rejected because it breaks the source lock and the autostart opening-label criteria. Byte-fraction download instrumentation was rejected because it needs a library change and is silent on the complete-cache path. An optional progress callback on open was rejected as a closed public-signature change that still cannot report true session-create progress. Discrete phase markers were rejected as the primary meter because they still do not measure the session-create wait. A fake percentage on a timer was rejected by the work-item decision recorded in STATE.yaml. GOAL's no-step-timer rule applies to Snake steps and is not the authority for that rejection.

## Product contract

Units realise R-001 through R-005 in 04-product-contract.md. This plan adds no behaviour beyond that contract.

## Units

### U1. Opening-branch loading chrome

Done when: while the opening flag is true the example home shows Opening…, the exact text Loading the model, and an indeterminate progress meter; while the flag is false those two new indicators are absent along with Opening… on idle mounts.

Files it may touch: the example home widget under example/lib, and example widget or source tests under example/test.

| Scenario | Category | Input | Action | Expected outcome | Covers |
|---|---|---|---|---|---|
| Opening chrome visible | happy path | Example home source, without calling open and without a native session | Inspect the opening-flag branch in source | That branch contains Opening…, the exact text Loading the model, and an indeterminate progress control with no fraction value and no wall-clock timer that invents a percentage. A live open is not the check, because the opening flag is private and set only on the path that awaits open | R-001, R-002, AE-001 |
| Idle chrome absent | edge | Default example app with autostart off | Pump and inspect after a second frame | Opening…, Loading the model, and the progress meter are all absent | R-003, AE-002 |
| Opening… retained | edge | Example home source | Search the source for the locked opening string | Opening… remains in source; Loading the model is additive, not a replacement | R-001 |

### U2. Failure and library surface unchanged

Done when: open failure still uses the locked Could not open runtime: prefix and does not navigate to Snake, and the public open and predict signatures of the library are unchanged by this slice.

Files it may touch: only example tests if a regression assertion is needed; library public entry points must not change.

| Scenario | Category | Input | Action | Expected outcome | Covers |
|---|---|---|---|---|---|
| Failure path intact | error | Example home source and existing failure expectations | Review failure text and navigation rules | Failure prefix remains Could not open runtime:; Snake navigation stays outside the failure path | R-004, AE-003 |
| Public signatures closed | edge | Library public open and predict entry points | Diff or source review for this slice | No new progress parameter, callback, or signature change on open or predict | R-005, AE-004 |

## Interfaces and shared decisions

- Status label text is exactly Loading the model, English only for this slice.
- Opening… stays; the new label is an addition beside it in the same opening branch.
- Progress UI is indeterminate: no value, no percent string, no timer that fakes advancement.
- Gate remains the existing private opening flag; no second loading flag.
- Public library open and predict stay closed; no download-byte instrumentation.
- goal_check remains null; Snake rules and the no-step-timer assumption stay closed.
- Accessibility naming beyond the fixed English label is not decided here and must not block shipping the label and meter.
- Wall-clock split of open phases and Hugging Face content-length reliability are accepted limits, not interfaces to invent.

## Risks

| Risk | Likelihood | Impact | Mitigation | Trigger that means it happened |
|---|---|---|---|---|
| A test asserts only Loading the model and drops Opening… | medium | Breaks the autostart chrome lock | Keep Opening… assertions and treat the new label as additive | Source or widget test no longer requires Opening… |
| Implementer adds a valued or animated fake percent | medium | Lies about progress and violates shared decisions | Criteria forbid a numeric fraction and a timer-driven percentage | Meter shows a percent or advances on a wall-clock fake |
| Scope creeps into library progress callbacks | low | Reopens closed public signatures | U2 and R-005 forbid signature changes | open or predict gain a progress parameter |
| Reviewer treats VM absence of session-load proof as a defect | low | False validation FAIL | Cite the macOS session-sandbox solution; keep checks at example chrome level | Validator demands integration_test for this chrome-only slice |

## Rollback

Revert the example home chrome additions and any test updates for this slice. No data migration and no library API change. Safe two-way door.

## Out of scope

- Numeric or phase progress from download or session create
- Public library API changes
- Changing Opening…, failure prefix, or success navigation rules
- Snake gameplay, step timer, or model predict behaviour
- Measuring wall-clock split of open phases
- Verifying Hugging Face content-length headers
- Accessibility semantics beyond showing the fixed English label
- Host integration tests that prove native session load
- Any goal success check (goal_check stays null)

## Verification approach

Run the example widget and source tests that cover idle absence, additive opening chrome, failure prefix, and success-only navigation. Run format and analyze on the touched example surfaces as required by repository checks. Do not treat VM flutter test as proof that ONNX session create completed; that remains outside this slice per the macOS session-sandbox solution.
