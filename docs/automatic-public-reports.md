# Automatic public report updates

One-time setup (PowerShell):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'D:\Forever coaching Addon\Forever-Coaching\tools\Enable-AutomaticPublicReports.ps1'
```

Enter your Warcraft Logs client ID and secret locally if prompted. Setup encrypts the secret using Windows DPAPI, bound to your Windows account/computer, in the ignored `.local/optimization/automatic-credentials.xml`. Credentials are never included in addon releases or Git commits. Setup requires Windows Task Scheduler and Node.js.

The `ForeverCoaching-PublicReports` scheduled task runs hidden while you are signed into Windows. It checks every four hours, and resumes unfinished request batches every 15 minutes. HTTP rate limits wait at least an hour before retrying. The task uses your normal user permissions and ignores overlapping invocations.

The updater queries the public API's All Dungeons zone (3000), follows available pages, retains previously discovered report codes and includes your saved HTML pages. Each new cycle refreshes discovery rather than reusing a seven-day-old listing. API visibility may differ from the website; this is not a guarantee of every website report or a global ranking. Listing, report and page limits are disclosed in the status log. In-progress/unsupported/unrankable runs remain excluded.

Completed catalogs are written to the source addon and `D:\World of Warcraft\_forever_\Interface\AddOns\ForeverCoaching`. Failed or interrupted collection preserves the existing catalog. Run `/reload` in WoW after a successful update. This updates your installation; it does not publish releases to CurseForge or update other players automatically.

Status: `.local/optimization/automatic-update.log` and `automatic-state.json`. `lastSuccess` and `nextCheckAt` are Unix timestamps in milliseconds. A successful run ends with `Catalog saved`.

Stop automatic updates:

```powershell
Unregister-ScheduledTask -TaskName 'ForeverCoaching-PublicReports' -Confirm:$false
```

To remove the stored credentials as well, delete `.local/optimization/automatic-credentials.xml`. To change credentials or the interval, rerun setup (optional `-Hours 1` through `-Hours 24`).

API reference: https://www.warcraftlogs.com/v2-api-docs/warcraft/reportdata.doc.html
