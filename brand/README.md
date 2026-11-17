# SoftLadyLux logo kit

| File | Use |
|---|---|
| `logo-icon.svg` | Icon (SL monogram in a double ring) on light backgrounds. Favicon, social avatar, app icon. |
| `logo-full.svg` | Icon + "SoftLadyLux" + "Fashion & Intimates" on light backgrounds. Header, invoices, packaging. |
| `*-reversed.svg` | Same marks for dark backgrounds (footer, announcement bar, dark packaging). |
| `*-mono.svg` | One colour (ink `#231E1C`) for stamps, embossing, single-colour print. |
| `png/` | Transparent PNG exports (icon 1024 px, full 2000 px wide). |

Colours: ink `#231E1C`, rosewood `#8C5550`, bronze `#7C6036`, champagne `#C9B28D` (reversed: ivory `#F8F4EC`, blush `#D9A7A0`).
Type: Cormorant Garamond 500 (upright and italic) and Jost 500, converted to outlines, so the files need no fonts installed.
The shop's live header logo is uploaded in Admin → Settings; these files are not wired into the site yet.

## Favicon
- `favicon-storefront/`: the logo icon on an ivory disc (so the ink S stays visible on dark browser tabs). Used on the website.
- `favicon-admin/`: simplified dark tile (ink square, ivory S, blush L). Used on the admin panel.
Each folder has `favicon.svg`, `favicon.ico` (16/32/48), `favicon-32.png`, `apple-touch-icon.png` (180), `icon-192.png`, `icon-512.png`.

## Where it is used
Copies live in `frontend/public/` (storefront: `/favicon.*`; admin: `/admin-favicon.*`; logos: `/brand/*`). Storefront header, mobile menu and footer show the logo when no logo is uploaded in Settings (an uploaded logo wins). The admin sidebar shows the icon. Favicon links are set in `nuxt.config.ts` (storefront) and overridden in `layouts/admin.vue` and `layouts/print.vue` (admin); a favicon uploaded in Settings replaces the storefront one.
