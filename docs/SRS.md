# SoftLadyLux — Software Requirements Specification

|                  |                                                                                                                                                                                                                                                                                                                                                                                                      |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Document         | SRS for the SoftLadyLux e-commerce website and admin portal                                                                                                                                                                                                                                                                                                                                          |
| Version          | 1.10                                                                                                                                                                                                                                                                                                                                                                                                  |
| Date             | 2026-11-17                                                                                                                                                                                                                                                                                                                                                                                           |
| Repos            | `backend_softladylux` (Django), `frontend_softladylux` (Nuxt)                                                                                                                                                                                                                                                                                                                                        |
| Design reference | "SoftLadyLux — Storefront & Admin Design" canvas (35+ boards)                                                                                                                                                                                                                                                                                                                                        |
| Status           | Awaiting owner approval. No implementation has started. Scope decisions on costly features are pending (see §1.6 and `SCOPE_REVIEW.md`).                                                                                                                                                                                                                                                             |
| Revision         | 1.1: added theme colour management (§4.16, THM); added scope decision register (§1.6); no existing requirement removed                                                                                                                                                                                                                                                                               |
| Revision         | 1.2: owner scope decisions applied (SD-01, 02, 03, 04, 06, 07, 09, 11, 12, 16, 17, 28); sub-category module added (CAT-17 to CAT-22); consistency pass over all sections. Rows for dropped requirements are kept and marked **Dropped** for traceability                                                                                                                                             |
| Revision         | 1.6 (2026-11-15: live MiMSMS JSON API configured in admin, no fake sender; order-received SMS; header WhatsApp/Call icons; four banner placements incl. Signature panel and Promotional Ads Panel; Best seller flag; 3 s hero and category carousel; GA4 ecommerce event shape; see SRS_AMENDMENT_v1.6_DRAFT.md); 1.5 (2026-11-08: owner-editable theme Background and Text colours; product photo minimum 300 px; Published/Unpublished wording; admin loader, notifications, inline validation and tab title; live SKU preview); 1.4 (2026-11-04: open items decided, palettes approved, staff 2FA out of scope, fake SMS sender); 1.3: owner-configurable staff permissions (§4.17, PRM); colour-palette library (THM-18, THM-19); system-wide unique mobile number (ACC-14); stale-draft auto-cancel dropped; backup script mode flag; chat links moved to the footer; all remaining scope items decided "keep as specified" (§1.6) |
| Revision         | 1.7 (2026-11-16: product and variant weight with order snapshot, CAT-24 to CAT-26; Steadfast courier API: auto-booking on Confirm, signed webhook, reconciliation, Courier dashboard, pickups, returns, customer delivery record, customer courier tracking, §4.18 CRR-01 to CRR-16; permissions `courier.view`, `courier.manage`; ORD-10 replaced; scenarios 31–40. Change record: `SRS_AMENDMENT_v1.7_DRAFT.md`) |
| Revision         | 1.8 (2026-11-17, owner decision: SMS and Steadfast credentials are shown in Admin → Settings, masked with a show/hide toggle, instead of write-only; still never logged, audited or public. Changes ACC-02, CRR-01, §6.) |
| Revision         | 1.9 (2026-11-17: owner-selectable font pairings for the storefront and the admin panel from a fixed catalogue of 9, THM-20 to THM-26; THM-15 and §1.3 changed; §6/§7; scenarios 41–45. Change record: `SRS_AMENDMENT_v1.9_DRAFT.md`) |
| Revision         | 1.10 (2026-11-17: per-pairing font tuning with `font-size-adjust` (width-matched to the original design), Compact/Standard/Large text size per area, responsive guarantee and audit, THM-27 to THM-31; §6/§7; scenarios 46–50. Change record: `SRS_AMENDMENT_v1.10_DRAFT.md`) |
| Revision         | 1.11 (2026-11-23, client request: guest checkout SMS OTP with verified numbers CHK-11; Bank payment method; payment logos CHK-12; SMS log NTF-07 / ADM-14 with permission `sms_log.view`; Buy dialog replaces Quick Add CAT-12; product image zoom CAT-27; seamless hero and uncropped mobile hero WEB-12; footer social icons, fade-in-up, product-page scroll STF-UI-01..04; second product Save ADM-13; Steadfast-aware Move to Shipping ORD-14; scenarios 51–61. Change record: `SRS_AMENDMENT_v1.11_DRAFT.md`) |

Requirement IDs use the pattern `MODULE-NN`. Words: **must** = mandatory for v1, **should** = desirable for v1, **later** = explicitly out of v1.

---

## 1. Introduction

### 1.1 Purpose

This document defines what the SoftLadyLux system does, the rules it follows, the data it keeps, and how it is delivered. It is the single source for design, development, testing, and acceptance.

### 1.2 Business background

SoftLadyLux is a Bangladeshi online retailer of women's fashion and intimates. Categories: Bras, Panties, Lingerie Sets, Shapewear, Sleepwear, Tops, Accessories, Gift Sets, plus an Offers view. Customers are mostly mobile users in Bangladesh paying with bKash, Nagad, or cash on delivery. The owner runs the shop day to day and must be able to change all content and business settings without a developer.

### 1.3 Scope

In scope for v1: public storefront, customer accounts, cart, checkout, order management, manual payment verification, inventory, coupons, reports, website/content management, company settings, contact form, wishlist, wishlist insight, Google Tag Manager / GA4 analytics, product sub-categories, owner-configurable staff permissions, role-based admin portal at `/admin/`, centralised theme colour management (§4.16), product weight (CAT-24 to CAT-26), Steadfast courier integration (§4.18, v1.7).

Out of scope for v1 (later) — online payment gateway, SMS marketing notifications (v1 sends only OTP SMS and the order-received SMS, NTF-02), courier API integration other than Steadfast (RedX, Pathao), Steadfast payouts, multi-language (Bangla), free-delivery threshold, loyalty points, product reviews, multi-warehouse, mobile apps, flash-sale timers, bundles, order-status notifications by SMS, dark mode, custom or uploaded fonts (font pairings from the THM-20 catalogue are in scope, v1.9).

**Dropped by owner decision (v1.2):** stock reservation, abandoned-cart list, custom visitor log and tracing screen, server-side cart and cart merge, partial returns, server-side PDF generation, home-section reordering, banner/slide date scheduling, image rendition pipeline, Celery/Redis, email OTP, the Manager and Content editor roles, stale-draft auto-cancel, the header contact bar and the floating chat button.

### 1.4 Definitions

| Term | Meaning |
|---|---|
| Variant | A sellable combination of a product with size and colour; holds the stock and SKU |
| On hand | Physical units in stock (deducted when an order is Confirmed) |
| Available | Equal to on hand. v1 has no stock reservation (SD-07): Draft orders neither hold nor deduct stock |
| Sub-category | A named subdivision of one category (e.g., Bras → Maternity Bra, Air Bra, Tube Bra) |
| GTM / GA4 | Google Tag Manager and Google Analytics 4, used for visitor, page and button-click reports |
| TrxID | bKash/Nagad transaction ID entered by the customer |
| Site settings | The single common configuration record holding company data, payment numbers, and delivery fees |
| Draft | Newly placed order, awaiting owner confirmation |
| BDT / ৳ | Bangladeshi taka, the only currency |

### 1.5 Stakeholders

Owner (approves scope and content), Customers, Staff, Developer (the project engineer).

### 1.6 Scope decision register (budget review)

The project has a basic-to-medium budget, so features that add significant effort, complexity, or running cost were reviewed one by one (companion document `SCOPE_REVIEW.md`). **All items in this register are now decided by the owner (2026-11-04).** Items marked "keep as specified" stay exactly as written in the requirements; the others were simplified as recorded and the simplification is already applied throughout this version. The ⚑ markers used during the review have been removed.

| SD | Feature | Requirements affected | Complexity | Decision |
|---|---|---|---|---|
| SD-01 | Background jobs (Celery + Redis) | ARC-10, NTF-06 | Medium | **Decided:** Django-Q2 with PostgreSQL broker; no Celery/Redis |
| SD-02 | Image renditions pipeline (WebP sizes) | ARC-07, WEB-09 | Medium | **Decided:** Nuxt Image request-time resizing with cache |
| SD-03 | Visitor tracing and event log | INS-03, INS-04, INS-05 | High | **Decided:** GTM + GA4 with dataLayer events and button-click tracking; no custom visitor log |
| SD-04 | Abandoned carts and server-side cart sync | CRT-01, CRT-06, INS-02 | Medium | **Decided:** browser-only cart with robust validation; no abandoned-cart list |
| SD-05 | Wishlist insights | INS-01 | Low | **Decided:** keep as specified |
| SD-06 | Email-OTP login and accounts | ACC-01, ACC-02, ACC-03 | Medium | **Decided:** guest checkout + track by order number and phone; optional registration (name, mobile, password, optional email), forgot password, SMS OTP via MiMSMS |
| SD-07 | Stock soft-reservation and auto-expiry | INV-02, INV-03, ORD-12 | High | **Decided:** no reservation; Confirm deducts stock |
| SD-08 | Stock ledger with row locking | INV-08, INV-09 | Medium | **Decided:** keep as specified |
| SD-09 | Partial returns and do-not-restock | ORD-05, INV-06 | Medium | **Decided:** whole-order returns, restock all |
| SD-10 | Bulk order actions | ORD-07 | Medium | **Decided:** keep as specified |
| SD-11 | Printable invoice and delivery slip | ORD-08 | Medium | **Decided:** print-styled HTML pages (browser Print / Save as PDF) |
| SD-12 | Extended payment audit controls | PAY-04, PAY-06, PAY-07 | Medium | **Decided:** basics kept (PAY-01 to 03, 05, 08); extras simplified |
| SD-13 | Advanced coupon rules | CPN-01, CPN-02, CPN-05 | Medium | **Decided:** keep as specified |
| SD-14 | Reports suite and CSV export | RPT-01 to RPT-07 | Medium | **Decided:** keep as specified |
| SD-15 | General audit log | ADM-10, SET-07 | Medium | **Decided:** keep as specified |
| SD-16 | Admin roles and permissions | ADM-06, ACC-10, §4.17 | Medium | **Decided:** two roles, Owner and Staff; **the Owner configures each Staff user's permissions** (add/remove at any time) |
| SD-17 | Home sections, banner placements, scheduling | WEB-02, WEB-06, WEB-10 | Medium | **Decided:** fixed home layout; carousel, two banners, categories, videos with on/off; no scheduling |
| SD-18 | Static pages with rich-text editor | WEB-07 | Low | **Decided:** keep as specified |
| SD-19 | Search with live suggestions | CAT-10 | Medium | **Decided:** keep as specified |
| SD-20 | URL-synced filters and "Load more" | CAT-09 | Low | **Decided:** keep as specified |
| SD-21 | Configurable size calculator and charts | CAT-08 | Low | **Decided:** keep as specified |
| SD-22 | Product bulk actions and drag-reorder | CAT-04, CAT-15 | Low | **Decided:** keep as specified |
| SD-23 | SEO extras (structured data, Open Graph) | §9 SEO | Low | **Decided:** keep as specified |
| SD-24 | Admin portal usable on mobile | ADM-09 | Medium | **Decided:** keep as specified |
| SD-25 | Full branded email template set | NTF-02, NTF-03 | Low | **Decided:** keep as specified |
| SD-26 | Account deletion and anonymisation | ACC-08 | Low | **Decided:** keep as specified |
| SD-28 | Quality and operations targets | §9 (coverage, WCAG, Lighthouse, Sentry, backups) | Medium | **Decided:** reduced targets, but **100% API test coverage** on the Django side |
| SD-29 | Newsletter sign-up and export | NTF-04 | Low | **Decided:** keep as specified |
| SD-30 | Message catalogue for later Bangla | UI-07 | Low | **Decided:** keep as specified |
| SD-31 | Cost price and inventory valuation | INV-13 | Low | **Decided:** keep as specified |

Required and not up for descoping: SD-32 Docker deployment (ARC-09) and SD-33 theme colour management (§4.16).

---

## 2. Overall description

### 2.1 System context

```
Customer browser ──► Nuxt app (storefront  /  and admin  /admin/) ──► Django REST API ──► PostgreSQL
                                                              │──► Media storage (images)
                                                              ├──► Email (SMTP) — contact form, order notices
                                                              └──► SMS gateway (MiMSMS) — registration and password-reset OTP, order-received SMS
Browser ──► Google Tag Manager / GA4 (only after cookie consent)
Django-Q2 worker (PostgreSQL broker) sends the emails and SMS
```

The frontend is a Nuxt 3 (Vue 3) application with server-side rendering for the storefront. The admin portal is part of the same Nuxt app under the `/admin/` URL prefix with its own layout and a staff-only route guard. The backend exposes a JSON REST API only; Django's built-in admin is enabled for developers at an obscure path and is not used by the owner. Images are resized at request time by Nuxt Image with caching; background work (email and SMS sending) runs in a Django-Q2 worker with a PostgreSQL broker; analytics run in the browser through Google Tag Manager and GA4 after consent.

### 2.2 Users and roles

| Role | Description |
|---|---|
| Guest | Browses, searches, uses the cart, may check out without an account, and tracks an order with order number + phone |
| Customer | Registered with name, mobile, password (email optional); wishlist, saved addresses, order history |
| Owner | Full access to everything, including settings, theme, users, permissions and the audit log |
| Staff | Back-office user whose access is **exactly the permissions the Owner grants** (§4.17). The Owner can add or remove any permission for any Staff user at any time |

**Permission catalogue** (details and rules in §4.17):

| Code | Allows | Default for new Staff |
|---|---|---|
| `dashboard.view` | Dashboard (widgets limited to the areas the user can open) | ✔ |
| `orders.view` | View orders, print invoice and delivery slip | ✔ |
| `orders.manage` | Change order stages, edit address/phone/note, cancel, return, bulk actions | ✔ |
| `payments.verify` | Verify or reject payments, correct TrxID | ✔ |
| `products.view` | View products, categories and sub-categories | ✔ |
| `products.manage` | Create/edit/deactivate products, variants, photos, categories, sub-categories, bulk actions | ✔ |
| `inventory.view` | Stock list and movement history | ✔ |
| `inventory.adjust` | Manual stock adjustments | ✔ |
| `coupons.manage` | Create and edit coupons | – |
| `reports.view` | Reports | – |
| `website.manage` | Carousel, banners, videos, announcement, static pages, trust items | – |
| `contact.manage` | Contact messages, newsletter export | – |
| `insights.view` | Wishlist insight and GA4 link | – |
| `settings.manage` | Site settings (company, payment numbers, delivery fees, analytics ID) | – |
| `theme.manage` | Theme colours | – |
| `courier.view` | Courier dashboard, Steadfast parcel lists and return requests (v1.7) | ✔ |
| `courier.manage` | Book or retry Steadfast parcels, bulk booking, refresh, pickup and return requests (v1.7) | – |
| `sms_log.view` | View the SMS log (v1.11) | – |
| `sms.send` | Send a one-off SMS from the SMS log page (v1.11; implies `sms_log.view`) | – |

**Owner-only (cannot be delegated):** create and deactivate Staff, reset passwords, edit permissions, and view the audit log.

### 2.3 Operating environment

Modern evergreen browsers (last two versions of Chrome, Edge, Safari, Firefox) on mobile and desktop. Server: Linux, Docker Compose (Nginx, Nuxt, Django/Gunicorn, Django-Q2 worker, PostgreSQL).

### 2.4 Constraints and assumptions

- Payments are manual (bKash/Nagad send-money to merchant numbers, plus COD). No gateway.
- One-time codes are sent by SMS through the **MiMSMS non-masking SMS API**. Per the provider's page: prepaid packs cost roughly ৳0.25–0.34 per SMS, the sender is a numeric ID, only local traffic is allowed, and API access needs approval with business registration documents. WhatsApp is not used for OTP.
- Analytics need a Google account owning a GA4 property and a Google Tag Manager container.
- Currency BDT only; prices include VAT; no tax engine.
- Real business data (address, phones, merchant numbers, logo, photos) is entered by the owner in the admin portal; development uses placeholders.
- The design canvas is the visual authority; deviations require owner approval.

---

## 3. System architecture requirements

| ID | Requirement |
|---|---|
| ARC-01 | Backend: Python 3.12+, Django 5, Django REST Framework, PostgreSQL 16. |
| ARC-02 | Frontend: Nuxt 3, Vue 3, TypeScript, Pinia state, Tailwind CSS (design tokens from the design system), `@nuxt/image` for responsive WebP images, Google Tag Manager integration. |
| ARC-03 | Storefront uses SSR/SSG-hybrid for SEO (home, category, product); admin is client-rendered. |
| ARC-04 | Admin portal routes live under `/admin/**`, with a separate layout and a guard that redirects non-staff to the admin login. |
| ARC-05 | API versioned under `/api/v1/`. Admin endpoints under `/api/v1/admin/` require staff authentication and role permissions. |
| ARC-06 | Authentication: customers by **mobile number + password** (mobile verified by SMS OTP at registration; password reset by SMS OTP); staff by **email + password**. Sessions via secure HTTP-only cookies (or JWT in cookies); CSRF protection enabled. (SD-06) |
| ARC-07 | Media files in a storage abstraction (local volume in v1, S3-compatible later). The backend validates uploads (type, size, decodable image) and stores the **original only**. Display sizes (WebP) are produced at request time by **Nuxt Image** with a persistent cache. (SD-02) |
| ARC-08 | Configuration by environment variables (`.env`); no secrets in the repository. |
| ARC-09 | Docker Compose with services: `db`, `backend`, `worker` (Django-Q2 cluster), `frontend`, `nginx`. No Redis service. Separate `docker-compose.dev.yml`. |
| ARC-10 | Background jobs (sending emails and SMS) run on **Django-Q2** with the PostgreSQL (ORM) broker, in a `worker` container. No Celery or Redis. Failed tasks are retried and logged. (SD-01) |
| ARC-11 | Every table has `created_at` and `updated_at`; business-critical tables use soft delete (`is_active`/`deleted_at`) rather than hard delete. |
| ARC-12 | Theme colours are served by the backend as design tokens and injected into the page head by the Nuxt server so the first paint is already themed (see §4.16). |

---

## 4. Functional requirements

### 4.1 Site settings — common configuration (SET)

One record (singleton) holds all owner/company data. Everything on the storefront that is company-specific is read from here.

| ID | Requirement |
|---|---|
| SET-01 | Must store: company name, tagline, logo, favicon, address lines, city, country, support phone(s), WhatsApp number, support email, working hours, Facebook / Instagram / YouTube / TikTok URLs, Messenger link, footer about text, copyright text. |
| SET-02 | Must store payment configuration: bKash merchant number and account type, Nagad merchant number and account type, payment instructions text (shown at checkout), COD enabled flag. |
| SET-03 | Must store delivery fees: fee for Inside Dhaka and fee for Outside Dhaka (BDT), and delivery time text for each. |
| SET-04 | Must store SEO defaults: site title, meta description, default share image. |
| SET-05 | Must store order rules: stale-draft highlight hours (default 24), low-stock threshold (default 5), order number prefix. |
| SET-06 | Public read-only endpoint `/api/v1/settings/` returns only public fields (never internal fields) and is cached; cache is cleared on save. |
| SET-07 | Only the Owner can edit. Each save is written to the audit log with old and new values. |
| SET-08 | Header, footer, contact page, checkout payment screen, and SEO meta all read from this record. No such value is hard-coded in the frontend. |
| SET-09 | Must store the **Google Tag Manager container ID** (e.g., `GTM-XXXXXXX`); empty means analytics is disabled. (SD-03) |

### 4.2 Website content management (WEB)

| ID | Requirement |
|---|---|
| WEB-01 | **Hero carousel slides:** image (desktop and optional mobile crop), eyebrow text, heading, sub-text, button label, link target (category, product, URL), sort order, on/off switch. At least 1, at most 8 active slides shown; the carousel advances every **5 seconds** (v1.11; was 3 s in v1.6) and only to a slide whose picture has loaded. No date scheduling. (SD-17) |
| WEB-02 | **Banners:** four fixed placements, edit only: `home_promo` and `home_offer` (shown side by side, whole and uncropped in the uploaded picture's own proportions), `signature` (the big Signature collection panel; the line-art panel is the fallback when no image is set) and `popup` (WEB-11); image, heading, text, button label, link, on/off switch. Other placements (category header, size-finder band) are not editable in v1. (SD-17, v1.6) |
| WEB-03 | **Category tiles:** each category has a tile image (used by the home category carousel), title, order, visibility. The home category carousel (six tiles on desktop, arrows beside the heading) moves right-to-left one tile every **3 seconds** in an endless loop, can be dragged with the mouse (with flick momentum) or swiped on touch screens, pauses on hover, focus, touch and drag, and does not move for visitors who prefer reduced motion. (v1.6) |
| WEB-04 | **Video gallery:** title, video URL (YouTube/Facebook/direct), thumbnail, order, active. |
| WEB-05 | **Announcement bar:** one or more short messages with optional link, active flag. |
| WEB-06 | **Home layout is fixed:** hero carousel, trust strip, category carousel, New arrivals, Signature collection, Offers tabs, Video gallery, Size-finder band. The owner edits the content of the carousel, banners, categories and videos, each with an on/off switch; sections cannot be reordered or hidden. New arrivals, Signature and Offers fill automatically from product flags. (SD-17) |
| WEB-07 | **Static pages:** About, Delivery & Returns, Privacy, Terms — simple rich-text pages editable in admin, shown in the footer. |
| WEB-08 | **Trust strip items:** icon, title, text, order (e.g., "Easy returns", "Secure payments"). |
| WEB-09 | Image upload rules: JPG/PNG/WebP, max 5 MB each; the original is stored and display sizes are generated at request time by Nuxt Image with caching; recommended dimensions are shown beside each upload field; alt text is required for accessibility. (SD-02) |
| WEB-10 | Changes go live on save (storefront caches are invalidated). There is no date scheduling in v1; the owner switches items on or off manually. (SD-17) |
| WEB-11 | **Promotional Ads Panel** (v1.6): Admin → Website content → "Promotional Ads Panel" edits one popup (the `popup` banner): image (required to show), heading, text, button label and link, on/off. While it is on, the home page opens it as a dialog once per **full load**, on the visitor's first scroll (about 300 px) or after 12 s without scrolling, never immediately on load (SEO: no intrusive interstitial, fast mobile LCP); it closes with ×, Esc, the backdrop or "Continue browsing". |
| WEB-12 | (v1.11) Hero slides change with a seamless slide (no blank frame): slides form one continuous strip of pictures (cloned ends for a seamless loop) that glides as a whole; every picture is preloaded and decoded, slides stay rendered, autoplay waits for a picture that is not ready, and the text cross-fades without changing height. On phones (< 640 px) the picture box takes the first slide's mobile image ratio (clamped 4:5 to 3:1) and every picture covers it, so there are no empty bands. The promotional popup picture also covers its box on phones. |

### 4.3 Catalogue (CAT)

| ID | Requirement |
|---|---|
| CAT-01 | **Category:** name, slug, description, tile image, sort order, active, SEO title/description, and its sub-categories (CAT-17). Seeded with the eight categories. "Offers" is a virtual view of products with a discount, not a stored category. |
| CAT-02 | **Product:** name, slug (auto, editable, unique), category, sub-category (CAT-17, CAT-19), short description, full description (rich text), fabric/care notes, brand/collection label, unit of measure (pc, set, pair, pack), base price, compare-at price (optional, must be higher than price), SKU prefix, published/unpublished (stored as `is_active`), tags, section flags (`is_new`, `is_signature`, `is_offer`, `is_bestseller` — v1.6), SEO fields. |
| CAT-03 | **Variant:** every product has one or more variants (a product with no options has one default variant). Fields: size label, colour name and swatch, SKU (unique), price override (optional), on hand, active. For bras, size is band + cup (e.g., 34B); for apparel, alpha (S–XXL); for accessories, free size. The admin variant table previews the SKU of a new variant live from the product SKU prefix (or name), colour and size in the server format `PREFIX-COLOUR4-SIZE4`; saved SKUs never change unless the admin chooses "Use ...", and the server stays the authority, adding `-2`, `-3` on a clash with any product. |
| CAT-04 | **Product images:** upload many during create/edit; mark one primary; drag to reorder; optionally link an image to a colour; delete. A product needs at least one image to be published. Each photo is JPG/PNG/WebP, up to 5 MB and at least 300 px on the long side; the browser checks type, size and dimensions at selection time, and the server validates a batch as a whole and names the failing file. |
| CAT-05 | Discount badge: if compare-at price > price, display "−N%" where N = round((compare − price) / compare × 100), and show the compare-at price struck through. |
| CAT-06 | A product appears in the **Offers** view if it has a compare-at price above its price or `is_offer` is set. |
| CAT-07 | **New arrivals:** products flagged `is_new`, or created in the last 30 days when no products are flagged. |
| CAT-08 | **Size chart:** admin-managed tables (band/cup, apparel, panty) used by the size guide page. The size calculator uses configurable thresholds (defaults from the design). |
| CAT-09 | **Listing page** per category and for Offers/New/Search: filters (on a category page: sub-category of that category, see CAT-20; on Offers/New/Search pages: category; size, colour, collection, price range, availability), sort (featured, newest, price low-high, price high-low), pagination with "Load more" showing "Showing X of Y". Filters are reflected in the URL query string so results are shareable. |
| CAT-10 | **Search:** by name, SKU, category, tags; suggestions dropdown while typing (top 6 matches with image and price); Bangla/English transliteration later. Sub-category names are also searched. |
| CAT-10a | (v1.11) Below `md` the search panel lists **Products** first, then Suggestions/Browse. |
| CAT-11 | **Product detail page:** gallery with zoom, variant selectors (size, colour), live price and availability (In stock / Only N left / Out of stock), quantity, Add to bag, Add to wishlist, size guide link, details tabs, delivery info (from settings), related products. |
| CAT-12 | (v1.11, replaced) **Buy** on cards (cart icon + "Buy") opens a compact product dialog (bottom sheet on phones, centred modal on wider screens): zoomable photo (CAT-27 controls), name, price, colour choices, size chips (sold-out disabled), size-guide link, quantity. **Add to Cart** adds and closes; **Checkout Now** (left) adds and opens `/checkout` with the whole bag; **Add to Cart** sits on the right. Both have icons and stay disabled until every required option is chosen, with a red prompt ("Please select a size"); a single-variant product is preselected. |
| CAT-13 | Out-of-stock variants are visible but disabled; a product with no available variants shows "Sold out". |
| CAT-14 | Deleting a product that has been ordered only deactivates it. |
| CAT-15 | Bulk actions in admin: publish/unpublish, change category, set flag, export CSV.; changing category requires choosing a new sub-category (CAT-21) |
| CAT-16 | Product CSV import is **later**. |
| CAT-17 | **Sub-category:** belongs to exactly one category; fields: name (2–40 characters, unique within its category, case-insensitive), slug (unique within the category), sort order, active flag. Example: Bras → Maternity Bra, Air Bra, Tube Bra. A category may have zero, one, or many sub-categories. |
| CAT-18 | **Category admin form:** the Add/Edit Category form has a **Sub-categories** section with a repeatable text input (add row, remove row, drag to reorder, on/off switch), so sub-categories are entered while creating the category and can be edited later. One save creates, renames, reorders or deactivates them. |
| CAT-19 | **Product admin form:** a **Sub-category** drop-down placed under Category, listing only the active sub-categories of the selected category and disabled until a category is chosen. It is **required when the selected category has at least one active sub-category**, optional otherwise. Changing the category clears the sub-category. The server rejects a sub-category that does not belong to the product's category. |
| CAT-20 | **Storefront category-page filter:** when a customer opens a category (e.g., Bras from the category bar), the left filter shows a **Sub-category** group of multi-select checkboxes for that category only (e.g., Maternity Bra, Air Bra, Tube Bra), each with its product count, **instead of** the category checkbox list. No selection shows all products of the category; one or more selections show products in any selected sub-category (OR). The group is hidden when the category has no active sub-categories. Selected sub-categories appear as removable chips and in the URL (`/shop/bras?sub=air-bra,tube-bra`). Size, colour, collection, price and availability filters combine with it (AND). On Offers, New arrivals and Search pages, which span categories, the filter shows categories instead. The mobile filter drawer behaves the same. |
| CAT-21 | **Integrity rules:** a sub-category that has products cannot be deleted (deactivate it or move the products first); deactivating hides it from filters and the product drop-down but its products stay visible under their category; renaming keeps the slug unless the owner edits it; bulk change of category requires choosing a new sub-category (or none if the new category has none). |
| CAT-22 | **Display and reach:** the product page breadcrumb is Home › Category › Sub-category; sub-category names are searchable (CAT-10) and appear in CSV exports; a category-scoped coupon covers all sub-categories of that category (CPN-02). |
| CAT-23 | **Best seller** (v1.6): products are marked by hand ("Best Seller" under "Show in sections" on the product form, or the bulk action). The home "Offers & favourites" section has three tabs: Special offer · Best seller · Our favourites (Signature flag); a tab with no products is hidden. |
| CAT-24 | **Product weight** (v1.7): every product has a weight in grams (whole number, 1–30,000) on the product form. New products default to 100 g; existing products were set to 100 g when v1.7 was deployed. The weight is never blank. |
| CAT-25 | **Variant weight override** (v1.7): a variant may have its own weight (same bounds); blank means the product weight. Effective weight = variant weight, else product weight. The admin variant table has a "Weight (g)" column. |
| CAT-26 | **Weight on orders** (v1.7): each order line copies the variant's effective weight at placement (snapshot, rule 10). Order total weight = Σ line weight × quantity, shown on admin order detail and the delivery slip (ORD-08). Lines placed before v1.7 were set to 100 g. |
| CAT-27 | (v1.11) **Product image zoom** on the product page: + / − buttons (1× to 4×, step 0.5) and reset on all screens; two-finger pinch and drag-to-pan on touch; Ctrl/⌘ + wheel on desktop (plain wheel scrolls the page); double-tap/double-click toggles 2×. Changing photo resets the zoom. |

### 4.4 Customer accounts (ACC)

| ID | Requirement |
|---|---|
| ACC-01 | **Registration is optional** (guests can always check out). A customer registers with **name, mobile number, password**, and optional email. The mobile number must be verified by a 6-digit **SMS OTP** (valid 5 minutes; max 5 attempts per code; resend after 60 seconds; max 5 codes per mobile per hour and 10 per day) before the account becomes active. The mobile number is unique system-wide (ACC-14). (SD-06) |
| ACC-02 | **SMS provider:** SMS is sent through the **MiMSMS JSON API** (`POST` to the API URL with `apiKey`, `userName`, `senderName`, `transactionType` = `T`, `mobileNumber` = `8801XXXXXXXXX`, `message`; success = reply `statusCode` `"200"`). API key, username, sender name and API URL are entered in **Admin → Settings → SMS** — no SMS environment variables, no provider switch and no fake sender; incomplete settings make every send fail with "SMS is not configured". The API key is shown in Admin → Settings → SMS to `settings.manage` only, masked with a show/hide toggle (v1.8); it is never logged, audited or public. MiMSMS accepts calls only from whitelisted server IPs; a refused IP is reported with the IP to add. Admin → Settings → SMS has **Send test SMS** (`settings.manage`, 10 per hour). (v1.6) Sending goes through the Django-Q2 queue with retries. If sending fails the user sees a clear message and can retry or contact support. Each SMS costs money, so OTP requests are rate-limited per mobile number and per IP (§9). (SD-06) |
| ACC-03 | Customer login by **mobile number + password**. Sessions last 30 days with "remember me", otherwise until the browser closes. After 5 failed password attempts login is locked for 15 minutes. (SD-06) |
| ACC-04 | Profile: name, mobile (verified), email (optional, not used for login), birthday (optional). |
| ACC-05 | Address book: label, recipient name, phone, delivery area (Inside/Outside Dhaka), district, thana/area, full address; one default; up to 5. |
| ACC-06 | Order history with status, tracking timeline, print-styled invoice page (browser Print / Save as PDF), cancel button while status is Draft or Confirmed, reorder button. |
| ACC-07 | Wishlist stored in the database for logged-in customers; a guest's local wishlist merges into the account at login. |
| ACC-08 | Customer may request account deletion; personal data is anonymised, order records are retained. |
| ACC-09 | Guests may track an order with order number plus phone number. |
| ACC-10 | Staff accounts are separate (email + password; 2FA is out of scope), created by the Owner, and cannot log in at the customer form. Roles: **Owner** and **Staff** only; a Staff user's access is the permission set the Owner assigns (§4.17). (SD-16) |
| ACC-11 | **Forgot password:** the customer enters their mobile number; an SMS OTP is sent (same limits as ACC-01); after the OTP is verified the customer sets a new password and other sessions are signed out. (SD-06) |
| ACC-12 | **Password rules:** at least 8 characters, stored hashed, must not equal the mobile number. |
| ACC-13 | **Guest orders and accounts (must):** when a customer registers and verifies a mobile number by OTP, earlier guest orders with the same (normalised) number are linked to the account and appear in the order history. Guests continue to track orders by order number + phone (ACC-09), including after linking. |
| ACC-14 | **Mobile number uniqueness (system-wide):** a mobile number is stored normalised (`01XXXXXXXXX`; `+880` and `880` accepted) and can belong to **only one user account across customers and Staff** (database unique constraint; Staff numbers are optional). Registering with an existing number shows "already registered: log in or reset your password". Customers log in with mobile number + password. Guest orders are not accounts, so one number may appear on many guest orders. |

### 4.5 Cart (CRT)

| ID | Requirement |
|---|---|
| CRT-01 | The cart is kept **only in the browser** (localStorage) for guests and logged-in customers alike. There is no server-side cart and no cart merge, and a cart does not follow the customer to another device. (SD-04) |
| CRT-02 | Lines: variant, quantity (1–10 per line, capped by available stock), unit price snapshot shown but re-validated against the current price at checkout. |
| CRT-03 | The cart re-validates with the server (`POST cart/validate/`) on load and before checkout; lines whose variant is deactivated or sold out are flagged and block checkout until removed. |
| CRT-04 | Cart shows subtotal, applied coupon, estimated delivery (based on the chosen area), and total. |
| CRT-05 | Coupon entry with clear messages for invalid, expired, minimum not met, or already used. |
| CRT-06 | **Dropped** (SD-04): no server-side cart record and no abandoned-cart list. Checkout drop-off is read from the GA4 `begin_checkout` and `purchase` events (§4.11). |
| CRT-07 | **Storage robustness:** the stored cart has a schema version and is parsed defensively; corrupt or old-format data is migrated or discarded without an error screen. If localStorage is unavailable (private mode or blocked), the cart works in memory for the session and tells the user it will not be saved. Cart changes sync across open tabs (storage event). Limits: 30 lines, quantity 1–10 per line, lines older than 30 days are dropped. (SD-04) |
| CRT-08 | **Validation endpoint:** `POST /api/v1/cart/validate/` takes lines (variant id, quantity) and returns for each line the current price, available quantity, and active flag, plus any coupon check. It is public, rate-limited, and never trusted for pricing: checkout (CHK-06) recomputes everything on the server. (SD-04) |
| CRT-09 | **Failure handling:** price changes, sold-out lines, deactivated products and quantity above stock are flagged on the cart and checkout pages with a clear message and a one-click fix; nothing is charged at a stale price. The cart is cleared only after an order is successfully created. (SD-04) |

### 4.6 Checkout and order placement (CHK)

| ID | Requirement |
|---|---|
| CHK-01 | Guest or logged-in checkout. Fields: full name, phone (BD format `01XXXXXXXXX`, validated), email (optional for guests, used for notices), delivery area (Inside Dhaka / Outside Dhaka), district, thana/area, address line, order note. |
| CHK-02 | The delivery fee is looked up from site settings by the chosen area and shown immediately; the total is recomputed server-side. |
| CHK-03 | **Payment methods:** bKash, Nagad, Cash on Delivery (if enabled in settings). |
| CHK-04 | For bKash/Nagad the screen shows the merchant number and instructions from settings; the customer pays by send-money, then enters the **sender number** and the **TrxID**. Both are required for these methods. (v1.11) For **Bank** the screen shows bank name, account name, account number, branch and routing number; the customer enters the **transaction/reference ID** (letters, digits, `-`, 6–30) and the **account holder name**, both required. |
| CHK-05 | TrxID format check (alphanumeric, 8–12 chars), and uniqueness check per method: a TrxID already used on another payment is rejected with a message. |
| CHK-06 | On submit the server, in one transaction: validates every line against current price and **on-hand** stock; creates the order in **Draft** with a unique order number; snapshots line prices, names, variant labels, address, fees, and coupon; creates a payment record (Pending); redeems the coupon; clears the cart. If any line is unavailable, nothing is created and the customer is told which line to fix. Stock is checked but not held or deducted until Confirm (SD-07). |
| CHK-07 | Confirmation page shows order number, summary, what happens next (owner will verify the payment and confirm), and contact details. An email confirmation is sent if an email is present. |
| CHK-08 | Order number format: `SLL-YYMMDD-NNNN` (daily sequence). Unique, never reused. |
| CHK-09 | Duplicate-submit protection (idempotency key per checkout attempt). |
| CHK-10 | COD orders skip payment verification and follow the same Draft → Confirmed flow. The customer pays the courier on delivery; the admin records collection at Delivered. |
| CHK-11 | (v1.11) **Guest mobile verification:** a guest must verify the checkout number with a **4-digit SMS OTP** before placing an order, unless the number is already verified or belongs to a registered account; logged-in customers skip. Code valid 5 min, 3 wrong attempts kill it, resend after 60 s, at most 5 codes per number per hour and 10 per day, per-IP limit, stored hashed. Success stores the number in verified phones; an order from an unverified guest number is refused (`phone_unverified`). The owner can switch the check off in Admin → Settings → SMS (`checkout_otp_enabled`, default on), e.g. while SMS is not configured. |
| CHK-12 | (v1.11) Payment method cards are compact (logo above the name, tick when chosen): two per row on phones, all on one line from 640 px. They show the official bKash and Nagad marks and a bank icon. |

### 4.7 Order management (ORD)

**Order lifecycle**

```
 Draft ──► Confirmed ──► Shipping ──► Delivered
   │           │            │            │
   │           │            └─► Returned ◄┘
   └─► Cancelled ◄─┘
```

| Status | Meaning | Stock effect |
|---|---|---|
| Draft | Placed, awaiting owner confirmation and payment verification | None (stock is checked at placement but not held) |
| Confirmed | Owner accepted; payment verified (or COD) | **On hand deducted** |
| Shipping | Handed to courier | None |
| Delivered | Customer received | None (COD: payment marked collected) |
| Cancelled | Cancelled by customer or staff | From Draft: none. From Confirmed: **on hand restored** |
| Returned | Customer or courier returned goods | **On hand restored** (all items) |

| ID | Requirement |
|---|---|
| ORD-01 | Allowed transitions only as drawn: Draft→Confirmed, Draft→Cancelled, Confirmed→Shipping, Confirmed→Cancelled, Shipping→Delivered, Shipping→Returned, Delivered→Returned. Any other transition is rejected. |
| ORD-02 | A bKash/Nagad order **cannot be Confirmed** until its payment is Verified. COD orders can be Confirmed directly. |
| ORD-03 | Confirming re-checks stock; if `on hand` is insufficient for any line, the confirmation is blocked with an explanation. |
| ORD-04 | The customer may cancel only in Draft or Confirmed; once in Shipping the cancel option disappears and the customer is shown the contact details. Staff may cancel from Draft or Confirmed with a mandatory reason. A Steadfast-booked order is already in Shipping; cancelling the parcel is done in the Steadfast dashboard, and the resulting `cancelled` event flags the order (CRR-09). |
| ORD-05 | **Returned is a whole-order return** and requires a reason; all items are restocked (on hand restored). Damaged or lost items are corrected afterwards with a manual stock adjustment and remark. Partial returns are not supported. (SD-09) |
| ORD-06 | Every status change records who, when, the old and new status, and a note, shown as a timeline to staff and (customer-safe wording) to the customer. |
| ORD-07 | Admin order list: search (order no., name, phone, TrxID), filter (status, payment method, payment status, date range, area), sort, pagination, bulk select to Confirm / Ship / Cancel (bulk Confirm skips orders that fail rules and reports each failure). |
| ORD-08 | Admin order detail: customer and address, lines, totals, coupon, payment block with Verify/Reject, status control, internal notes, timeline, and print-styled **invoice** and **delivery slip** pages opened in the browser (Print / Save as PDF); no server-side PDF. (SD-11) |
| ORD-09 | Staff may edit address, phone, and note on Draft and Confirmed orders (logged). Editing line items is **not** allowed; cancel and re-create instead. |
| ORD-10 | (v1.7) When a Confirmed order is booked with Steadfast it moves to Shipping with courier "Steadfast" and the Steadfast tracking code as tracking reference (CRR-03). Staff can still move an order to Shipping by hand with a free-text courier and tracking reference: the fallback when auto-booking is off or failed, and the way to ship with other couriers. |
| ORD-11 | Delivered orders become read-only except for the Return action. |
| ORD-12 | **Stale Drafts:** Drafts older than the stale-draft hours (default 24, Settings) are highlighted in the order list and on the dashboard so staff can follow up or cancel them manually. There is no automatic cancellation in v1. Drafts hold no stock, so a stale Draft costs only clutter and coupon usage, which staff release by cancelling. (SD-07) |
| ORD-13 | Order totals: `total = subtotal − coupon discount + delivery fee`. Product discounts are already inside the line prices. Delivery fee is never discounted by coupons in v1. |
| ORD-14 | (v1.11) On a Confirmed order **Move to Shipping** books with Steadfast when it is configured (`courier.manage`); while an auto-booking is queued it shows "Booking with Steadfast…" and is disabled; after a failure it reads "Retry booking". A secondary **Ship with another courier** opens the manual ORD-10 form. Without Steadfast only the manual form shows. The server refuses a second booking and a manual ship while a booking is in progress (`booking_in_progress`). |

### 4.8 Payment verification (PAY)

| ID | Requirement |
|---|---|
| PAY-01 | A payment record holds: order, method (bKash, Nagad, Bank (v1.11), COD), amount, sender number (bKash/Nagad), sender name (Bank), TrxID / reference ID, status, verified by, verified at, rejection reason, notes. |
| PAY-02 | Status: **Pending** (bKash/Nagad/Bank awaiting check; COD awaiting collection), **Verified**, **Rejected**, **Collected** (COD only, on delivery). |
| PAY-03 | The owner opens the order, compares the TrxID, sender number, and amount against the bKash/Nagad merchant statement, and marks the payment Verified or Rejected. Rejection requires a reason. |
| PAY-04 | **Dropped** (SD-12): no automatic amount-mismatch warning. The payment amount is shown beside the order total and staff compare them while verifying. |
| PAY-05 | TrxID is unique per method across all payments; duplicates are blocked at checkout and flagged to staff if created by editing. |
| PAY-06 | If a payment is Rejected, the order stays Draft; staff contact the customer by phone and may correct the sender number or TrxID on the payment (the edit keeps the uniqueness check and is noted on the order timeline). There is no customer self-service resubmission. (SD-12) |
| PAY-07 | **Simplified** (SD-12): Verify, Reject and any TrxID edit are recorded on the order timeline with user, time and note; payment rows keep verified-by and verified-at. There is no separate append-only payment audit table. |
| PAY-08 | A "payments to verify" queue on the dashboard lists Pending bKash/Nagad/Bank payments, oldest first. |

### 4.9 Inventory (INV)

| ID | Requirement |
|---|---|
| INV-01 | Each variant holds `on_hand`. There is no reservation in v1, so available stock equals `on_hand`, never below zero. (SD-07) |
| INV-02 | **Draft placed:** no stock change. Checkout is blocked when qty > on hand; the check is repeated at Confirm. (SD-07) |
| INV-03 | **Draft cancelled (by the customer or staff):** no stock change. (SD-07) |
| INV-04 | **Draft → Confirmed:** on_hand −= qty in one transaction with a row lock. Confirm is blocked with an explanation if on hand is insufficient. |
| INV-05 | **Confirmed → Cancelled:** on_hand += qty. |
| INV-06 | **Return (whole order):** on_hand += qty for every item. (SD-09) |
| INV-07 | **Manual adjustment** (stock in, correction, damage, loss): admin enters the variant, signed quantity, reason, **lot/shipment reference**, and remarks; all are mandatory except the lot for corrections. |
| INV-08 | Every change writes an immutable **stock movement** row: variant, change in on_hand, resulting on_hand, reason code (`order_confirmed`, `order_cancelled`, `order_returned`, `adjustment_in`, `adjustment_out`, `opening_stock`), order reference, lot reference, remarks, user, timestamp. Rows are never edited or deleted. |
| INV-09 | All stock changes run inside database transactions with row locks so concurrent orders cannot oversell. |
| INV-10 | Inventory screen: list by product/variant with on hand and status chips (In stock, Low, Out); filter by status and category; movement history per variant; adjustment form; CSV export. |
| INV-11 | Low stock threshold from site settings; the dashboard shows low-stock and out-of-stock counts. |
| INV-12 | Stock can never be negative; adjustments that would go below zero are rejected. |
| INV-13 | Inventory valuation report uses an optional cost price per variant (**should**; hidden from storefront). |

### 4.10 Coupons (CPN)

| ID | Requirement |
|---|---|
| CPN-01 | Fields: code (unique, case-insensitive), description, type (percent / fixed BDT), value, maximum discount cap (for percent), minimum order subtotal, start and end date, total usage limit, per-customer limit, applies to (all / selected categories / selected products), applies to already-discounted items (yes/no), active. |
| CPN-02 | Validation order: active → within dates → minimum subtotal met → usage limits → applicable lines exist. Discount is computed on eligible line totals only, rounded to the nearest taka, never exceeding the subtotal. A category-scoped coupon covers all sub-categories of that category. |
| CPN-03 | One coupon per order. |
| CPN-04 | Usage is counted when the order is placed; it is released if the order is Cancelled, and kept on Returned. |
| CPN-05 | Admin list with usage count, status, quick enable/disable, and a "used by" list of orders. |

### 4.11 Wishlist insight and analytics (INS)

| ID | Requirement |
|---|---|
| INS-01 | **Wishlist insight:** most wishlisted products, and which customers wishlisted a product. |
| INS-02 | **Dropped** (SD-04): no abandoned-cart list. |
| INS-03 | **Analytics through Google Tag Manager + GA4** (SD-03): the storefront loads the GTM container whose ID is stored in Site settings (SET-09), only after the visitor accepts the cookie notice. GA4 provides visitor, page-wise and traffic reports. There is no custom visitor log and no visitor-tracing screen; GA4 data is aggregated and not linked to customer accounts. |
| INS-04 | **Consent:** a cookie notice explains analytics; GTM and GA4 are not loaded until the visitor accepts (Google Consent Mode default: denied). "Decline" keeps analytics off and is remembered. The privacy page mentions Google Analytics. GA4 anonymises IP addresses by default and its data retention is set in GA4. |
| INS-05 | **dataLayer event contract:** the frontend pushes `page_view` (once per page), `view_item_list`, `view_item`, `search`, `login`, `sign_up`, `add_to_cart`, `remove_from_cart`, `add_to_wishlist`, `begin_checkout`, `add_payment_info` (payment method chosen), `purchase` (once per order, when the order is placed, with order number, value, shipping, coupon and items), and a generic `ui_click` event with `button_name`, `button_location` and `page_path`. Any button or link carrying a `data-track="name"` attribute raises `ui_click` automatically, which gives a **page-wise action-button click report** in GA4. The tracked names (e.g., `add_to_bag`, `quick_add`, `buy_now`, `size_guide`, `checkout_submit`, `hero_cta`, `whatsapp_click`) are listed in the repository. Ecommerce events use the GA4 shape `{event, ecommerce: {currency: "BDT", value, items[]}}`, preceded by `{ecommerce: null}`; items carry `item_id`, `item_name`, `item_variant`, `price`, `quantity`, `item_category`. The importable GTM container and setup steps are in the frontend repository (`docs/gtm-container.json`, `TRACKING.md`). (v1.6) No personal data (name, phone, address, email) is ever pushed to the dataLayer; the filter keeps only the contract keys `item_name`, `item_list_name` and `button_name` among keys containing "name". (SD-03) |
| INS-06 | The Insights screen shows the wishlist insight (INS-01) and a link out to the GA4 reports; it requires the `insights.view` permission. |
| INS-07 | Setting up the GA4 property and the GTM container (tags, the `ui_click` trigger, conversions) is done by the developer with the owner's Google account. This SRS defines the event contract (INS-05) and the `data-track` convention. Useful GA4 views: Pages and screens, Events filtered by `ui_click` and `button_name`, Ecommerce purchases, and funnel exploration (`view_item` → `add_to_cart` → `begin_checkout` → `purchase`). |

### 4.12 Reports (RPT)

| ID | Requirement |
|---|---|
| RPT-01 | Date-range selector with presets (today, 7 days, 30 days, this month, custom). |
| RPT-02 | Sales summary: orders count, revenue (Confirmed and later, excluding Cancelled/Returned), average order value, returns, coupon discounts given. |
| RPT-03 | Sales by day (chart), by category, by product (top 20), by payment method, by delivery area. |
| RPT-04 | Order funnel: placed, confirmed, shipping, delivered, cancelled, returned counts and rates. |
| RPT-05 | Inventory report: stock by variant, low/out lists, movement summary by reason for a period. |
| RPT-06 | Coupon report: usage and discount by code. |
| RPT-07 | Export each report to CSV. |

### 4.13 Admin portal (ADM)

| ID | Requirement |
|---|---|
| ADM-01 | Base URL `/admin/`. Login page `/admin/login`. Sidebar sections as designed: Dashboard, Orders, Products, Inventory, Coupons, Reports, Website, Insights, Settings, Users. Each item, screen and button appears only when the signed-in user holds the matching permission (§4.17); Users and Audit log are Owner-only. |
| ADM-02 | **Dashboard:** today's orders and revenue, orders awaiting confirmation, payments to verify, stale Drafts, low-stock count, 7-day sales chart, top products, recent orders. |
| ADM-03 | **Products screen:** table with image, name, category, price, stock, status (Published / Unpublished); search and filters; create/edit form with sections: basics, pricing, variants (add/remove rows of size, colour, SKU, stock), images (multi-upload, reorder, primary), section flags, SEO. Opening stock on creation creates an `adjustment_in` movement with reason "opening stock". |
| ADM-04 | **Website screen** (WEB module): tabs for carousel, banners, categories (reorder, hide, tile image), videos, announcement, sections, static pages, trust items. |
| ADM-05 | **Settings screen** (SET module): tabs for company, contact and social, payment numbers, delivery fees, order rules, SEO. |
| ADM-06 | **Users screen (Owner only):** create Staff accounts, deactivate them, reset passwords, and edit each Staff user's permissions through a checklist (§4.17). There are only two roles. (SD-16) |
| ADM-07 | All lists support server-side pagination, search, sort, and show loading, empty, and error states. Every admin API request shows a loading indicator; every failed write shows an error notification carrying the server's message, and a successful write shows a confirmation. Notifications do not replace inline field errors. |
| ADM-08 | Destructive actions need a confirmation dialog. |
| ADM-09 | The admin is usable on a mobile browser for the dashboard and orders (design: Admin Mobile board). |
| ADM-10 | **Audit log** (Owner only): who changed what and when for orders, payments, stock, settings, theme, products, coupons, users and staff permissions. |
| ADM-11 | **Theme screen** (THM module) under Settings: primary, accent, background and text colour pickers, presets, live preview, save and reset (§4.16). |
| ADM-12 | The admin browser tab title is `{company name} | Admin Panel`, with the company name taken from Settings (SET-08). |
| ADM-13 | (v1.11) The product create/edit page has a second **Save** button directly before the SEO section, identical in action to the top one. |
| ADM-14 | (v1.11) Admin → **SMS log**: newest first, filters by status, source and date range, search by number, pagination, full message on open. Permission `sms_log.view`. A **Send SMS** button (permission `sms.send`) opens a dialog with recipient number and message (max 640 characters, live SMS-part count); the SMS is sent at once, logged as source "Admin (manual)", audited (number only) and rate-limited (30 per hour). |

### 4.14 Contact and notifications (NTF)

| ID | Requirement |
|---|---|
| NTF-01 | Contact form: name, phone, email, subject, message; stored in the database and emailed to the support email from settings; spam protection (honeypot + rate limit). Admin can view and mark as handled. |
| NTF-02 | Emails sent: order received (customer), new order (owner), order status changes (customer, if email present), contact form (owner), newsletter welcome. SMS is used for the registration OTP, the password-reset OTP and the **order-received SMS** to the customer (one ASCII part: "<Company>: Order <number> received. Total Tk <total>. We will call you to confirm. Thank you!"), which the owner can switch off in Admin → Settings → SMS (default on). (v1.6) |
| NTF-03 | Email templates are branded, plain text and HTML, and kept in the repository. |
| NTF-04 | Newsletter sign-up (footer): stores email; export to CSV; sending campaigns is **later**. |
| NTF-05 | **WhatsApp and Messenger links** are shown in the footer Contact column (from Site settings; each hidden when blank), together with the phone number, email and support hours. The header also shows a **WhatsApp** icon (`wa.me/<whatsapp_number>`, which opens the WhatsApp app when installed) and a **Call** icon (`tel:` link to the first support phone) immediately before Track Order, each with a tooltip and each hidden when its number is blank; national numbers (`01…`) are converted to the international form. There is no floating chat button. (v1.6) |
| NTF-06 | Email and SMS sending runs in the Django-Q2 background queue with retries; failures are logged and never block checkout. (SD-01) |
| NTF-07 | (v1.11) **SMS log:** every SMS sent through the provider is recorded with date/time, receiver, message, source (Registration OTP, Password reset OTP, Checkout OTP, Order received, Admin test), status (**Pending → In Progress → Sent / Failed**), provider transaction ID and error reason. OTP codes are masked. Logging never blocks or fails a send. |
| STF-UI-01 | (v1.11) Header logo height: mobile 2.75rem, tablet 3.5rem, desktop 4rem. |
| STF-UI-02 | (v1.11) Footer shows an icon for each configured social link with a subtle hover lift; footer text is near-white (contrast ≥ 7:1). |
| STF-UI-03 | (v1.11) Product cards and lazily loaded sections fade in and move up once on entering the viewport, including those on the first screen (inline head script before first paint; opacity/transform only, one shared observer, off under reduced motion, visible without JS). Header shortcut icons get the footer icons' hover (coloured disc, lift). |
| WEB-13 | (v1.11) Banner placement **Login page** (Admin → Website content → Login page): picture (900 × 1200 px, cover) and optional heading/text for the side panel of the login / register page on tablets and desktops; without a picture the drawn panel and default wording stay. On by default. Public `GET banners/login/`. |
| STF-UI-05 | (v1.11) Contact page: an icon before each detail (address, phone, email, support hours), social icons, and a Google map from **Map latitude / longitude** in Admin → Settings → Contact & social (both empty = drawn placeholder). The cart page notice for a hidden floating bag is a compact warning-style line. |
| STF-UI-04 | (v1.11) Opening a product page starts at the top; back/forward restores the saved position. |

### 4.15 Storefront pages (STF)

Pages and their purpose, matching the design canvas:

| Page | URL |
|---|---|
| Home | `/` |
| Category / Offers / New arrivals / Search | `/shop/:category` (optional `?sub=slug1,slug2`), `/shop/offers`, `/shop/new`, `/search?q=` |
| Product detail | `/product/:slug` |
| Size guide and calculator | `/size-guide` |
| Cart | `/cart` |
| Checkout and confirmation | `/checkout`, `/order/:number` |
| Login / OTP | `/login` |
| Account (orders, wishlist, addresses, profile) | `/account/**` |
| Track order (guest) | `/track` |
| Contact | `/contact` |
| Static pages | `/pages/:slug` |
| 404 / error | – |

Header: announcement bar, logo, search with suggestions (placeholder types out "Search for <category>…" in turn, static for reduced motion), **WhatsApp** and **Call** icons (NTF-05), **Track Order**, **Find My Size**, wishlist, account, bag count, category bar. Product cards zoom slightly on mouse hover. (v1.6) Mobile: hamburger menu and a bottom navigation (Home, Shop, Wishlist, Bag, Account).

### 4.16 Theme and colour management (THM)

The website's colours are managed centrally as design tokens. The owner changes the primary theme colour in one place and the whole website follows.

| ID | Requirement |
|---|---|
| THM-01 | **Single source of truth:** all theme colours are stored in one singleton record (`core_themesettings`) and exposed as CSS custom properties (design tokens). No other place defines brand colours. |
| THM-02 | **Owner-configurable colours:** the owner picks a **palette** from the built-in library of colour platters (THM-18), or sets a **custom** primary colour (required), accent colour (optional), **Background** (required, default `#F8F4EC`) and **Text** (required, default `#231E1C`) by colour picker or hex code (`#RRGGBB`) (THM-19). |
| THM-03 | **Token roles:** `--color-primary` (main buttons, links, active navigation, selected states, focus ring, toggles, progress, carousel dots), `--color-accent` (badges, highlights, eyebrow text, wishlist heart, small emphasis), plus derived tokens listed in THM-04. The page **Background** and **Text** colours are owner-editable. Every other neutral (surface, cream, border, field, muted, body, tinted tiles) is **derived** from those two by the server (THM-14) so any background stays readable; the footer, announcement bar and status chips remain fixed. The admin portal keeps the Signature neutrals; primary and accent still style both (THM-05). |
| THM-04 | **Automatic derivation:** from the primary colour the system derives `-hover`, `-active`, `-soft` (light tint for backgrounds and chips), and `-contrast` (text colour on primary, auto-chosen black or white for readability). The owner only has to pick one colour; the neutrals follow Background and Text. |
| THM-05 | **Application everywhere:** every themed element on the storefront, checkout, account area, admin portal accents (buttons, active states, links) and printed documents reads colours from the tokens. Components use token names only (Tailwind theme mapped to the CSS variables), never raw hex values. The build/CI includes a check that fails when a raw colour literal appears outside the token definition file. |
| THM-06 | **Delivery without flash:** the Nuxt server fetches the cached public theme (`GET /api/v1/theme/`) and writes a `:root{--color-…}` style block into the page head at render time, so the first paint already uses the saved theme. The defaults in `tokens.css` have zero specificity (`:where(:root)`), so the saved theme always wins; Admin → Theme applies a published theme to open pages at once. The theme response is under 2 KB, is cached, and is invalidated on save. If the API is unavailable, the built-in default theme is used. |
| THM-07 | **Readability guard:** the text colour on primary is chosen automatically to meet contrast 4.5:1. The guard also checks text on background (4.5:1) and primary on background (3:1) (weak links, borders, or focus rings). A failing combination makes the Theme screen show a warning, and publishing needs `confirm_low_contrast` (400 `low_contrast` listing the issues). |
| THM-08 | **Theme screen** (Settings → Theme): palette gallery of swatch cards, colour picker, hex input, a live preview panel (button, secondary button, link, badge, product card, navigation item, form field with focus) that updates instantly, **Save and publish**, **Reset to default**, and "last changed by / at". Changes go live on save without a code change or redeploy. |
| THM-09 | **Permission:** `theme.manage` (held by the Owner; the Owner may grant it to a Staff user, §4.17). |
| THM-10 | **Audit:** every theme save and reset is written to the audit log with the old and new values (or to a minimal change log if the general audit log is simplified, SD-15). |
| THM-11 | **Emails and print:** transactional email templates and the printable invoice use the saved primary colour for buttons and header accents (inlined at send/print time). |
| THM-12 | **Icons and images:** SVG icons use `currentColor` so they follow the tokens. Uploaded images (logo, product photos, banners) are never recoloured. |
| THM-13 | **Default theme:** the palette "Signature" reproduces the current design canvas: primary `#231E1C` (ink) and accent `#8C5550` (muted rose) on warm ivory neutrals. It is the default and **Reset to default** restores it. (Decided: the current colours stay as the default.) |
| THM-14 | **Validation:** the server accepts only valid hex values, normalises them to upper case, and rejects anything else; derived tokens are recomputed on the server so the frontend cannot store inconsistent values. While Background and Text are the defaults only the six palette tokens are emitted and `tokens.css` supplies the neutrals, so existing sites look unchanged. |
| THM-15 | **Out of scope for v1:** a visitor-facing dark-mode toggle, custom or uploaded fonts (only the THM-20 catalogue, v1.9), per-category or per-page colours or fonts, scheduled seasonal themes. |
| THM-16 | **Design system:** the design-system board of the canvas will document the token table (name, role, default value, where used). |
| THM-17 | **Testing:** a test changes the primary colour through the API and asserts that the page head contains the new token values; a visual check confirms buttons, links, navigation and focus rings update. |
| THM-18 | **Palette library (colour platters):** at least 12 curated palettes, each a primary + accent pair (Background and Text keep the defaults) chosen for a women's fashion audience worldwide, shown as swatch cards in the Theme screen. Built-in palettes cannot be deleted. The set listed below was approved by the owner on 2026-11-04. |
| THM-19 | **Custom palettes:** the owner can save up to 5 named custom palettes (primary, accent, background, text), re-apply, rename or delete them. Selecting or saving a palette only changes the live preview; **Save and publish** applies it to the website. |
| THM-20 | **Font pairing catalogue** (v1.9): 9 Google Fonts pairings (heading + body) defined once on the server and returned by the theme API: `signature` Cormorant Garamond + Jost (default, THM-13), `editorial` Playfair Display + Inter, `modern` Montserrat + Open Sans, `friendly` Poppins + Roboto, `classic` Lora + Source Sans 3, `bookish` Merriweather + Lato, `boutique` DM Serif Display + DM Sans, `elegant` Libre Baskerville + Nunito Sans, `clean` Inter + Inter. Each entry: key, label, families and weights, fallback stacks, Google Fonts stylesheet URL (`display=swap`). |
| THM-21 | **Two selections** (v1.9): one pairing for the storefront (public pages, checkout, account area, printed customer documents) and one for the admin panel, each changeable at any time independently. |
| THM-22 | **Font tokens** (v1.9): `--font-display` (headings) and `--font-sans` (body, buttons, inputs). Storefront values on `:root`, admin values override them inside the admin panel. No other place names a font family. |
| THM-23 | **Fonts without flash** (v1.9): the Nuxt server writes the font tokens and one Google Fonts stylesheet link per area (with preconnect) at render time, like THM-06. Only the selected pairing is requested. |
| THM-24 | **Fonts section** (v1.9) on the Theme screen beside the palettes: Storefront and Admin panel selectors, each option previewed in its own fonts ("Aa" + one sentence); Save and Reset fonts with the palette section's messages. |
| THM-25 | **Font validation, permission, audit** (v1.9): only catalogue keys are accepted (400 otherwise); `theme.manage` required; every change audited with old and new keys. |
| THM-26 | **Font defaults and reset** (v1.9): both default to `signature` (existing record set to it on deploy). Reset fonts restores `signature` for both; the general theme Reset restores default colours and fonts together. |
| THM-27 | **Per-pairing tuning** (v1.10): each catalogue font carries its measured x-height and a factor chosen so text is no wider than the original design (factor = original width ÷ font width, max 1.0). The browser applies it with `font-size-adjust` (value = x-height × factor), so computed font sizes, line heights and fixed control heights do not change. `signature` sends none. |
| THM-28 | **Text size** (v1.10) per area: Compact (body ×0.94, headings ×0.94), Standard (default, ×1.0), Large (body ×1.06, headings ×1.03), multiplied into the THM-27 values. No free font-size fields. |
| THM-29 | **Font metric tokens** (v1.10): `--font-display-adjust` (h1–h4, `.font-display`) and `--font-sans-adjust` (body, `.font-sans`), numbers 0.2–1.0 or `none`, computed on the server and range-checked in the browser. |
| THM-30 | **Theme screen** (v1.10): a Text size selector per area in the Fonts section; samples use the tuned values; Save and Reset fonts include text size (Reset → Standard). |
| THM-31 | **Responsive guarantee** (v1.10): no pairing at any text size causes horizontal page scroll, clipped text, labels outside their control, or wrapped single-line button/tab labels at 360, 390, 768, 1024 and 1440 px on the pages in the v1.10 verification plan. Failures are fixed in the component or by lowering the factor, never accepted. Checked with `frontend/scripts/typography-audit.js`. |

**Approved built-in palettes**

| # | Palette | Primary | Accent | Mood |
|---|---|---|---|---|
| 1 | Signature (default) | `#231E1C` | `#8C5550` | Ink and muted rose |
| 2 | Blush Rose | `#A8475A` | `#E8B4B8` | Soft, romantic |
| 3 | Champagne Gold | `#7C6036` | `#C9B28D` | Warm, luxurious |
| 4 | Mauve Lavender | `#6E4F7C` | `#CBB5D8` | Calm, elegant |
| 5 | Burgundy Wine | `#6D1F36` | `#C98A9A` | Rich, classic |
| 6 | Sage Eucalyptus | `#4F6B5A` | `#A9C0A6` | Natural, fresh |
| 7 | Terracotta Peach | `#A8553A` | `#F0B79D` | Earthy, warm |
| 8 | Emerald | `#1F6B54` | `#9ED1BC` | Deep, confident |
| 9 | Navy Pearl | `#1F2F4F` | `#B7C4DC` | Crisp, refined |
| 10 | Mocha Nude | `#6B4E43` | `#D9BDAA` | Neutral, intimate |
| 11 | Coral Pink | `#C4473F` | `#F7B6A8` | Lively, youthful |
| 12 | Plum Berry | `#5B2A58` | `#D79ACB` | Bold, feminine |

### 4.17 Staff permissions (PRM)

The Owner decides what each Staff user can do, and can change it at any time.

| ID | Requirement |
|---|---|
| PRM-01 | **Fixed catalogue, flexible assignment:** the permission codes are those listed in §2.2. The Owner assigns any subset to each Staff user; there are no other roles. New Staff start with the default set shown in §2.2, which the Owner can change before or after saving. |
| PRM-02 | **Permission checklist (Users → Staff → Permissions):** permissions are grouped by area (Orders, Catalogue, Inventory, Marketing, Content, Settings), each with a one-line description, plus **Select all**, **Clear all** and **Reset to default**. Sensitive permissions (`payments.verify`, `inventory.adjust`, `settings.manage`, `theme.manage`, `courier.manage`) show a warning icon and a confirmation when granted. |
| PRM-03 | **Enforcement on the server:** every admin API endpoint declares the permission it needs and checks it on every request from the database, so a change by the Owner takes effect on the Staff user's next request without signing out. A missing permission returns HTTP 403. |
| PRM-04 | **Enforcement in the interface:** menu items, screens, buttons and dashboard widgets appear only for granted permissions (`GET admin/me/` returns the user's permissions); opening a forbidden URL shows a "no access" page. The server stays authoritative. |
| PRM-05 | **Dependencies:** a `.manage` / `.adjust` / `.verify` permission implies the matching view access (e.g., `orders.manage` requires `orders.view`, `courier.manage` requires `courier.view`); the interface and the server enforce this automatically. |
| PRM-06 | **Owner protection:** the Owner always holds every permission, cannot be edited or deactivated by Staff, and the system never allows removal of the last active Owner. |
| PRM-07 | **Audit:** every permission change (who, when, Staff user, added and removed codes) is written to the audit log; deactivating a Staff user blocks sign-in and ends their sessions immediately. |
| PRM-08 | **Testing:** the automated API tests (§9) include a permission matrix: for every admin endpoint, a user with the permission succeeds and a user without it receives 403. |

### 4.18 Courier: Steadfast (CRR, v1.7)

API reference: `docs/STEADFAST_API_NOTES.md`. Steadfast has no sandbox: every booking is a real parcel.

| ID | Requirement |
|---|---|
| CRR-01 | **Courier settings:** Admin → Settings → Courier (`settings.manage`) holds the Steadfast API key, secret key, webhook auth token, base URL (default `https://portal.packzy.com/api/v1`) and "Book Steadfast parcels automatically when an order is confirmed" (default on). Keys and token are shown to `settings.manage` only, masked with a show/hide toggle (v1.8); they are never logged, audited or public. The page shows the webhook URL to copy. No courier environment variables. |
| CRR-02 | **Test connection:** calls `/ping` and a key-checked read (`/get_balance`) and reports which failed (`POST admin/courier/ping/`, `settings.manage`, rate-limited). |
| CRR-03 | **Auto-booking:** when an order becomes Confirmed and auto-booking is on, it is booked in the background (Django-Q); confirming never waits for Steadfast. Payload: `invoice` = order number, recipient name and phone, address = address line, thana, district, `cod_amount` = total for COD and 0 for bKash/Nagad, `note` = order note, `item_description` = "<N> items, <total weight> kg". On success the consignment ID, tracking code and tracking link are stored and the order moves to **Shipping** automatically (timeline entry by System, status email). |
| CRR-04 | **Booking safety:** only a Confirmed order with no Steadfast parcel is booked. The invoice is the order number and Steadfast refuses duplicate invoices, so a retry cannot double-book. |
| CRR-05 | **Booking failure:** a 400/422 rejection keeps the order Confirmed, flagged **Booking failed** with Steadfast's field messages, with no automatic retry. Unreachable/5xx is retried by the queue (3 attempts), then flagged. Staff fix the data and press **Book with Steadfast** (`courier.manage`) or ship by hand (ORD-10). |
| CRR-06 | **Lockout guard:** a 401/403 stops every courier call and shows "Steadfast keys rejected, check Admin → Settings → Courier" until the courier settings are saved again. 401/403 are never retried (Steadfast locks a client out for 60 minutes after 10 failures). |
| CRR-07 | **Bulk booking:** the admin order list has **Book with Steadfast** for Confirmed, unbooked orders (`courier.manage`), using the bulk endpoint (≤ 500 per request) and reporting each failure per order like bulk Confirm (ORD-07). |
| CRR-08 | **Webhook:** `POST /api/v1/webhooks/steadfast/` requires `Authorization: Bearer <token>` and an `X-Signature` equal to the hex HMAC-SHA256 of the raw body keyed with the token (constant-time compare), else 401. An already-received `Idempotency-Key` is answered 200 and ignored. Events are stored, answered 200 at once and processed in the background. |
| CRR-09 | **Status mapping:** `delivered` → order **Delivered** (COD collected, CHK-10; a `cod_amount` differing from the total adds a staff note). `partial_delivered` → flag **Partly delivered** (ORD-05, staff decide). `cancelled` → flag **Courier returning parcel**; staff mark Returned when goods arrive. `exceptional` → flag **Lost or damaged at courier**. `hold` → flag **On hold at courier**. `pending`, `in_review`, `unknown`, `*_approval_pending` → recorded only. Delivered or Returned orders are never changed by a later event. Steadfast status and flag show on order detail and the order list. |
| CRR-10 | **Tracking steps:** each `tracking_update` event and each step from `trackings_by_invoice` is stored once (message, time). `return_request`, `cancel_request`, `consignment_update` and `pickup_request` add a staff-only timeline note; other events are stored only. |
| CRR-11 | **Reconciliation:** every 2 hours a scheduled task re-reads Shipping orders with no courier update for 6 hours (`status_by_cid`, CRR-09), back-fills missing steps, and for parcels flagged returning shows **Parcel back with you** once the return status says received. |
| CRR-12 | **Courier dashboard:** Admin → Courier (`courier.view`): Steadfast balance; the four dashboard states (In review, Delivery processing, COD processing, Return requests) with count and COD, each opening a paged parcel list; stats per outcome for a date range. Cached 60 seconds. |
| CRR-13 | **Pickups:** Admin → Courier → Pickups (`courier.manage`) sends a pickup request and lists those sent from this system. |
| CRR-14 | **Returns:** Admin → Courier → Returns lists Steadfast return requests (`courier.view`); order detail has **Ask Steadfast to return** for a Shipping order (`courier.manage`, reason 3–500 characters); Steadfast's refusal message is shown. |
| CRR-15 | **Customer delivery record:** on a Draft or Confirmed order, **Check delivery record** (`orders.view`) shows Steadfast's cross-merchant record for the phone: delivered and cancelled ratios, volume band, report count and categories. No data shows "No record", never 0. Fetched only on the button press; a signal for staff, not a decision. |
| CRR-16 | **Customer tracking:** Track Order (ACC-09) and the account order page (ACC-06) show the courier steps newest first and a **Track on Steadfast** link, read from our database only. |

---

## 5. Business rules summary

1. Prices are BDT, VAT inclusive. Compare-at price must exceed price to count as a discount.
2. Delivery fee = Inside Dhaka fee or Outside Dhaka fee from settings, chosen by the customer's area.
3. A Draft does not touch stock; Confirm deducts it; Cancel-after-Confirm and a whole-order Return restore it.
4. bKash/Nagad orders need a Verified payment before Confirm; the owner verifies by matching TrxID against the merchant statement.
5. A TrxID can be used once per method.
6. Draft orders hold no stock; Drafts older than 24 hours (configurable) are highlighted for staff; cancellation is manual.
7. Customers can cancel only before Shipping.
8. One coupon per order; usage counts at placement and is released on cancel.
9. Stock never goes below zero; every stock change is logged.
10. Order totals are frozen at placement; later price changes never alter existing orders.
11. Orders, payments, and stock movements are never hard-deleted.
12. Product photos, banners, carousel slides, logo, and company data are managed only through the admin portal.
13. Theme colours are defined only as tokens in one place; changing the primary colour in the admin Theme screen updates the whole website with no code change.
14. Registration is optional; guests can always check out and track an order by order number + phone.
15. A product belongs to one category and optionally one sub-category of that category; the sub-category filter on a category page replaces the category filter.

---

## 6. Data model

Fields shown are the main ones; all tables also have `id`, `created_at`, `updated_at`.

**accounts_user** — phone (unique system-wide when present; required for customers), email (unique when present; required for staff), password (hashed), full_name, role (`customer`, `owner`, `staff`), is_active, phone_verified, birthday, failed_login_count, locked_until, last_login.
**accounts_address** — user, label, recipient_name, phone, area (`inside_dhaka`/`outside_dhaka`), district, thana, address_line, is_default.
**accounts_staffpermission** — user, code; unique (user, code).
**accounts_otp** — phone, purpose (`register`, `reset`), code_hash, expires_at, attempts, consumed_at, sent_at.

**core_sitesettings (singleton)** — all fields listed in SET-01..05 and SET-09, plus the SMS settings (ACC-02, NTF-02): `mimsms_api_key` (shown to settings.manage only, never audited), `mimsms_username`, `mimsms_sender_name`, `mimsms_url` (default `https://api.mimsms.com/api/V2/SMS`), `sms_order_enabled`.
**core_mediaasset** — file, kind (`product`, `carousel`, `banner`, `category`, `logo`, `video_thumb`, `page`), alt_text, width, height, uploaded_by.
**core_carouselslide** — media, eyebrow, heading, subtext, button_label, link_type, link_value, sort, is_active.
**core_banner** — placement (`home_promo`, `home_offer`, `signature`, `popup`), media, heading, text, button_label, link, is_active. (v1.6)
**core_video** — title, url, thumbnail, sort, is_active.
**core_announcement** — text, link, is_active, sort.
*(No* `core_homesection` *table: the home layout is fixed, SD-17.)*
**core_trustitem** — icon, title, text, sort, is_active.
**core_page** — slug, title, body, is_active.
**core_themesettings (singleton)** — palette (nullable FK; null means custom), primary_hex, accent_hex (nullable), background_hex, text_hex (varchar 7), tokens (json, derived), storefront_font, admin_font (catalogue keys, default `signature`, v1.9), storefront_text_size, admin_text_size (`compact`/`standard`/`large`, default `standard`, v1.10), updated_by.
**core_themepalette** — name, primary_hex, accent_hex, background_hex, text_hex (varchar 7), is_builtin, sort, is_active, created_by (built-in rows seeded; up to 5 custom rows).
**core_contactmessage** — name, phone, email, subject, message, is_handled, handled_by.
**core_subscriber** — email, subscribed_at.
**core_auditlog** — user, action, model, object_id, before (json), after (json), ip_masked.

**catalog_category** — name, slug, description, tile_media, sort, is_active, seo_title, seo_description.
**catalog_subcategory** — category, name, slug, sort, is_active; unique (category, slug) and (category, lower(name)).
**catalog_product** — name, slug, category, subcategory (nullable, must belong to category), short_desc, description, care_notes, collection, uom, price, compare_at_price, sku_prefix, is_active, is_new, is_signature, is_offer, is_bestseller (v1.6), tags, seo fields, weight_grams (default 100, v1.7).
**catalog_productimage** — product, media, color (optional), is_primary, sort.
**catalog_variant** — product, size_label, color_name, color_hex, sku (unique), price_override, cost_price (optional), on_hand, is_active, weight_grams (nullable override, v1.7).
**catalog_sizechart** — name, type, rows (json).

**inventory_stockmovement** — variant, delta_on_hand, on_hand_after, reason, order, lot_reference, remarks, user.

*(No server-side cart tables: the cart is browser-only, SD-04.)*
**shop_wishlistitem** — user, product, created_at.
**shop_coupon** — code, description, type, value, max_discount, min_subtotal, starts_at, ends_at, usage_limit, per_customer_limit, scope, categories, products, includes_discounted, is_active, used_count.
**shop_order** — number, user (nullable), guest_email, status, name, phone, email, area, district, thana, address_line, note, subtotal, coupon_code, coupon_discount, delivery_fee, total, payment_method, courier, tracking_ref, placed_at, confirmed_at, shipped_at, delivered_at, cancelled_at, cancel_reason, returned_at, return_reason, idempotency_key.
**shop_orderitem** — order, variant, product_name, variant_label, sku, unit_price, quantity, line_total, weight_grams (snapshot, v1.7).
**shop_orderstatuslog** — order, from_status, to_status, user, note.
**shop_payment** — order, method, amount, sender_number, trx_id, status, verified_by, verified_at, reject_reason, note; unique (method, trx_id) where trx_id is not null.

**courier_shipment** (v1.7) — order (one-to-one), consignment_id (unique), tracking_code, tracking_link, courier_status, status_at, attention (blank/booking_failed/hold/partial/returning/returned_to_merchant/exceptional), last_error, booked_at, booked_by.
**courier_event** — order, kind (status/tracking), status, message, occurred_at, source (booking/webhook/poll); unique (order, kind, message, occurred_at).
**courier_webhookreceipt** — idempotency_key (unique), notification_type, payload, received_at, processed_at, error.
**courier_pickuprequest** — the request fields, steadfast id, status, requested_by.
`core_sitesettings` adds the CRR-01 fields (keys shown to settings.manage only and never audited, v1.8) and a lockout marker.

*(No visitor-event table: analytics are handled by GTM + GA4, SD-03.)*

Indexes: order number, order status/date, variant SKU, product slug, payment (method, trx_id), movement (variant, created_at).

---

## 7. API summary (REST, JSON)

Public (`/api/v1/`):
`GET settings/`, `GET theme/` (cached design tokens; v1.9 adds `fonts.storefront` and `fonts.admin`; v1.10 adds `display_adjust`, `sans_adjust`, `text_size` to each), `GET home/` (carousel, banners, signature_banner, popup, sections, categories, bestsellers, trust, videos), `GET categories/` (with nested sub-categories and product counts), `GET products/` (filters incl. `category`, `sub`, sort, paging), `GET products/{slug}/`, `GET search/suggest/?q=`, `GET size-charts/`, `POST auth/register/` (sends SMS OTP), `POST auth/register/verify/`, `POST auth/login/`, `POST auth/logout/`, `POST auth/password/forgot/` (sends SMS OTP), `POST auth/password/reset/`, `GET/PATCH me/`, `CRUD me/addresses/`, `GET/POST/DELETE me/wishlist/`, `POST cart/validate/`, `POST coupons/validate/`, `POST checkout/` (idempotent), `GET orders/` (mine), `GET orders/{number}/`, `POST orders/{number}/cancel/`, `POST track/` (with `courier_steps[]`, `tracking_link`, v1.7), `POST webhooks/steadfast/` (v1.7, signed), `POST contact/`, `POST newsletter/`, `GET pages/{slug}/`.

Admin (`/api/v1/admin/`, staff only):
`auth/login`, `dashboard/`, `orders/` (+ `{id}/transition/`, `{id}/payment/verify|reject/`, `bulk-transition/`), `products/` CRUD, `products/{id}/variants/`, `products/{id}/images/`, `categories/` (with nested `subcategories[]`), `inventory/` (list, `adjust/`, `movements/`), `coupons/`, `reports/*`, `website/*` (carousel, banners incl. `?placement=` filter, videos, announcements, sections, pages, trust), `settings/`, `settings/sms-test/` (POST, v1.6), `theme/` (GET, PUT; v1.9 adds `storefront_font`, `admin_font`, `font_pairings`; v1.10 adds `storefront_text_size`, `admin_text_size`, `text_sizes`), `theme/reset/` (POST) and `theme/palettes/` (list, create and delete custom), `users/`, `users/{id}/permissions/` (GET, PUT), `permissions/` (catalogue), `me/` (own permissions), `insights/*`, `contact-messages/`, `audit-log/`, and (v1.7) `courier/ping/`, `courier/dashboard/`, `courier/parcel-states/{state}/`, `courier/orders/{id}/book/`, `courier/orders/{id}/refresh/`, `courier/orders/{id}/return/`, `courier/bulk-book/`, `courier/pickups/`, `courier/returns/` (+ `{id}/`), `courier/fraud-check/?phone=`; `orders/` adds `courier_status`, `attention`, `?attention=` filter and `total_weight_grams`.

Conventions: pagination `?page=&page_size=`, errors as `{code, message, fields{}}`, HTTP 400/401/403/404/409 (stock/state conflicts)/429.

---

## 8. User interface requirements

| ID | Requirement |
|---|---|
| UI-01 | Visual identity follows the design canvas and design system: warm ivory/cream/champagne/muted-rose palette (the default theme; primary and accent colours are owner-configurable, §4.16), display serif plus clean sans, square corners, spacious editorial layout, large imagery, subtle hover. |
| UI-02 | Responsive breakpoints: mobile 360+, tablet 768+, desktop 1280+. Touch targets at least 44 px. |
| UI-03 | Every list and data view has loading skeletons, empty states, and error states. |
| UI-04 | Placeholder garment art from the design is used only in development; production uses uploaded photos. |
| UI-05 | Images lazy-load with explicit dimensions to avoid layout shift. |
| UI-06 | Forms validate inline, keep user input on error, and use accessible labels and error text. Every admin form marks mandatory fields with `*` and optional ones with `(Optional)`, validates against the API's limits, and moves focus to the first problem. |
| UI-07 | Language: English v1; text strings are kept in a message catalogue to allow Bangla later. |
| UI-08 | Design additions to be applied to the canvas before frontend work: Track Order and Find My Size in header, WhatsApp/Messenger links in the footer, discount badges, Quick Add, mobile bottom navigation, registration with SMS OTP, login and forgot-password screens, cookie consent banner, "Showing X of Y / Load more", payment-pending states on order pages. |
| UI-09 | No colour value is hard-coded in any page, component or stylesheet; all colours come from the theme tokens defined in §4.16. The design-system board of the canvas will list the tokens. |
| UI-10 | **Design changes required by v1.2 (to be applied to the canvas after the owner approves this version):** (1) category page filter shows the Sub-category group instead of categories (Listing and Shop-* boards); (2) Add/Edit Category form with sub-category rows and Add/Edit Product form with dependent Sub-category drop-down (Admin Products and Admin Website boards); (3) Auth board: register (name, mobile, password, optional email), SMS OTP step, login by mobile + password, forgot password; (4) Admin Website: fixed home layout, two banners, no section toggles or scheduling; (5) Admin Insights: wishlist insight plus GA4 link, remove visitor tracing and abandoned carts; (6) Admin Inventory: remove the Reserved column; (7) Admin Orders: remove partial-return controls, add print invoice/slip pages; (8) Users screen with two roles; (9) Sitemap and requirement-coverage board updated; (10) Footer: WhatsApp and Messenger links plus support hours in the Contact column; (11) Theme screen with the palette gallery and custom palettes; (12) Users screen with the Staff permission checklist. |

---

## 9. Non-functional requirements

| Area | Requirement |
|---|---|
| Performance | No numeric performance targets in v1 (SD-28). Good practice applies: lazy-loaded responsive WebP images via Nuxt Image, pagination, and caching of public settings, theme and home responses. |
| Scalability | Designed for up to 5,000 products, 50,000 orders/year, 100 concurrent shoppers on one server. |
| Security | HTTPS only; HSTS; secure, HTTP-only, SameSite cookies; CSRF protection; password hashing (Argon2/PBKDF2); OTP codes stored hashed; rate limiting on SMS OTP (per mobile number and per IP), login, forgot password, coupon, contact, tracking, and cart-validate endpoints; upload validation (type, size, image decode); output escaping; permission checks on every admin endpoint; no secrets in code. |
| Privacy | Personal data limited to what orders need; cookie consent before analytics; account anonymisation on request; no personal data sent to GTM/GA4; GA4 retention set in GA4. |
| Reliability | A backup script `backup.sh --mode all|db-only|media-only` (default `all`): `db-only` dumps PostgreSQL, `media-only` archives the uploaded media folder, `all` does both; the daily schedule runs `all`; the last 14 backups are kept; restore procedure documented. No uptime target in v1 (SD-28). |
| Data integrity | All stock and order changes in transactions with row locking; idempotent checkout. |
| Maintainability | Code formatted and linted (Ruff/Black, ESLint/Prettier); typed frontend; migration files committed; README in each repo. |
| Testability | **100% API test coverage on the Django side (SD-28 decision):** every API endpoint and HTTP method has automated tests covering success, validation errors, authentication and permission failures (anonymous, customer, Staff, Owner) and not-found/conflict cases. A CI test enumerates the URL configuration and fails if any route has no test, so API QA is confirmed from the test report. Business-logic unit tests cover stock, order transitions, coupon and fee math. Frontend: component tests for the cart and one end-to-end happy path. |
| Accessibility | Basics only in v1 (SD-28): labels, alt text, keyboard focus, and colour contrast (theme guard THM-07). No formal WCAG audit target. |
| SEO | Clean slugs, per-page title/meta, Open Graph tags, `sitemap.xml`, `robots.txt` (admin disallowed), structured data (Product, Breadcrumb). structured data and Open Graph included. GTM loads only after consent. |
| Observability | Structured logs and the health endpoint `/api/v1/health/`. No error-tracking service in v1 (SD-28). |
| Browser support | As §2.3. |
| Localisation | Currency formatted as ৳1,250; dates in `DD MMM YYYY`; timezone Asia/Dhaka. |

---

## 10. Validation rules (selected)

- Phone: `^01[3-9]\d{8}$`; stored normalised without spaces (+880 accepted and normalised).
- Email: standard format, lower-cased (optional for customers).
- Mobile number for registration: same pattern as Phone; normalised before the check; unique system-wide.
- Password: at least 8 characters.
- Sub-category name: 2–40 characters, unique within its category (case-insensitive).
- TrxID: 8–12 alphanumeric characters, upper-cased.
- Price: ≥ 0, up to 2 decimals; compare-at > price.
- Quantity per line: 1–10; stock check on server.
- SKU: unique, uppercase, letters/digits/dash.
- Weight: whole grams 1–30,000 ("Weight must be between 1 and 30,000 grams."), v1.7.
- Slug: lowercase letters/digits/dash, unique.
- Image: JPG/PNG/WebP, ≤ 5 MB, at least 300 px on the long side for products.
- Coupon code: 4–20 characters, letters/digits.
- Order cancel reason, return reason, adjustment reason: required, 3–300 characters.

---

## 11. Error handling and edge cases

- **Last item race:** two customers order the last piece (there is no reservation, SD-07); both Drafts are accepted, the first Confirm succeeds and the second Confirm is blocked with "insufficient stock"; staff contact that customer and cancel the order.
- **Price change during checkout:** the server uses the current price; if it differs from the displayed one the customer must re-confirm.
- **Payment rejected:** the order remains Draft; the customer sees "payment could not be verified" with contact options until staff resolve it.
- **Stale Drafts:** unpaid Drafts stay until staff cancel them; they hold no stock.
- **Image upload failure:** an error is shown and the form keeps all other fields.
- **Email failure:** logged; the user sees success on their action; staff can resend a notice from the order page.
- **Settings missing:** if payment numbers are empty, bKash/Nagad are hidden at checkout.
- **Order with deactivated product:** order history still shows the snapshot.
- **Returns:** whole-order only; damaged items are corrected with a manual stock adjustment.
- **Double click / network retry:** protected by idempotency key.
- **SMS OTP not received:** the user can resend after 60 seconds within the limits; if the SMS gateway fails the user sees a message and the contact details, and guest checkout stays available.
- **localStorage unavailable or corrupt:** the cart falls back to memory or is reset without a crash (CRT-07).
- **Cookie consent declined:** analytics stay off and the store works normally.
- **Deactivated sub-category:** its products remain listed under the category.

---

## 12. Acceptance criteria (key scenarios)

1. Owner uploads a logo, three carousel slides, and edits the address; the storefront reflects them without code change.
2. Owner creates a product with two variants and four photos; it appears in its category with the correct discount badge.
3. Customer places a bKash order; stock is unchanged; the order is Draft with a Pending payment.
4. Owner verifies the TrxID; Confirm succeeds; on hand drops by the ordered quantities.
5. Confirm on an order whose payment is Pending is rejected with an explanation.
6. A duplicate TrxID is rejected at checkout.
7. Cancel after Confirm increases on hand; cancel in Draft changes no stock.
8. A Draft older than 24 h is highlighted as stale in the order list and on the dashboard; stock is unaffected.
9. A returned order restocks all its items; the movement log shows every step with user and time.
10. Changing delivery fees in settings changes the next checkout total but not existing orders.
11. A Staff user can open only the areas the Owner has granted; the Owner can open everything.
12. A customer registers with name, mobile, password and an SMS OTP (wrong OTPs lock after 5 attempts), logs in with mobile + password, and resets a forgotten password via SMS OTP; a guest places an order and tracks it by order number + phone.
13. Category pages show only that category; filters survive page reload through the URL.
14. Coupon `WELCOME10` applies 10% to eligible lines and is released when its order is cancelled.
15. The Owner changes the primary colour in Settings → Theme and saves; buttons, links, active navigation, selected chips, focus rings, and admin accents on every page show the new colour after reload, without a code change or redeploy.
16. Choosing a low-contrast primary shows a warning, the text-on-primary colour flips automatically, and the owner must confirm.
17. "Reset to default" restores the default theme everywhere.
18. The CI colour check fails if a raw hex colour is added to a component.
19. A Staff user without `theme.manage` cannot open the Theme screen; with it, they can.
20. The browser cart survives reload and tab changes; corrupt storage is cleared without an error; a price or stock change is flagged at the cart and at checkout; `cart/validate` is rate-limited and checkout recomputes all prices.
21. After the visitor accepts cookies, GTM loads and tracked buttons raise `ui_click` events with `button_name` and `page_path` visible in GA4; after Decline nothing from Google loads.
22. The Owner adds the sub-categories Maternity Bra, Air Bra and Tube Bra while creating or editing the Bras category; the product form's Sub-category drop-down then lists only those for Bras and clears when the category changes.
23. On the Bras page the filter shows sub-category checkboxes instead of the category list; selecting Air Bra and Tube Bra shows only their products; clearing shows all Bras; reload keeps the selection through the URL.
24. The Django test report shows every API route tested; CI fails when a route has no test.
25. The invoice and delivery-slip pages open from the order and print cleanly from the browser.
26. Images display as resized WebP generated by Nuxt Image from the stored original.
27. In Settings → Theme the owner selects the "Mocha Nude" palette, sees it in the live preview, publishes it, and the whole website (including emails and admin accents) uses it; "Reset to default" restores Signature; the owner can save, re-apply and delete a custom palette.
28. The Owner removes `orders.manage` from a Staff user: on that user's next request the Cancel/Confirm controls disappear and the API returns 403; adding `coupons.manage` makes the Coupons menu appear without re-login; the Staff user cannot open Users or the audit log.
29. Registering with a mobile number that already exists (customer or Staff) is rejected; after registration with a verified number, that number's earlier guest orders appear in the new account's history, and guest tracking by order number + phone still works.
30. `backup.sh --mode db-only` creates only a database dump, `--mode media-only` only a media archive, and `--mode all` (the default) both; the last 14 backups are kept.
31. A new product saved without a weight gets 100 g; a variant with 250 g overrides it; an order line for that variant keeps 250 g after the variant changes to 300 g; the delivery slip shows the total weight.
32. Staff confirm a COD order with auto-booking on; Steadfast (mocked) returns a consignment; the order moves to Shipping with courier Steadfast and the tracking code, `cod_amount` = order total, timeline by System.
33. Steadfast rejects the phone (400): the order stays Confirmed, flagged Booking failed with the field message; after correcting the phone, Book with Steadfast books it.
34. Steadfast answers 401: no further courier call is made until the courier settings are saved; the Courier page shows the keys-rejected message.
35. A webhook with a wrong `X-Signature` gets 401 and changes nothing; the same valid event sent twice with one `Idempotency-Key` is processed once.
36. A `delivered` webhook moves a Shipping COD order to Delivered with COD collected; a `cancelled` webhook flags it Courier returning parcel without changing status or stock.
37. With no webhook for 6 hours, reconciliation reads `delivered` and moves the order to Delivered, back-filling two tracking steps without duplicates.
38. A guest tracking by order number + phone sees the courier steps and the Track on Steadfast link; no Steadfast call is made.
39. Bulk Book with Steadfast on 3 Confirmed orders, one with a duplicate invoice: two move to Shipping, the third is reported with its error.
40. A Staff user with `courier.view` only opens the Courier dashboard but gets 403 on booking, pickups and creating returns; removing `courier.view` hides the Courier menu.
41. The owner sets the storefront fonts to Editorial: after reload, home headings use Playfair Display and body Inter; the admin panel keeps its own pairing and no other pairing's stylesheet is requested.
42. The owner sets the admin panel fonts to Clean: admin headings and text use Inter; the storefront is unchanged.
43. `storefront_font = "comic"` is rejected with 400; a Staff user without `theme.manage` gets 403; a valid change is audited with old and new keys.
44. Reset fonts (or the general theme Reset) returns both selections to Signature.
45. The first server-rendered HTML of a storefront page contains the selected font tokens and stylesheet link (no flash).
46. Elegant + Standard: every storefront page at 360 px has no horizontal scroll and the home hero heading breaks onto the same number of lines as with Signature.
47. Admin panel at Large: tables, tabs and buttons keep their height and no label wraps at 1024 px.
48. Signature + Standard renders exactly as v1.9 (no `font-size-adjust` applied).
49. An invalid text size is rejected with 400; a valid change is audited; Reset returns Standard.
50. The typography audit script reports zero failures for all 27 combinations on the listed pages and widths.
51. A guest with a new number gets a 4-digit SMS, enters it, and the order is placed; the number is now verified.
52. The same number orders again as a guest without an OTP.
53. Three wrong codes kill the code; resend before 60 s is refused; a 6th code in an hour is refused without an SMS.
54. A guest order for an unverified number is rejected (`phone_unverified`).
55. A Bank order with a reference ID is Draft with a Pending payment in the verify queue; a duplicate reference is refused.
56. Every SMS appears in Admin → SMS log with source and final status; OTP codes are masked; a gateway failure shows Failed and the customer flow is unaffected.
57. With auto-book on, Move to Shipping is disabled while booking is queued; afterwards the order is Shipping with the Steadfast code and no second parcel exists.
58. With auto-book off, Move to Shipping books with Steadfast; "Ship with another courier" ships by hand.
59. Buy → colour + size → Checkout Now opens checkout with the item; both buttons are disabled until both options are chosen.
60. On a 375 px phone the hero image shows uncropped and slides change without a blank frame.
61. Pinch and + / − zoom the product photo; opening a product from a scrolled listing lands at the top.

---

## 13. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Manual payment checks are slow or error-prone | Pending queue, TrxID uniqueness, order timeline notes; gateway later |
| Overselling (no reservation, SD-07) | Confirm-time recheck under a row lock; staff contact the customer when stock is insufficient |
| SMS OTP delay or failure, or SMS credit running out | Resend cooldown, per-mobile and per-IP limits, Owner watches the SMS balance, guest checkout always available |
| MiMSMS API approval takes time (business documents required); calls from a non-whitelisted IP are refused | Start approval early; tests replace the sender; whitelist the server IP in the MiMSMS panel before go-live (the error names the IP to add) |
| Browser-only cart is lost when the device changes | Accepted trade-off (SD-04); robust validation at checkout |
| Large uploaded images slow the site | Request-time resizing with caching (Nuxt Image) and an upload size limit |
| Owner changes critical settings by mistake | Owner-only access, audit log, confirmation on payment/fee changes |
| Scope growth | Out-of-scope list in §1.3; changes handled through SRS versions |
| Owner picks an unreadable colour | Automatic contrast text, warning and confirmation, reset button (THM-07, THM-08) |
| Budget overrun from advanced features | Scope decision register (§1.6) with simpler alternatives for each costly feature |
| Steadfast has no sandbox; every booking is a real parcel (v1.7) | All tests mock Steadfast; first live test is one low-value order with the owner, cancelled in the Steadfast dashboard |
| Webhook needs a public HTTPS domain; repeated bad keys lock the client out for 60 minutes | Reconciliation every 2 hours (CRR-11); lockout guard stops calls after a 401/403 (CRR-06) |

---

## 14. Traceability to the original requirement draft

Covered: Django + Docker; Nuxt storefront; product categories; order stages (Draft, Confirm, Shipping, Delivered, Cancelled, Returned); bKash/Nagad with transaction number; coupons; size chart and calculator; cart persistence; wishlist; contact form email; inventory adjustment with lot/shipment reference and remarks; reports; website management; wishlist insight; visitor and cart analytics through GTM + GA4 (decisions SD-03, SD-04).

---

## 15. Open items and future phases

Decided: admin at `/admin/` inside Nuxt; SMS OTP via MiMSMS for optional customer registration; free-delivery threshold deferred; Nuxt.js; two repositories; owner scope decisions of 2026-11-04 (§1.6, all items decided); configurable staff permissions; default theme stays the current colours; stale-draft auto-cancel not required; WhatsApp/Messenger links in the footer.

Decisions of 2026-11-04 (owner): couriers expected are Steadfast, RedX and Pathao (integration is a future phase; staff enter courier name and tracking number by hand for now); staff 2FA is out of scope; hosting provider and domain will be chosen later; no SMS account exists yet, so the system ships with a pluggable SMS provider interface and a fake (console/log) sender selected by `SMS_PROVIDER=fake`, and the MiMSMS provider is configured later through environment settings or the admin Settings screen (**withdrawn 2026-11-15, v1.6:** the MiMSMS account is active; SMS is configured only in Admin → Settings → SMS and the fake sender is removed); the GTM ID and GA4 property stay as placeholders until supplied; the 12 colour palettes (THM-18) are approved as final.

Decisions of 2026-11-15 (owner, v1.7): product weight first (existing products 100 g, never blank), then Steadfast courier integration; a successful booking moves the order to Shipping automatically; a Steadfast `cancelled` only flags the order and staff mark Returned; admin pages for the Courier dashboard, pickups, returns, customer delivery record and bulk booking; Steadfast payouts are not included; credentials in Admin → Settings → Courier, write-only. This supersedes "courier integration is a future phase" for Steadfast.

Decision of 2026-11-17 (owner, v1.8): saved SMS and courier credentials are visible in Admin → Settings (masked, with a show/hide toggle) so the form never looks empty; they stay out of the audit log, logs and public APIs. Supersedes "write-only" in ACC-02 and CRR-01.

Still to confirm (owner will supply later): hosting provider (the domain is bought); the hosting server's IP to whitelist in MiMSMS; GTM ID and GA4 property.

Future phases: free-delivery threshold, courier API for RedX and Pathao, Steadfast payouts, Bangla, order-status and marketing SMS, WhatsApp notifications, reviews, loyalty, product CSV import, payment gateway, bundles, flash sales.

---

## 16. Implementation plan

**Note:** milestone durations will be re-baselined after the owner decides the scope items in §1.6.

**Repos and workflow:** two repos on `main` plus feature branches; Conventional Commits; PR per milestone; CI runs lint and tests. Both repos are already initialised with GitHub remotes.

| Milestone | Backend | Frontend | Done when |
|---|---|---|---|
| **M0 Foundation** (3–4 d) | Django project, settings by env, custom User (customer/owner/staff), Docker + Postgres, DRF, health endpoint, Django-Q2 worker container, CI with the route-coverage test gate | Nuxt 3 + Tailwind wired to CSS-variable theme tokens (THM-03, THM-05, no raw hex lint), Nuxt Image, layouts (store, admin), API client, auth guard for `/admin` | `docker compose up` runs all services; health check and empty pages render |
| **M1 Settings, theme, permissions and content** (8–10 d) | Staff permission catalogue and enforcement (PRM), ThemeSettings with derivation, palette library and public/admin theme API (THM), SiteSettings (incl. GTM ID), MediaAsset (original upload and validation), carousel, two banners, videos, pages, public settings/home API, admin APIs, audit log | Admin shell, login, permission-aware sidebar, Users and permissions screen, Settings, Theme (palette gallery, live preview) and Website screens; SSR theme injection; storefront header/footer/home from API; Nuxt Image for all images | Owner changes logo, address, slides and the primary colour from admin and the site updates (scenarios 1, 15–19, 26–28) |
| **M2 Catalogue** (5–7 d) | Category with sub-categories, Product (category + sub-category), Variant, ProductImage, size charts, listing/filter/search APIs with `sub` filter, admin CRUD with multi-upload | Product admin (dependent Sub-category drop-down), Category admin (sub-category rows); storefront home, category listing with sub-category filter, product page, size guide, search | Create a product with photos and see it filtered correctly by category and sub-category (scenarios 2, 13, 22, 23) |
| **M3 Cart, checkout, orders, payments, inventory** (6–8 d) | Cart validate API, coupons, checkout transaction (no stock hold), Order/Payment/StockMovement, transitions (Confirm deducts; cancel-after-confirm and return restore), stale-Draft highlight, emails via Django-Q2 | Browser cart with robust storage, cart, checkout, confirmation, print-styled invoice and slip; admin Orders, Payment verification, Inventory and adjustment, Coupons | Acceptance scenarios 3–10, 14, 20 and 25 pass |
| **M4 Accounts and engagement** (4–5 d) | Registration with SMS OTP (MiMSMS provider), login, forgot password, addresses, wishlist, guest tracking, contact, newsletter | Register/OTP, login, forgot password, account area, wishlist, track page, contact, footer WhatsApp/Messenger links | Scenarios 12 and 29 pass |
| **M5 Reports, analytics, hardening** (5–7 d) | Reports, rate limits, backup script with the `--mode` flag, API tests completed to 100% route coverage | Dashboard, Reports, Insights (wishlist + GA4 link), cookie consent, GTM/GA4 dataLayer events and `data-track` buttons, SEO, accessibility basics | 100% API route coverage gate green; scenarios 21, 24 and 30 pass |
| **M6 Release** (2–3 d) | Production Docker, Nginx, TLS, env docs, seed data, migration and restore runbook | Production build, error pages | Staging approved by owner, then production |
| **M7 Weight and Steadfast** (v1.7) | Phase 1: product/variant weight, order-line snapshot (CAT-24..26). Phase 2: `apps/courier` client, booking, webhook, reconciliation, courier admin API, permissions (CRR-01..16) | Product weight fields, slip weight; Settings → Courier, Courier dashboard, pickups, returns, order courier block, bulk booking, track page courier steps | Scenarios 31–40 pass; one live parcel booked and cancelled with the owner |

Order of work inside each milestone: models and migrations → services/business rules with tests → API → admin UI → storefront UI → review against the design canvas.

Pre-requisite before M2: apply the §UI-08 design additions to the canvas (Track Order/Find My Size, footer WhatsApp/Messenger links, badges, Quick Add, bottom nav, registration/OTP/forgot-password screens, payment-pending states) and the UI-10 design changes (sub-category filter, category and product admin forms, simplified Website and Insights admin).

---

## 17. Approval

| Role | Name | Date | Signature |
|---|---|---|---|
| Owner | | | |
| Developer | | | |
