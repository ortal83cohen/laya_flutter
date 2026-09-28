# Tasks: Start the example Snake game without a play button

## Legend

- `[P]` — may run in a parallel subagent. Only mark a task `[P]` if no other `[P]` task in the same
  group touches any of the same files.
- Every task cites the criteria it satisfies and the unit (`U1`, `U2`) it completes. A task
  satisfying no criterion does not belong here.
- Owned files are exclusive. Two tasks never list the same file.

## Groups

Groups run in sequence. This work item has one group and one task, because the example root and the
widget test describe the same autostart contract.

### Group 1 — Example autostart

| #   | Task                                                                                                                                                                                              | Satisfies                              | Files owned                                          | Parallel | Done when                                                                                                                                                                                                                                                                              |
|-----|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------|------------------------------------------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1.1 | U1, U2, U3. Add the autostart flag on the example root, turn it on from process entry, start the existing open path with no play button, and update the widget test to the default pump contract. | AC-001, AC-002, AC-003, AC-004, AC-005 | example/lib/main.dart, example/test/widget_test.dart |          | Default pump shows Laya and no opening label and does not require Play Snake. Production entry passes autostart on, does not open before runApp, and the autostart path has no play button, reuses opening and open-failure text, and navigates to Snake only after a successful open. |

## Serialised files

| File                          | Owning task |
|-------------------------------|-------------|
| example/lib/main.dart         | 1.1         |
| example/test/widget_test.dart | 1.1         |

## Test tasks

| #    | Covers                 | Positive case                                                                                                                                                                                                                               | Negative case                                                                                                   |
|------|------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|
| 1.1a | AC-003, AC-004, AC-005 | Pump the default root. Laya is present. Opening label is absent. Play Snake is not required.                                                                                                                                                | A pump that shows the opening label, or a test that fails because Play Snake is missing, fails the criterion.   |
| 1.1b | AC-001, AC-002         | Production entry constructs the root with autostart on. The autostart path shows no play button, uses the existing opening label, navigates to Snake after success, and shows the existing open-failure text without Snake when open fails. | A remaining play button as the only start control, or navigation to Snake when open fails, fails the criterion. |
