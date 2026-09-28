# Plan: Start the example Snake game without a play button

## Goal

A person who launches the example with production settings reaches Classic Snake without pressing a
play button: the home starts the existing open path, shows the existing opening and open-failure
text, and navigates to Snake after a successful open. A VM widget test that pumps the example root
with the default (autostart off) still does not open an ONNX session and still does not show the
opening label.

## Approach

Keep a single example root. Add an explicit autostart flag on that root widget, defaulting to off so
a bare construction matches today’s idle pump. Production process entry constructs the root with
autostart on. The home receives that flag and, when it is on, starts the same open-then-navigate
path that the play button used, without presenting a play control. When the flag is off, the home
stays idle for session open: mounting alone does not call open.

Leave the library and the Snake screen and controller untouched. Leave process entry synchronous: do
not await open before runApp. Do not introduce an environment or harness signal that skips open. Do
not add a second root for tests.

Update the example widget test so it still pumps the default root, still asserts the Laya title and
the absence of the opening label, and no longer asserts the Play Snake label. The product note that
today ties idle safety to a user button is rewritten in the document phase so the lasting rule is
the VM pump contract, not a play control.

## Why this approach

Research chose an explicit autostart flag with default off and production entry turning it on.
Opening in process entry before the widget tree was rejected because failure handling and opening
text already live on the home and the entry would become asynchronous. Always-autostart plus a
test-harness signal was rejected as less explicit than a constructor flag. Two roots were rejected
for drift cost. Unguarded mount-time open of the pumped widget was rejected because it breaks VM
widget tests that only pump that tree. Keeping the play button was rejected because the request is a
launch with no button. Calling open from the pumped tree with a stub was rejected because the test
forbids the opening label and the requirement is that the pump does not open a session. See
wiki/work/0005-autostart-snake/00-research.md.

## Product contract

Units realise R-001 through R-004 in wiki/work/0005-autostart-snake/04-product-contract.md. This
plan adds no behaviour that contract does not state.

## Units

### U1. Autostart flag on the example root

Done when: the example root widget exposes an explicit autostart setting that defaults to off; the
home can observe that setting; with the default, constructing and pumping the root does not start
session open or show the opening label; with the setting on, the home begins the existing open path
without a play button.

Files it may touch: example application main source (example root and home only).

| Scenario                         | Category   | Input                             | Action                                   | Expected outcome                                                                                                                                                                              | Covers               |
|----------------------------------|------------|-----------------------------------|------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------|
| Default stays idle               | happy path | Root built with default autostart | Single pump                              | Laya title present; opening label absent; no session open started                                                                                                                             | R-003, R-004, AE-003 |
| Autostart begins open            | happy path | Root built with autostart on      | Pump and settle enough to observe chrome | Play button absent; opening label appears while open is in progress; after a successful open the home navigates to Snake; if open fails, existing failure text appears and Snake is not shown | R-001, R-002, AE-001 |
| Mount alone never opens when off | edge       | Root built with autostart off     | Pump without further gestures            | No opening label; home does not navigate to Snake                                                                                                                                             | R-004                |

### U2. Production entry enables autostart

Done when: the process entry that launches the running example constructs the root with autostart
on, still calls runApp without awaiting open first, and does not introduce a second root or a
harness environment signal.

Files it may touch: example application main source (process entry and root construction only).

| Scenario                      | Category   | Input                       | Action                           | Expected outcome                                                          | Covers        |
|-------------------------------|------------|-----------------------------|----------------------------------|---------------------------------------------------------------------------|---------------|
| Production path turns flag on | happy path | Process entry as shipped    | Inspect construction of the root | Root is created with autostart on; runApp is not preceded by session open | R-001         |
| Open failure stays on home    | error      | Autostart on and open fails | Observe home after failure       | Existing open-failure text shown; Snake not presented                     | R-002, AE-002 |

### U3. Widget test matches the default pump contract

Done when: the example widget test pumps the default root, asserts the Laya title, asserts the
opening label is absent, and does not assert a Play Snake label.

Files it may touch: example widget test.

| Scenario                         | Category   | Input              | Action                      | Expected outcome                                             | Covers               |
|----------------------------------|------------|--------------------|-----------------------------|--------------------------------------------------------------|----------------------|
| Idle pump without play assertion | happy path | Default ExampleApp | pumpWidget and expectations | Laya found; Opening label not found; Play Snake not required | R-003, R-004, AE-003 |
| Opening label still forbidden    | negative   | Default ExampleApp | pumpWidget                  | Finding the opening label fails the test                     | R-003                |

## Interfaces and shared decisions

- Autostart lives on the example root widget (ExampleApp), not on a second root and not as a
  process-wide environment signal. Name it in words as an autostart flag. Default is off.
- The home receives that flag from the root. When true, it starts the existing open-then-navigate
  path once after mount (or equivalent single trigger that is not a user play button). When false,
  that path runs only if a later explicit control exists; this slice’s default-off tree need not
  keep a play button.
- Production process entry passes autostart on when constructing the root. Widget tests and any bare
  construction omit the flag and get off.
- Opening label text and open-failure text stay the existing strings on the home. No new
  predict-failure UI.
- Library open signature and Snake screen or controller behaviour are out of this slice’s edit set.
- Document-phase (not implement): update the classic Snake example product note so the lasting VM
  rule is that the pumped tree does not open a session, replacing the “user starts Snake” wording.

## Risks

| Risk                                                                                                | Likelihood | Impact                                                                      | Mitigation                                                                                                                                      | Trigger that means it happened                                                                    |
|-----------------------------------------------------------------------------------------------------|------------|-----------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------|
| Autostart schedules open in a way that still runs during a default-off pump after a future refactor | Low        | VM widget tests break with MissingPluginException or show the opening label | Keep default off as the only path the widget test pumps; assert opening label absent                                                            | Widget test fails on pump with plugin or opening label                                            |
| Removing the play button leaves no recovery after open failure                                      | Low        | User stuck after a failed open with only failure text                       | Keep existing failure text visible; open path remains retriable if a later slice adds a control, but this slice does not require a retry button | Open fails and no failure text appears                                                            |
| Accidental edit to Snake screen or library while wiring navigation                                  | Low        | Reopens closed assumptions                                                  | Prefer touching only example main and the widget test                                                                                           | Diff includes lib or snake_screen or snake_controller without a compile-forced comment-only touch |

## Rollback

Revert the example main and widget test changes. The previous idle home with Play Snake returns. No
data migration and no one-way door. The document-phase product note edit, if already applied, is
reverted or superseded in the same rollback.

## Out of scope

- Any change under the package library sources.
- Changes to the Snake screen or Snake controller except a compile-forced comment-only touch, which
  should be avoided.
- Opening the session before runApp.
- Test-harness environment signals.
- A second application root.
- New predict-failure UI.
- Claiming SC-003 or SC-005; goal_check remains null.
- Proving a real ONNX session via VM flutter test (belongs on macOS integration_test per the sandbox
  solution).
- Rewriting the classic Snake example product note during implement; that update is document phase.

## Verification approach

Run the example widget test with flutter test on the example package and confirm the default pump
finds Laya, finds no opening label, and does not need a Play Snake assertion. Review the example
main source for: autostart default off on the root, production entry passing autostart on, no open
before runApp, no harness environment skip, play button absent on the autostart path, and reuse of
existing opening and open-failure text. Do not treat VM flutter test as session-load proof. Manual
or host launch of the production entry confirms no play button and that Snake appears after a
successful open when a host session is available.
