# Forever Coaching 0.1.1

- Removed the live rotation engines, icon strip, action-button highlights and rotation settings.
- Integrated Warcraft Logs controls directly into Combat Review, with logging controls, manual imports and fight navigation in one dashboard.
- Added external analysis tools for completed boss attempts in a supplied Warcraft Logs report, with timestamped observations and conservative comparisons against compatible verified 100-percentile parses.
- Preserved talent inspection, local fight recording and Combat Review.

Warcraft Logs uploads and analysis happen outside WoW. Detailed reviews require
an uploaded report, external API analysis and manual import. No automatic website
connection is included. Live API access and game behavior require further
verification; automated checks use simulated events and UI frames.

Package: dist/ForeverCoaching-0.1.1-forever.zip
Game: WoW Forever 1.60.1 (Interface 16001).
The package excludes personal imported reviews and API credentials.

Validation: Warcraft Logs integration tests, class coverage, reading-page layout
and the combat-only review flow passed. These do not replace live-client testing.
