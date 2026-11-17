# SRS amendment v1.5 (approved, applied)

**Approved by the owner on 2026-11-08 and applied to `SRS.md` as v1.5.** This file is kept as the change record.

## 1. Theme: owner-editable Background and Text (changes THM-03, THM-15; extends THM-02/04/07/14/18/19)

- **THM-03 (replaces the "fixed in v1" sentence).** The page **Background** and **Text** colours are owner-editable. Every other
  neutral (surface, cream, border, field, muted, body, tinted tiles) is **derived** from those two by the server (THM-14) so any
  background stays readable; the footer, announcement bar and status chips remain fixed. The admin portal keeps the Signature
  neutrals; primary and accent still style both (THM-05).
- **THM-02.** The owner sets Primary (required), Accent (optional), Background (required, default `#F8F4EC`) and Text (required,
  default `#231E1C`).
- **THM-07.** The readability guard checks text on background (4.5:1) and primary on background (3:1). A failing combination
  needs `confirm_low_contrast` to publish (400 `low_contrast` listing the issues).
- **THM-14.** The server recomputes all derived tokens on save. While Background and Text are the defaults only the six palette
  tokens are emitted and `tokens.css` supplies the neutrals, so existing sites look unchanged. The public payload stays under 2 KB.
- **THM-18/19.** Palettes (built-in and custom) carry Background and Text; built-ins keep the defaults.
- **THM-15 (out of scope list).** Remove "owner-editable neutral palette". Still out of scope: a visitor-facing dark-mode toggle,
  owner-editable fonts, per-category or per-page colours, scheduled themes.
- **THM-06/08 (clarification).** The storefront theme is applied through a zero-specificity default (`:where(:root)`), so the
  saved theme always wins; Admin → Theme applies a published theme to open pages at once.
- **DB §6 `core_themesettings` / `core_themepalette`:** add `background_hex`, `text_hex` (varchar 7).

## 2. Product photos (changes §10, WEB-09, CAT-04)

- Product photo minimum is **300 px on the long side** (was 600 px). Still JPG/PNG/WebP, 5 MB.
- The browser checks type, size and dimensions at selection time; a batch is validated as a whole and names the failing file.

## 3. Product status wording (CAT-02, CAT-04, CAT-15)

`is_active` is shown as **Published / Unpublished** (was Active / Draft). Rules unchanged: a new product is created Unpublished;
publishing needs at least one photo and one active variant.

## 4. Admin feedback and validation (adds to UI-06, ADM-07)

- **UI-06.** Every admin form marks mandatory fields with `*` and optional ones with `(Optional)`, validates inline against the
  API's limits, keeps the user's input on error and moves focus to the first problem.
- **ADM-07.** Every admin API request shows a loading indicator; every failed write shows an error notification with the server's
  message, and a successful write shows a confirmation. Notifications do not replace inline field errors.
- **ADM-12 (new).** The admin browser tab title is `{company name} | Admin Panel` (company name from Settings, SET-08).

## 5. SKU preview (CAT-03, ADM-03)

The variant table previews the SKU of a new variant live from product SKU prefix (or name), colour and size, using the server's
format `PREFIX-COLOUR4-SIZE4`. Saved SKUs never change unless the admin chooses "Use ...". The server remains the authority and adds
`-2`, `-3` on a clash with any product.
