# Addon languages

English is the default, independently of the game client's locale. The addon
offers Romanian, Spanish, French, German and Portuguese through **Language** in
the dashboard sidebar. `/fclanguage` opens the same menu; `/fclanguage en`, `ro`,
`es`, `fr`, `de` or `pt` switches directly. The choice is saved in
`ForeverCoachingDB.settings.language` and applies without reloading.

The browser preview has its own Language selector and saves its preference in
local storage. This does not alter the installed addon's preference.

Only addon-owned displayed text is translated. Class, specialization, spell and
talent names are protected using the spell catalogue and talent layouts. User
input, exported data, URLs, IDs and native game tooltips remain unchanged.
Translations do not change spell logic, build identities, API calls or saved
combat data. Missing translation entries retain their English source text.

Translation sources are maintained in `localization/messages.tsv`. Each row has
six tab-separated fields: English, Romanian, Spanish, French, German and
Portuguese. Preserve named game terms and format placeholders in every column.
Run `node tools/Build-Localization.cjs` to validate the table and generate the
addon's Lua dictionaries and the browser's JavaScript dictionaries together.
Run `node tests/Localization.Tests.cjs` after editing translations.
