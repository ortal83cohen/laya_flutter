# Acceptance criteria: Start the example Snake game without a play button

## Frozen

- Frozen at: 2026-09-27
- Frozen by: orchestrator, at the start of implementation

## Criteria

| ID | Traces | Criterion | How it is checked | Negative case |
|---|---|---|---|---|
| AC-001 | R-001 | When the example is launched with production entry settings, the home shall not show a play button and shall begin opening the runtime so the existing opening label appears before a successful navigation to Classic Snake. | Launch or inspect the production entry path: no play-button label; opening label appears while open is in progress; Snake screen is reached after a successful open on a host that can load a session. | A play button remains the only start control, or Snake appears without the opening path having run, or the opening label never appears while open is still in progress. |
| AC-002 | R-002 | When production autostart open fails, the home shall show the existing open-failure text and shall not present the Classic Snake screen. | Force or simulate open failure on the autostart path and observe the home. | Failure shows new predict-failure chrome, shows no failure text, or navigates to Snake anyway. |
| AC-003 | R-003 | When the example root is built with the default autostart setting, a single widget-test pump of that tree shall not show the opening label. | Run the example widget test that pumps the default root and asserts the opening label is absent. | The pump shows the opening label, or the test requires a native ONNX plugin to complete. |
| AC-004 | R-003, R-004 | When the example root is built with the default autostart setting, a single widget-test pump shall show the Laya title and shall not require a Play Snake label. | Same widget test: find Laya; do not assert Play Snake as present. | The idle pump fails because Play Snake is missing, or the Laya title is absent. |
| AC-005 | R-004 | When autostart is off, mounting the example home alone shall not open an ONNX session. | Default-off construction plus pump; no session-open side effect required; opening label absent. | Mounting the default tree schedules open or shows the opening label without any further start action. |

## Non-functional criteria

| ID | Traces | Criterion | How it is checked | Negative case |
|---|---|---|---|---|
| AC-006 | R-003 | When verifying this slice, VM flutter test shall remain sufficient for the idle-pump contract and shall not be treated as host session-load proof. | Confirm verification uses the example widget test for AC-003 through AC-005 and does not claim a real session from that run. | A reviewer treats a green VM widget test as proof that an ONNX session loaded. |

## Explicitly not required

- A play button or any other manual start control on the production path.
- Retaining the Play Snake assertion in the widget test.
- Changes to library open or predict.
- Changes to Snake rules, relative turns, step gating, or pacing bans.
- New predict-failure UI.
- Opening the session before runApp.
- A test-harness environment signal.
- A second application root.
- Goal advances SC-003 or SC-005; goal_check stays null.
- Updating the classic Snake example product note during implement (document phase).

## Verdict log

| Round | Date | Verdict | Report |
|---|---|---|---|
