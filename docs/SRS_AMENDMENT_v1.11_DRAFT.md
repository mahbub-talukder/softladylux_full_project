# SRS amendment v1.11 (draft, client request of 2026-11-23)

**Status:** approved by the owner 2026-11-23 and applied to `SRS.md` v1.11. This file is the change
record and the implementation plan. Source: `additional_requiemnt_from_client.md`.

Owner decisions taken 2026-11-23 (all recommended options):

| # | Question | Decision |
|---|---|---|
| D1 | Hero on phones, "full frame" | The mobile hero box takes the mobile image's own aspect ratio: no crop, no bars |
| D2 | Buy dialog → Checkout Now | Add to bag, then open `/checkout` with the whole bag |
| D3 | Bank payment input | The customer pays first, then enters the bank transaction/reference ID and the account holder name; staff verify or reject it like bKash/Nagad |
| D4 | Move to Shipping | One Steadfast-aware button (see ORD-14) |
| D5 | SMS log statuses | Pending, In Progress, Sent **and Failed** (with the error reason) |
| D6 | Checkout OTP skip | Logged-in customers, and guests whose number belongs to a registered account or is in the verified table, skip the OTP |
| D7 | Logo size | All breakpoints scale up: desktop 3rem → 4rem, tablet 2.75 → 3.5rem, mobile 2.25 → 2.75rem |
| D8 | Payment logos | Official bKash and Nagad SVG marks, sourced by the developer and confirmed by the owner before release; a neutral bank icon |

---

## 1. What the audit found (2026-11-23)

- **Carousel flash:** `HomeHero.vue` keys each rendered slide by `offset-id`. After every move all three slide nodes are
  destroyed and rebuilt, and their CSS background images reload. The empty `bg-cream` box shows for a moment: that is
  the "white flash".
- **Mobile crop:** the hero box has a fixed height (320 px on phones) and uses `background-size: cover`, so portrait or
  square mobile images lose their sides. This is by design today and is changed by D1.
- **SMS:** every message goes through `apps.core.sms.send_sms()`. Callers are the register/reset OTP
  (`accounts/otp.py`), the order-received SMS (`shop/notifications.py`) and the admin test SMS. One central log point
  is enough.
- **OTP:** `accounts/otp.py` already has hashed codes, expiry, attempt lock, resend wait and hourly/daily caps. The
  checkout OTP reuses it.
- **Move to Shipping:** this is today's manual ORD-10 fallback (free-text courier + tracking, no booking). Duplicate
  Steadfast bookings are already impossible: `book()` locks the order row and refuses when already booked or not
  Confirmed. The real issue is the workflow. With auto-book on, staff can click it while the booking is still queued.
  The order then ships "by hand" and the queued booking quietly skips.

## 2. Requirement changes

### Storefront

| ID | Change |
|---|---|
| STF-UI-01 (UI-02 note) | Header logo heights per D7. |
| CAT-10 (changed) | Below `md`, the search panel shows **Products** first, then Suggestions/Browse. Wider screens keep two columns. |
| WEB-01 (changed) | Slides change with a seamless slide: no blank frame between images. Neighbouring images are preloaded. |
| WEB-12 (new) | On phones (< 640 px) the hero picture box takes the aspect ratio of the mobile image (or of the desktop image when no mobile image is set), clamped between 4:5 and 16:9, so the full image shows uncropped. Admin shows a recommended mobile ratio (4:5). |
| CAT-27 (new) | Product image zoom on the product page: + / − buttons (1× to 4×, step 0.5) and a reset button on all screens; two-finger pinch zoom and drag-to-pan on touch; Ctrl/⌘ + mouse wheel zoom on desktop (plain scrolling still scrolls the page); double-tap or double-click toggles 2×. Changing photo resets the zoom. |
| CAT-12 (replaced) | The product card button is **Buy** with a cart icon. It opens a compact product dialog (bottom sheet on phones, centred modal on wider screens): photo, name, price, colour choices, size chips (sold-out sizes disabled), size-guide link, quantity (1 to stock, max per CRT rules). Two buttons, **Add to Cart** (adds, closes the dialog, confirms with the live region/toast) and **Checkout Now** (adds, opens `/checkout`, D2), each with an icon, both disabled until every required option is chosen. A product with a single variant has it preselected. |
| STF-UI-02 (new) | Footer: a social icon for each configured link (Facebook, Instagram, YouTube, TikTok, Messenger, WhatsApp), with a subtle hover lift and fill and a visible focus ring. Footer text is near-white (contrast ≥ 7:1 on the dark footer). |
| STF-UI-03 (new) | Product cards and lazily loaded sections fade in and move up (≈ 400 ms, 12 px, staggered ≤ 60 ms per card) the first time they enter the viewport. Only `opacity`/`transform` animate. One shared IntersectionObserver is used. The animation is off under `prefers-reduced-motion`, and content stays visible when JS has not run. |
| STF-UI-04 (new) | Opening a product page always starts at the top. Browser back/forward restores the saved scroll position. |

### Checkout and payments

| ID | Change |
|---|---|
| CHK-11 (new) | **Guest mobile verification.** Before a guest places an order, the checkout mobile number must be verified with a **4-digit SMS OTP** unless it is already verified (D6). Code valid 5 min; 3 wrong attempts kill a code; resend after 60 s; at most 5 codes per number per hour and 10 per day; per-IP rate limit. The code is stored hashed. A successful check adds the number to **verified phones**. `place_order` rejects a guest order with an unverified number (`phone_unverified`). Owner switch `checkout_otp_enabled` (Admin → Settings → SMS, default on) so guests can still order while SMS is not set up. |
| CHK-04 (changed) | Adds **Bank**: the checkout shows bank name, account name, account number, branch and routing number from settings plus the payment instructions. The customer enters the **transaction/reference ID** (letters, digits and `-`, 6–30) and the **account holder name**. Both are required. |
| PAY-01/02/03/05/08 (changed) | Method list becomes bKash, Nagad, Bank, COD. Bank follows the bKash/Nagad Pending → Verified/Rejected flow and appears in the verify queue. Reference ID is unique per method. |
| SET (changed) | Admin → Settings → Payments adds Bank fields (bank name, account name, account number, branch, routing number). Bank is hidden at checkout while the account number is empty (§11). |
| CHK-12 (new) | Payment method cards show the official bKash / Nagad marks (D8) and a bank icon beside the name. |

### Admin

| ID | Change |
|---|---|
| ADM-13 (new) | The product create/edit page has a second **Save** button directly before the SEO section. It runs the same action (same label, state and validation) as the top button, which stays unchanged. |
| ORD-14 (new, D4) | On a Confirmed order, **Move to Shipping**: (a) when Steadfast is configured, books the parcel with Steadfast (same as CRR-06 manual booking, needs `courier.manage`). While an auto-booking is queued or running it shows "Booking with Steadfast…" and is disabled. After a booking failure it reads "Retry booking". (b) a secondary **Ship with another courier** link opens the manual courier + tracking form (ORD-10 fallback). When Steadfast is not configured, only the manual form is shown. The server keeps refusing a second booking and refuses a manual ship while a booking is in progress (`booking_in_progress`). |
| NTF-07 (new) | **SMS log.** Every SMS sent through the provider is recorded: date/time, receiver number, message, source section (Registration OTP, Password reset OTP, Checkout OTP, Order received, Admin test), status (**Pending → In Progress → Sent / Failed**), provider transaction ID, error reason. OTP codes are masked in the stored text (`****`). Writing the log never blocks or fails a send. |
| ADM-14 (new) | Admin → **SMS log** page: newest first, filters by status, source and date range, search by number, pagination, message shown in full on row open. Read-only. New permission `sms_log.view` (PRM). |

## 3. Data model (§6)

- `core_smslog`: id, created_at, receiver (11), message (text), source (choice), status (choice), provider_ref, error,
  sent_at. Index on (created_at), (receiver), (status).
- `accounts_verifiedphone`: phone (unique, 11), verified_at, source (`checkout` / `registration`).
- `accounts_otp.purpose` adds `checkout`.
- `core_sitesettings` adds `bank_name`, `bank_account_name`, `bank_account_number`, `bank_branch`, `bank_routing_number`.
- `shop_payment`/`shop_order` method choice adds `bank`. `payment.sender_name` (new, bank account holder). `trx_id` is
  widened to 30.
- `courier_shipment` already holds the booking state. A new `queued_at` marks an auto-booking in flight for ORD-14.

## 4. API (§7)

- `POST /api/checkout/otp/` `{phone}` → `{status: "sent" | "verified", resend_in}` (`verified` = skip, D6).
- `POST /api/checkout/otp/verify/` `{phone, code}` → `{token}`.
- `POST /api/checkout/` refuses unverified guest numbers (409 `phone_unverified`). It accepts `payment_method: "bank"` with `trx_id` + `sender_name`.
- `GET /api/admin/sms-log/?status=&source=&from=&to=&q=&page=`
- `POST /api/admin/orders/{id}/ship/` is unchanged (manual). The Steadfast book endpoint is unchanged.

## 5. Acceptance scenarios (§12)

51. A guest with a new number gets a 4-digit SMS, enters it, and the order is placed. The number is now verified.
52. The same number orders again as a guest: no OTP is asked.
53. Three wrong codes lock the code. Resend before 60 s is refused. A 6th code in an hour is refused, with no SMS sent.
54. A guest order for an unverified number is rejected (`phone_unverified`).
55. With bank details set, a customer pays by Bank with a reference ID. The order is Draft with a Pending payment and
    appears in the verify queue. A duplicate reference ID is refused.
56. Every SMS (OTP, order received, test) appears in Admin → SMS log with source and final status. OTP codes are masked.
    A gateway failure shows Failed with the reason, and the customer flow is unaffected.
57. With auto-book on, Move to Shipping is disabled while the booking is queued. After it books, the order is Shipping
    with the Steadfast tracking code. No second parcel is created.
58. With auto-book off, Move to Shipping on a Confirmed order books with Steadfast. "Ship with another courier" ships
    by hand.
59. Buy → choose colour and size → Checkout Now opens checkout with the item in the bag. Both buttons are disabled
    until both options are chosen.
60. On a 375 px phone the hero image shows uncropped, and slides change with no blank frame.
61. On the product page, pinch and + / − zoom the photo. Opening a product from a scrolled listing lands at the top.

## 6. Implementation order

Backend and frontend each get branch `feat/v1.11-client-requests`. Order: models + migrations → rules + tests → API →
admin UI → storefront UI → browser check at 375 px and 1280 px.

1. SMS log (NTF-07, ADM-14): model, logging wrapper in `send_sms(source=…)`, admin page.
2. Checkout OTP (CHK-11): `otp.py` purpose `checkout` (4-digit, 3 attempts), verified phones, owner switch, checkout step UI.
3. Bank payment (CHK-04, PAY, SET) and payment logos (CHK-12).
4. Quick storefront items: logo, search order, footer, fade-in-up, product-page scroll.
5. Carousel (WEB-01, WEB-12).
6. Product zoom (CAT-27).
7. Buy dialog (CAT-12).
8. Admin second Save (ADM-13) and Move to Shipping (ORD-14).

After each step: backend `pytest`, frontend `vitest`, lint, typecheck. `TRACEABILITY.md` is updated.
