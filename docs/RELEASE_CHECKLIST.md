# SoftLadyLux: release checklist

"Staging approved by the owner, then production" (SRS §16). Tick each box on staging first. Sign-off is
the owner's; nobody else can approve it.

## A. Before staging

- [ ] `backend/.env` filled from `backend/.env.production.example` and `frontend/.env` from `frontend/.env.production.example`; the environment check passes (warnings understood).
- [ ] TLS certificate files in place (or the provider proxy variant chosen).
- [ ] `docker compose … up -d --build`, all services `healthy`.
- [ ] `create_owner` run; owner can sign in at `/admin/login`.
- [ ] Staging only: `seed_demo` run for realistic content.
- [ ] `scripts/smoke.sh https://staging-domain` passes.

## B. Content the owner must supply (placeholders show `[LIKE THIS]` until then)

- [ ] Settings → Company: name, tagline, logo, favicon, address, city, support phone(s), support email, hours, WhatsApp, Messenger, social links, footer text, copyright.
- [ ] Settings → Payment: bKash and Nagad merchant numbers and instructions; COD on/off.
- [ ] Settings → Delivery fees (Inside / Outside Dhaka) and delivery time text.
- [ ] Settings → Order rules (stale-draft hours, low-stock threshold, order prefix) and SEO defaults.
- [ ] Settings → Analytics: GTM container ID (empty = analytics off).
- [ ] Settings → SMS (MiMSMS) and `.env` SMTP, when accounts exist.
- [ ] Theme colours chosen and published; static pages written (About, Delivery & Returns, Privacy, Terms).
- [ ] Real products with photos, variants and opening stock; category tiles; carousel and banners.

## C. Acceptance scenarios on staging (SRS §12)

Tick when it works as written. Items marked ⚠ depend on things not testable by the developer.

- [ ] 1 Logo, slides and address changed in admin appear on the site.
- [ ] 2 Product with two variants and four photos appears with the right discount badge.
- [ ] 3 bKash order is Draft with a Pending payment and stock unchanged.
- [ ] 4 Verify the TrxID, Confirm succeeds, stock drops.
- [ ] 5 Confirm with a Pending payment is refused with an explanation.
- [ ] 6 A duplicate TrxID is refused at checkout.
- [ ] 7 Cancel after Confirm restores stock; cancel in Draft changes none.
- [ ] 8 A Draft older than the stale limit is highlighted; stock unaffected.
- [ ] 9 A returned order restocks all items; the movement log shows every step.
- [ ] 10 Changing delivery fees changes the next checkout only.
- [ ] 11 A Staff user sees only what the Owner granted.
- [ ] 12 ⚠ Register with SMS OTP, login, forgot password; guest order tracked by number + phone (needs the real SMS provider).
- [ ] 13 Category pages show only that category; filters survive reload.
- [ ] 14 `WELCOME10` applies 10% and is released on cancel.
- [ ] 15 Primary colour change shows on every page after reload.
- [ ] 16 Low-contrast colour warns and flips the button text; owner must confirm.
- [ ] 17 Reset to default restores Signature.
- [ ] 18 CI colour check fails on a raw colour (CI).
- [ ] 19 A Staff user without `theme.manage` cannot open the Theme screen.
- [ ] 20 Cart survives reload and tabs; corrupt storage is cleared; price/stock changes flagged.
- [ ] 21 ⚠ Cookie banner: Accept loads GTM and `ui_click` appears in GA4; Decline loads nothing from Google (needs the real GTM/GA4).
- [ ] 22 Bras sub-categories added; the product form lists only those and clears on category change.
- [ ] 23 Bras page: sub-category filter replaces the category list; survives reload.
- [ ] 24 CI fails when an API route has no test (CI).
- [ ] 25 Invoice and delivery slip open from the order and print cleanly.
- [ ] 26 Images display as resized WebP.
- [ ] 27 Palette gallery, publish, reset; custom palette saved and deleted.
- [ ] 28 Removing `orders.manage` takes effect on the next request; adding `coupons.manage` shows Coupons.
- [ ] 29 Duplicate mobile rejected; guest orders appear after verified registration.
- [ ] 30 `backup.sh` modes produce the right files; last 14 kept; **restore drill done** (RUNBOOK).

## D. Hardening checks

- [ ] HTTP redirects to HTTPS; HSTS and security headers present (`smoke.sh`).
- [ ] Admin and Django-admin paths are not guessable; `ADMIN_URL` is unique.
- [ ] Daily backup service running and a copy leaves the server.
- [ ] A 404 URL and a stopped frontend show the branded pages (not a stack trace).
- [ ] Mobile phone: storefront, checkout, admin dashboard and orders are usable.

## E. Owner sign-off (staging)

- [ ] Owner has reviewed the screens built without a design board: Track Order, admin Messages, Reports tabs (funnel, inventory, coupons), delivery-area report, wishlist "who saved it".
- [ ] Owner approves staging. Name / date: ______________________

## F. Go live

- [ ] Production `backend/.env`, `frontend/.env`, and certificates in place; **do not run** `seed_demo`.
- [ ] Backup taken; `docker compose … up -d --build`; `create_owner`; smoke test passes.
- [ ] Real Settings, products and pages entered; one real test order placed and cancelled.
- [ ] DNS cut over; certificate valid; uptime check on `/api/v1/health/`.
- [ ] Google Tag Manager container set up with the owner's Google account (SRS INS-07) and the GTM ID saved.

## G. After launch

- [ ] First 24 h: watch `logs backend worker`; first backup file exists and copied off.
- [ ] First week: review Reports → Order funnel and the audit log; confirm emails and SMS arrive.
