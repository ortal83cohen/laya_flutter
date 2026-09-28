---
id: release-pipeline
title: Release pipeline operator gates
status: active
owner: unassigned
last_verified: 2026-09-28
applies_to: [".github/workflows/release.yml", ".github/workflows/publish.yml", "tools/bump_patch_version.sh"]
summary: The three human prerequisites that make the automated pub.dev release work, the pub.dev permanence constraint, and which changelog notes a deploy publishes.
---

# Release pipeline operator gates

Every push to `main` bumps the patch version and publishes the package to pub.dev. The
mechanics live in the two workflow files and the bump helper; this document records only the
things an agent cannot learn by reading them.

## Why the release is split across two workflows

Pub.dev accepts an automated publish only from a workflow run that a git tag push started, and
it rejects a run triggered by anything else. A branch push therefore cannot publish, no matter
how it authenticates. That single external rule is why `release.yml` bumps and tags while
`publish.yml` publishes, and why the tag must be pushed with a token that can start workflow
runs: events created with the default Actions token do not start new runs, so a tag it pushed
would never reach `publish.yml`.

For the same reason, no commit message this automation writes may carry one of GitHub's
bracketed workflow-skip instructions. The annotated tag points at the release commit, so such
an instruction on that commit risks suppressing the publish run itself. Whether GitHub applies
a skip instruction to a tag-ref push is undocumented and untested here; the design avoids the
question rather than betting on it. Loop protection is the job-level condition on the release
commit message prefix instead, and it cannot be replaced by comparing the triggering actor
against the Actions bot: a push made with a personal access token reports the token owner.

## The three operator prerequisites

None of these lives in the repository, and the first release attempt is what proves the second
and third.

1. **Automated publishing enabled on pub.dev.** On the package admin tab, publishing from
   GitHub Actions must be enabled for repository `ortal83cohen/laya_flutter` with tag pattern
   `v{{version}}`. That pattern must stay aligned with the tag filter in `publish.yml`; if they
   diverge, the tag lands and the publish run fails on authentication.
2. **A `RELEASE_GITHUB_TOKEN` repository secret.** A personal access token or GitHub App
   installation token with write access to repository contents. The release job's first step
   fails when it is empty, before checkout and before any git write, so a missing secret cannot
   leave a half-applied bump behind.
3. **Branch protection on `main` that permits that token to push.** The release commit is pushed
   before the tag, so a protected-branch rejection publishes nothing.

## What cannot be undone

A pub.dev version is permanent. Version 0.1.0 is already published and can never be reused; the
first version this automation can produce is 0.1.1. Deleting the workflow files stops future
releases but removes nothing already uploaded, so each release is a one-way door. Retraction
exists as a pub.dev feature but this repository builds no path for it.

Because the release job runs the full check suite before it tags, a repository state that fails
that suite cannot produce a release at all.

## Which notes a deploy publishes

On deploy, if `CHANGELOG.md` has exactly one line equal to `## Unreleased` and that span has
hyphen-space bullets, those bullets and their immediate whitespace wrap lines become the new
version's notes. The heading stays, without those bullets.

If that heading is missing or the span has no hyphen-space bullet, the new version still gets
the sentence "Automated patch release from main."

Two exact Unreleased headings fail the bump and write neither file.

Already numbered changelog sections are not rewritten by the helper. The next real deploy is
what moves the current Unreleased notes.
