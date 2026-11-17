# SRS amendment v1.10 (draft, owner request of 2026-11-17)

**Status:** approved by the owner 2026-11-17 and applied to `SRS.md` v1.10. This file is the change record, including
the implementation and verification plan in §5–§6.

Owner request: different fonts need different sizes. Tune each font pairing automatically, and let the owner pick a
simple text size. Responsive design must not break on any screen.

---

## 1. What the audit found (2026-11-17)

**How text is sized today (frontend):**
- Headings use the shared scale in `tailwind.config.ts` (`text-h1` … `text-card`, about 100 uses).
- Tailwind rem sizes (`text-sm`, `text-xs` …) are used about 350 times.
- Fixed pixel sizes like `text-[15px]` are used about 210 times, plus a set in `assets/css/main.css` (admin
  tables, buttons, tabs).
- Conclusion: changing the root font size or the heading scale alone would miss most text. The adjustment has to
  work whatever unit a size uses.

**Layout that depends on text size:**
- About 139 fixed-height controls (buttons `h-11`/`h-12`/`h-14`, inputs `h-[46px]`).
- 60 fixed pixel widths, 106 custom letter-spacings (mostly uppercase labels), and 12 `whitespace-nowrap` spots.
  These include the header category bar, admin table headers, admin tabs and the floating cart.
- Product cards use `line-clamp` and `truncate`.
- The SSR breakpoints are Tailwind's defaults: sm 640, md 768, lg 1024, xl 1280.

**Measured font metrics** at the same font size, measured in the browser with the real Google Fonts (weight 500
for headings, 400 for body):

| Font | x-height | Heading width vs Cormorant | Body width vs Jost |
|---|---|---|---|
| Cormorant Garamond (today) | 0.39 | 1.00 | — |
| Jost (today) | 0.46 | — | 1.00 |
| Playfair Display | 0.52 | **+15%** | — |
| Montserrat | 0.54 | **+27%** | — |
| Poppins | 0.56 | **+24%** | — |
| Lora | 0.51 | +19% | — |
| Merriweather | 0.56 | +21% | — |
| DM Serif Display | 0.49 | +12% | — |
| Libre Baskerville | 0.53 | **+31%** | — |
| Inter (heading) | 0.54 | +20% | +13% |
| Open Sans | 0.55 | — | +9% |
| Roboto | 0.54 | — | +5% |
| Source Sans 3 | 0.49 | — | −3% |
| Lato | 0.52 | — | +1% |
| DM Sans | 0.51 | — | +9% |
| Nunito Sans | 0.50 | — | +5% |

So without tuning, a pairing like Elegant makes every heading about 31% wider than today. Headings would wrap onto
extra lines, and on a 360 px phone some words would not fit at all.

## 2. Approach

- **Tune with the CSS `font-size-adjust` property, not by changing font sizes.** It makes the browser draw each font
  at a chosen visual size while the element's *computed* font size, line height, paddings and fixed heights stay
  exactly as today. That means:
  - It reaches every text size (scale, rem, pixel, `main.css`) without touching the ~660 size declarations.
  - Button and input heights, line heights and `em`-based spacing don't move, so vertical layout can't break.
  - It applies to fallback fonts too, so a missing glyph never shows up oversized.
  - Browser support: Chrome/Edge 127+, Firefox, Safari 17+. An older browser simply ignores it and shows the
    untuned font, which is what v1.9 does today.
- **Match widths, not letter heights.** Each pairing gets a heading factor and a body factor, chosen so its text is
  **no wider than today's design** (factor = today's width ÷ font width, capped at 1.0). Text then wraps where it
  wraps today, which keeps every breakpoint as safe as the current site. The adjust value sent to the browser is
  `x-height × factor`.

## 3. Requirements (new THM-27..THM-31)

- **THM-27 Per-pairing tuning.** Every THM-20 pairing carries a measured x-height and a tuned factor for its
  heading font and its body font, defined on the server with the catalogue. Starting factors (to be confirmed by
  the visual review in §6):

  | Pairing | Heading factor | Body factor |
  |---|---|---|
  | signature | 1.00 | 1.00 |
  | editorial | 0.87 | 0.89 |
  | modern | 0.79 | 0.91 |
  | friendly | 0.81 | 0.96 |
  | classic | 0.84 | 1.00 |
  | bookish | 0.83 | 0.99 |
  | boutique | 0.89 | 0.92 |
  | elegant | 0.76 | 0.95 |
  | clean | 0.83 | 0.89 |

  `signature` sends no adjustment at all, so today's design is unchanged pixel for pixel.
- **THM-28 Text size choice.** Per area (storefront, admin panel), the owner picks **Compact**, **Standard**
  (default) or **Large**. The multipliers are:

  | Choice | Body | Headings |
  |---|---|---|
  | Compact | 0.94 | 0.94 |
  | Standard | 1.00 | 1.00 |
  | Large | 1.06 | 1.03 |

  Headings grow less than body text on Large because they already fill the narrow phone widths. The final adjust
  value is `x-height × pairing factor × size multiplier`. There are no free font-size fields.
- **THM-29 Font metric tokens.** Alongside `--font-display`/`--font-sans` (THM-22) the theme sends
  `--font-display-adjust` and `--font-sans-adjust`. Body text uses the sans value. Headings (h1–h4 and
  `.font-display`) use the display value. `.font-sans` inside a heading switches back to the sans value. Values are
  numbers 0.2–1.0, or `none`; the server computes them and the frontend only accepts numbers in that range.
- **THM-30 Theme screen.** The Fonts section gets a Text size selector per area. Each option's live sample uses its
  tuned adjustment and the selected text size, so the preview matches the site. Save and Reset fonts cover text
  size too. Reset returns to Standard.
- **THM-31 Responsive guarantee.** No pairing at any text size may:
  - cause horizontal page scrolling,
  - clip text,
  - push a control's label outside its box, or
  - make a single-line button or tab label wrap,

  at 360, 390, 768, 1024 and 1440 px on the pages listed in §6. Any failure is fixed in the component (for example
  letting a label wrap or scroll) or by lowering that pairing's factor. It is never accepted as is.

## 4. Data model and API (changes §6, §7)

- **§6 `core_themesettings`** adds `storefront_text_size` and `admin_text_size` (`compact` / `standard` /
  `large`, default `standard`). The pairing metrics live in the catalogue, not in the database.
- **§7 public `GET theme/`**: each `fonts.<area>` entry adds `display_adjust`, `sans_adjust` and `text_size`.
- **§7 admin `theme/`**: GET and PUT add `storefront_text_size`, `admin_text_size` and `text_sizes`, the list of
  choices with labels. They are validated and audited like the fonts (THM-25), and reset like THM-26.

## 5. Implementation plan

1. **Backend (`apps/core/theme.py`, model, views, tests).**
   - Add x-height and factor to each catalogue font, plus `TEXT_SIZES`.
   - Add a function that computes the two adjust values for a pairing and size, rounded to 3 decimals and
     clamped to 0.2–1.0.
   - Add the two text-size fields with a migration that clears the public cache (as in v1.9), and extend the
     payloads, validation, audit and reset.
   - Tests: values for every pairing and size, `none` for Signature Standard, invalid size → 400, audit and reset.
2. **Frontend.**
   - `utils/theme.ts` `fontToCss` also writes the two adjust variables, accepting only numbers 0.2–1.0 or `none`.
   - `assets/css/main.css`: `body { font-size-adjust: var(--font-sans-adjust, none) }`,
     `h1–h4, .font-display { font-size-adjust: var(--font-display-adjust, none) }` and
     `.font-sans { font-size-adjust: var(--font-sans-adjust, none) }`.
   - `pages/admin/theme.vue`: a Text size selector per area, with samples using the tuned values.
   - vitest for the CSS builder, including that unsafe values are rejected.
3. **Responsive audit script** (`frontend/scripts/typography-audit.js`, dev-only, runs in the browser console, no
   new dependency).
   - Loads each page of §6 in a same-origin iframe at each width.
   - Swaps in each pairing × size by writing the CSS variables and stylesheet into the iframe. Nothing is saved, so
     the live site is never touched.
   - Reports any page wider than the viewport, any element with clipped text (`scrollWidth > clientWidth` under
     `overflow: hidden/clip`), any `nowrap` text wider than its parent, and any single-line button, tab or chip
     label that wraps.
   - Run it before tuning to record today's baseline, so problems that already exist are listed separately and
     not blamed on fonts.
4. **Tune** factors that fail the audit (step size 0.01), and fix any component that already fails at Large
   with Signature. Fixes go in the component, keeping the THM-31 rule.

## 6. Verification plan

- **Pages, storefront:** home, category listing, product page, cart drawer and floating cart, checkout, track
  order, login/register, My account (orders tab), size guide, contact, search results, the customer invoice print
  page.
- **Pages, admin:** login, dashboard, orders list + order panel, product form, settings, theme, courier dashboard,
  delivery slip print page.
- **Widths:** 360, 390 (phones), 768 (tablet), 1024 and 1440 (desktop), including mobile menu and bottom nav at
  phone widths.
- **Combinations:** all 9 pairings × 3 sizes on every page and width (the script makes this practical:
  21 pages × 5 widths × 27 combinations).
- **Visual review:** before/after screenshots for each pairing at 390 and 1440 on home, product and checkout, sent
  to the owner before committing (§2 width matching keeps wrapping safe; the review checks the look).
- **Tests:** backend pytest with the route gate, ruff, vitest, eslint, `nuxi typecheck`.
- **Acceptance scenarios (new):**
  - 46. With Elegant, Standard, every storefront page at 360 px has no horizontal scroll and the home hero heading
    breaks onto the same number of lines as with Signature.
  - 47. Admin panel set to Large: tables, tabs and buttons keep their height and no label wraps at 1024 px.
  - 48. Signature + Standard renders exactly as v1.9: no `font-size-adjust` is applied.
  - 49. An invalid text size is rejected with 400, a valid change is audited, and Reset returns Standard.
  - 50. The audit script reports zero failures for all 27 combinations on the §6 pages and widths.

## 7. Audit record (2026-11-17/18)

- 22 pages (storefront and admin) × 360, 390, 768, 1024, 1440 px with `frontend/scripts/typography-audit.js`. All 26
  combinations ran at 360 px. The other widths ran Standard and Large only: Compact is uniformly smaller than
  Standard, so a Standard pass covers it.
- **Fixed during tuning** (component fixes, no factor needed lowering):
  - Footer Help links: two sub-columns only from 1280 px (they wrapped at 768 and 1024).
  - Cart delivery-area buttons stack below 400 px.
  - Dashboard "৳ thousand" label kept on one line.
  - Chart screen-reader tables wrapped in `div.sr-only` (a `<table>` cannot shrink and widened phone pages).
  - `fieldset { min-inline-size: 0 }` (the product form's variant table widened the page).
  - Admin order numbers kept on one line.
- **Final result:** 0 font-caused failures. A targeted recheck after the last fixes covered home, admin orders and
  the courier dashboard at 768/1024/1440 px at Large.
- **Follow-up 2026-11-18:** the problems listed below that already existed are resolved:
  - Admin orders at phone widths: the list's grid cell gets `min-w-0`, so the table scrolls in its own box.
  - Size-guide tab: `min-h-10` instead of a fixed height, so the long label wraps inside the tab.
  - The video titles and the sidebar brand were false alarms in the audit script (line-clamped text and glyph
    ascent above tight lines); the script was corrected.
  - Recheck: 0 baseline problems and 0 failures on those pages at 360/390 px with Elegant and Modern at Standard
    and Large.
- **Problems that already existed with today's fonts** (original findings):
  - The admin orders page scrolls sideways at phone widths.
  - Long video titles overflow their buttons on the home page.
  - A size-guide tab label overflows at 360 px.
  - The admin sidebar brand overflows at phone widths.
- Wrapping that is intended and allowed: cards, full-cover video title overlays, status lines and table headers.
  Headings gaining a line at Large are listed as notes (for example "Lingerie Sets" at 360 px).
