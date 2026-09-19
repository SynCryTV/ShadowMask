# ShadowMask

Retail WoW streamer-privacy addon. ShadowMask replaces character names with stable session aliases, masks your own name, and hides selected player nameplates.

Incoming protection is configurable independently: ShadowMask can block all incoming whispers, decline all group invitations, and decline every duel request. It does not build or save a player-name list from chat.

## Install

Download `ShadowMask-<version>.zip` from GitHub Releases, extract it into `World of Warcraft/_retail_/Interface/AddOns/`, then reload the game. The ZIP already contains the required `shadowmask` addon folder.

For a local build, run `./tools/package.ps1`. The script reads the version from `shadowmask/ShadowMask.toc`; the finished archive is written to `dist/`.

## Commands

`/sm toggle` enables or disables masking.

`/sm block Name` blocks a name (chat is suppressed; invitations are declined).

`/sm trust Name` leaves a name visible.

`/sm alias Streamer` changes the alias used for your own character.

Aliases never contain spaces so they remain compatible with unit-frame and chat addons. For example, the default group aliases are `Player01`, `Player02`, and so on.

`/sm options` opens the ShadowMask settings page. It provides immediate controls for every privacy switch, alias format, and the account-wide block and trust lists.

`/sm minimap` shows or hides the minimap button. Like Mimorium's button, it is fixed beside the minimap; left-click opens settings and right-click hides it.

## Compatibility

ShadowMask includes adapters for **DandersFrames** and **EllesmereUI**. It only replaces visible `FontString` label text and does not alter secure unit-frame attributes, so it remains safe around combat lockdown. DandersFrames is supported through its exposed frame API, with a fallback for older releases. EllesmereUI support is defensive because enabled modules vary by profile.

The DandersFrames adapter also masks the player frame embedded in its party header.

EllesmereUI's own unit-name resolver is wrapped so player, target, focus, pet, target-of-target, focus-of-target, and boss frames receive aliases during their normal render pass, without a visible real-name flash.

Hostile player units are deliberately left unchanged in unit frames; only friendly and group units are masked there.

Visible player-name text is also masked in unit tooltips, the character and inspect windows, and Blizzard or addon frames that use regular FontString labels. Global-chat authors are replaced with a generic alias without being cached or stored; the temporary display cache is rebuilt only from currently visible units.

Midnight marks some combat UI text and frame state as protected secret values. ShadowMask deliberately avoids scanning arbitrary Blizzard frames and uses explicit hooks for the character window, inspect window, unit frames, and unit tooltips instead, preventing UI errors while masking supported name displays.

The complete UnitName line is removed from player tooltips before they render. NPC tooltip titles are never changed.

For EllesmereUI group-frame tooltips, ShadowMask also resolves the active group unit through the tooltip GUID when the normal unit token is protected.

The level of an incoming inviter is not reliably supplied by the WoW invitation event. Therefore, the initial version can automatically decline names already on the block list; a low-level rule can be added only for characters whose level has been observed and cached while grouped.

## Release workflow

Every push to `main` reads `## Version` from `shadowmask/ShadowMask.toc`. If that version does not already have a matching `v<version>` tag, GitHub Actions packages the addon, creates the tag and GitHub Release, then attaches the ZIP. Bump the TOC version before a release; ordinary pushes with an already released version do nothing.
