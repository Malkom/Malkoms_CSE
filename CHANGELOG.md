# Changelog

## 1.5.0
- Fixed the button sticking to the cursor when moved (the stop call used the wrong API name; it now stops reliably in every theme).
- New **Visibility** options: show the button in Open World / Dungeons (incl. Delves) / Raids.
- More spacing between options; option checkboxes sized to match Malkoms DataBroker.
- Localization moved to per-language files under `Locales/` (enUS, frFR).

## 1.4.0
- First public release.
- Movable/resizable button showing the icon of the currently equipped equipment set.
- Hidden automatically when no set is equipped.
- Live theming: Default / ElvUI / Masque (auto-fallback to Default).
- Options (Blizzard Settings API + `/mcse`): lock, keep aspect ratio, width/height,
  opacity, frame strata, set-name label (show, position, X/Y offset, font, size, outline).
