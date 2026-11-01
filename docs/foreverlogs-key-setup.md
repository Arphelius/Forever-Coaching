# Local Forever Logs key

Paste the API key alone on a single line in:

`.local/foreverlogs-api-key.txt`

Save the file, then run `Preview-Addon.cmd` again. The launcher detects changes
to the key file and restarts the helper. Player search verifies the configured
key automatically on the first request. `events:read` is required.

The file is excluded from Git and lies outside the addon/package source folder.
It is a local plaintext configuration file, not an encrypted credential store.
The key is never sent to the browser, embedded in the addon, or bundled in ZIPs.
An existing `FOREVERLOGS_API_KEY` environment variable takes precedence.

The player interface has no Owner tools button or key-entry form. Existing raw
report endpoints still require a separately authenticated owner session; putting
the key in this file does not grant browsers administrative access.

Forever Logs is the current external log source through the local helper. This
does not provide a live combat stream or a hosted service for other machines.
