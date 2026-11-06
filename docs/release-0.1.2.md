# Forever Coaching 0.1.2

- Restored client-specific addon discovery manifests in the release ZIP.
- Included default, Forever and Camelot manifests with identical versions and load lists.
- Packaging now rejects missing or mismatched discovery manifests.

Install the complete ForeverCoaching folder in the Forever client's Interface/AddOns
directory, then fully exit and restart WoW so it rescans the addon list.
This fixes a packaging omission; in-game discovery still needs confirmation in
the client. Warcraft Logs recording and review features are unchanged.
