# Repository workflow

- After each completed code update, run the relevant checks, commit the changes,
  and push to the configured GitHub remote. The user has explicitly authorized
  this workflow; do not ask for confirmation again for routine commits and pushes.
- Report the pushed branch and commit. If a push fails, say so clearly and retain
  the local commit for retrying. Never force-push or overwrite unrelated changes.
- Keep local backups and generated scratch artifacts out of commits.
- Treat shared addon changes as class-wide. For changes to rotations, buff
  upkeep, build recommendations or talent effects, run
  `node tests/RunClassCoverageTests.cjs`. Distinguish simulated coverage from
  behavior actually checked in the live game client.
