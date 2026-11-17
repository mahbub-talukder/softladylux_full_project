# SRS amendment v1.9 (draft, owner request of 2026-11-17)

**Status:** approved by the owner 2026-11-17 and applied to `SRS.md` v1.9. This file is the change record.

Owner request: in Admin → Theme, next to the colour palettes, choose the font family pairing for the storefront and,
separately, for the admin panel, and change either at any time.

---

## 1. Scope (changes §1.3, THM-15)

- **§1.3 out of scope.** Remove "owner-editable fonts". Font *pairings* from a fixed catalogue are now in scope.
  Uploading custom font files and choosing arbitrary Google Fonts stay out of scope.
- **THM-15 (replaces).** Out of scope for v1: a visitor-facing dark-mode toggle, custom or uploaded fonts (only the
  THM-20 catalogue), per-category or per-page colours or fonts, scheduled seasonal themes.

## 2. Requirements (new THM-20..THM-26)

- **THM-20 Font pairing catalogue.** A fixed catalogue of 9 pairings (heading font + body font), all from Google
  Fonts, defined once on the server and returned by the theme API. The frontend never keeps its own copy.

  | Key | Label | Heading | Body |
  |---|---|---|---|
  | `signature` | Signature (default) | Cormorant Garamond | Jost |
  | `editorial` | Editorial | Playfair Display | Inter |
  | `modern` | Modern | Montserrat | Open Sans |
  | `friendly` | Friendly | Poppins | Roboto |
  | `classic` | Classic | Lora | Source Sans 3 |
  | `bookish` | Bookish | Merriweather | Lato |
  | `boutique` | Boutique | DM Serif Display | DM Sans |
  | `elegant` | Elegant | Libre Baskerville | Nunito Sans |
  | `clean` | Clean | Inter | Inter |

  Each entry carries its key, label, heading family and weights, body family and weights, a CSS fallback stack
  (serif or sans-serif) for each, and its Google Fonts stylesheet URL (`display=swap`). `signature` reproduces the
  current design (THM-13).
- **THM-21 Two separate selections.** The owner picks one pairing for the **storefront** (all public pages,
  checkout, account area and printed customer documents) and one for the **admin panel**. Each can change at any
  time without affecting the other.
- **THM-22 Font tokens.** Fonts are exposed as CSS custom properties `--font-display` (headings) and `--font-sans`
  (body text, buttons, inputs). Storefront values are set on `:root`; admin values override them inside the admin
  panel. No other place names a font family (same rule as THM-01 for colours).
- **THM-23 Delivery without flash.** The Nuxt server writes the font tokens and one Google Fonts stylesheet link per
  area (with preconnect) into the page head at render time, the same way as colours (THM-06). Only the selected
  pairing's fonts are requested: unselected pairings are never downloaded.
- **THM-24 Fonts section on the Theme screen.** Beside the palette gallery: two selectors, Storefront and Admin
  panel. Each option shows a live sample in its own fonts (an "Aa" heading and one body sentence) and its name.
  Save and Reset fonts use the same confirmations and success/error messages as the palette section.
- **THM-25 Validation, permission and audit.** Only catalogue keys are accepted (anything else is a 400 with a field
  message). Changing fonts needs `theme.manage` (THM-09). Every font change is audited with the old and new keys,
  like colour changes (THM-10).
- **THM-26 Defaults and reset.** Both selections default to `signature`, and the existing theme record is set to
  `signature` for both when this change is deployed, so nothing changes visually. **Reset fonts** restores
  `signature` for both. The general theme **Reset** (`theme/reset/`) restores the default colours and the default
  fonts together.

## 3. Data model and API (changes §6, §7)

- **§6 `core_themesettings`** adds `storefront_font` and `admin_font` (varchar 20, catalogue key, default
  `signature`).
- **§7 public `GET theme/`** adds `fonts: {storefront, admin}`, each `{key, display, sans, stylesheet}`. The
  admin pairing is included because the admin login page renders before anyone signs in; storefront pages still
  load only the storefront stylesheet (THM-23).
- **§7 admin `theme/` (GET, PUT)** adds `storefront_font`, `admin_font` and `font_pairings` (the THM-20 catalogue,
  read-only). PUT accepts either font key on its own, so fonts can be saved without resending the colours.
  `theme/reset/` also resets both fonts (THM-26).
- **§9 performance.** At most one font stylesheet per area per page. The storefront never loads the admin pairing.

## 4. Acceptance scenarios (§12, new)

41. The owner sets the storefront fonts to Editorial and saves. After reload, home page headings use Playfair Display
    and body text uses Inter. The admin panel still uses its own pairing, and no stylesheet for any other pairing
    is requested.
42. The owner sets the admin panel fonts to Clean. Admin headings and text use Inter, and the storefront is
    unchanged.
43. Saving `storefront_font = "comic"` is rejected with 400 and a field message. A Staff user without
    `theme.manage` gets 403. A valid change is in the audit log with the old and new keys.
44. Reset fonts (or the general theme Reset) returns both selections to Signature, and the storefront again looks
    like the original design.
45. The first server-rendered HTML of a storefront page already contains the selected font tokens and the matching
    stylesheet link, so the page does not flash in the old font.

## 5. Traceability and files

- Backend: `apps/core/theme.py` (catalogue, validation, payloads), `apps/core/models.py` + migration, theme
  serializers and views in `apps/core`, tests in `apps/core/tests`.
- Frontend: `assets/css/main.css` (static font import removed), `tailwind.config.ts` (font families read the CSS
  variables), `plugins/theme.server.ts` / `theme.client.ts` and `utils/theme.ts` (tokens and stylesheet links),
  `pages/admin/theme.vue` (Fonts section), `types`, vitest for the token and link builder.
- No new dependencies and no self-hosted font files.
