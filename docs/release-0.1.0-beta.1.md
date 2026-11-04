# Forever Coaching 0.1.0-beta.1

Initial public beta for WoW Forever 1.60.1 (Interface 16001).

- Updated spell catalog, talent layouts, adapted talent plans, and tuning checks.
- Added Wowhead Forever custom talent import/export and guide references.
- Added profession guides and optional inventory-aware crafted-item suggestions.
- Preserved compact native UI, class/spec browsing, localization, and combat reviews.

Installed Forever client detected during packaging: 1.60.1.70790. Reviewed gameplay data: 1.60.1.70753, November 3. Automated checks do not replace in-game launch testing.

## CurseForge submission

Create or select a World of Warcraft addon project named **Forever Coaching**. Use `docs/curseforge-description.md` as the description, link this repository for source/issues, and choose the applicable project license. No project-wide license has been selected in this repository; do not claim MIT ownership of third-party artwork or data.

Upload `dist/ForeverCoaching-0.1.0-beta.1-forever.zip`, select **Forever / 1.60.1**, and mark the file **Beta**. Use the notes above as the changelog. CurseForge account/project access is required to submit it and moderation may precede publication.

Rebuild with `powershell -NoProfile -ExecutionPolicy Bypass -File tools/Package-ForeverRelease.ps1`.
