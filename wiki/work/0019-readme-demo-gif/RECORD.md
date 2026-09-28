# README uses the current demo recording

The README now shows a GIF made from the demo recording in the project root. The GIF uses the
longest practical duration while keeping dimensions, frame rate, and palette optimized for a
GitHub README.

## Files

`README.md` and `screenshots/example.gif`.

## Qualifying conditions

1. The change is limited to one user-facing README reference and its media asset.
2. No dependency, public interface, schema, data model, security, or privacy surface changes.

## Checks

`ffmpeg` converted the full 50.30-second source at 12 fps and 480 pixels wide. The resulting looping GIF is 1,878,948 bytes (about 1.8 MiB). `ffprobe` reports 50.34 seconds. `git diff --check` passed.

The full repository check suite has not been run.
