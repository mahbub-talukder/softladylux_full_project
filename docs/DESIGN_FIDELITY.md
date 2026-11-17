# Design fidelity checklist (storefront, Phase 1)

Method: board source read from the canvas, then design vs live rendered at 1440 px and 390 px with headless Chrome. Screenshots in `/tmp/shots/`.

| Screen | Status | Intentional differences (reason) |
|---|---|---|
| Foundations (tokens, type, buttons, inputs, tiles, line art) | Done | Stage-chip and success colours added as tokens |
| Header, search, mobile menu | Done | Announcement bar shown only when set in admin (SET) |
| Footer, newsletter band | Done | Placeholders stay in brackets until the owner supplies data (SET-08) |
| Home | Done | No Hot deal/Best seller flags in the SRS, so Offers/Favourites tabs use offer and signature flags |
| Listing + ProductCard + filters | Done | Mobile filter drawer; extra "In stock only" filter (CAT-13) |
| Product page | Done | Single colour-by-size selector (SRS variants) instead of band + cup rows; sticky add-to-bag on mobile |
| Cart | Done | No "Move to wishlist" (SRS CRT-01); delivery-area picker kept (CRT-04) |
| Checkout + confirmation | Done | Full site header kept instead of the slim checkout header; step bar added |
| Login / register / OTP / reset | Done | Reset is two steps (phone, then code + password) per SRS ACC-11 |
| Account | Done | Several saved addresses (SRS ACC-08) instead of one; delete-account confirm is inline |
| Track order | Done | No board; reuses the account tracking panel |
| Contact, Size guide | Done | Map block is a placeholder until a map link exists |
| Cookie banner, bottom nav | Done | |
| Motion | Done | 0.26 s page fade, content fade-in; off with prefers-reduced-motion |
| Admin shell: sidebar, mobile header + slide-in menu, page background | Done | |
| Admin dashboard | Done | KPI notes are generic text (API has no comparison figures) |
| Admin orders + order panel | Done | Bulk bar keeps courier/reason inputs (ORD-10); panel is a full-screen sheet on phones |
| Admin products, inventory, coupons, reports, categories, messages | Done by shared admin styles (tables, chips, buttons, tabs, inputs) | Checked at 1440; reports at 390 |
| Admin settings, website content | Done | Two-column field grid on desktop |
| Admin theme, staff & permissions | Matches boards; no layout change needed | |
| Print pages (invoice, slip) | Not restyled | Existing token-based print sheet; review separately |
