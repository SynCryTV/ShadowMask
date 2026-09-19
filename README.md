# ShadowMask

Retail WoW streamer-privacy addon. ShadowMask replaces character names with stable session aliases, hides blocked players' chat, masks your own name, and can decline invitations from names on its account-wide block list.

## Install

Download `ShadowMask-<version>.zip` from GitHub Releases, extract it into `World of Warcraft/_retail_/Interface/AddOns/`, then reload the game. The ZIP already contains the required `shadowmask` addon folder.

For a local build, run `./tools/package.ps1 -Version 0.1.0`. The finished archive is written to `dist/`.

## Commands

`/sm toggle` enables or disables masking.

`/sm block Name` blocks a name (chat is suppressed; invitations are declined).

`/sm trust Name` leaves a name visible.

`/sm alias Streamer` changes the alias used for your own character.

`/sm options` opens the ShadowMask settings page. It provides immediate controls for every privacy switch, alias format, and the account-wide block and trust lists.

The minimap button opens settings with a left-click, toggles masking with a right-click, and can be dragged. It can also be hidden in the settings page.

## Compatibility

ShadowMask includes adapters for **DandersFrames** and **EllesmereUI**. It only replaces visible `FontString` label text and does not alter secure unit-frame attributes, so it remains safe around combat lockdown. DandersFrames is supported through its exposed frame API, with a fallback for older releases. EllesmereUI support is defensive because enabled modules vary by profile.

The level of an incoming inviter is not reliably supplied by the WoW invitation event. Therefore, the initial version can automatically decline names already on the block list; a low-level rule can be added only for characters whose level has been observed and cached while grouped.

## Release workflow

Pushing a tag such as `v0.1.0` runs the GitHub Actions release workflow. It packages the addon and attaches the ZIP to a GitHub Release, which provides a stable downloadable release asset for update clients that support GitHub releases.
