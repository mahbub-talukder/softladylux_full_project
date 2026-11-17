# SRS amendment v1.7 (draft, owner decisions of 2026-11-15)

**Status:** approved by the owner 2026-11-16 and applied to `SRS.md` v1.7. This file is the change
record. Steadfast API reference: `docs/STEADFAST_API_NOTES.md`.

Build order: **Part A (product weight) first, then Part B (Steadfast)**. Part B depends on Part A.

---

## Part A. Product weight (changes CAT-03, ORD-08, §6, §7; new CAT-24..CAT-26)

- **CAT-24 (new) Product weight.** Every product has a weight in **grams** (whole number, 1–30,000), entered on the
  product form. New products default to 100 g. **Existing products are set to 100 g** when the change is deployed.
  The weight is never blank.
- **CAT-25 (new) Variant weight override.** Each variant may have its own weight (same bounds). When blank it uses
  the product weight. Effective weight = variant weight, or the product weight when the variant has none. Admin
  product form: a "Weight (g)" column on the variant table, where blank means "same as product".
- **CAT-26 (new) Weight on orders.** At placement each order line copies the variant's effective weight (snapshot,
  rule 10). The order's total weight = Σ line weight × quantity. It appears on admin order detail and on the
  delivery slip (ORD-08). Order lines placed before this change are set to 100 g each.
- **§6 `catalog_product`** adds `weight_grams` (default 100). **`catalog_variant`** adds `weight_grams` (nullable).
  **`shop_orderitem`** adds `weight_grams` (default 100).
- **§7.** Admin `products/` and variant payloads add `weight_grams`. Admin `orders/{id}` adds line
  `weight_grams` and `total_weight_grams`. Public payloads do not change.
- **§10.** Weight: integer 1–30,000; message "Weight must be between 1 and 30,000 grams."

## Part B. Steadfast courier API (changes §1, §2.2, ORD-04, ORD-10, §6, §7, §9, §13, §15; new CRR-01..CRR-16)

### B.1 Scope

- **§1 out of scope.** Change "courier API integration" to "courier API integration other than Steadfast (RedX,
  Pathao)". **Steadfast** is now in scope. Steadfast payouts are not part of v1.7.
- **§15.** The decision of 2026-11-04 ("integration is a future phase") is superseded for Steadfast by the decisions
  of 2026-11-15 below.
- **ORD-10 (replaces).** When a Confirmed order is booked with Steadfast, the order moves to Shipping with
  courier "Steadfast" and the Steadfast tracking code as the tracking reference (CRR-03). Staff can still move an
  order to Shipping by hand with a free-text courier and tracking reference. This is the fallback when auto-booking
  is off or has failed, and the way to ship with other couriers.

### B.2 Settings and access

- **CRR-01 Courier settings.** **Admin → Settings → Courier** (`settings.manage`) holds:
  - the Steadfast API key, secret key and webhook auth token
  - the base URL (default `https://portal.packzy.com/api/v1`)
  - "Book Steadfast parcels automatically when an order is confirmed" (default **on**)

  The keys and the token are write-only, the same as the MiMSMS key in v1.6: they are never returned by any API,
  logged or audited. The page shows "saved" or "not set" for each and the webhook URL to copy. There are no
  courier environment variables.
- **CRR-02 Test connection.** A **Test connection** button calls Steadfast's `/ping` and a key-checked read
  (`/get_balance`) and reports which one failed (`POST admin/courier/ping/`, `settings.manage`, rate-limited).
- **§2.2 permissions** add two codes, giving 17 in total:
  - `courier.view` (group Orders): Courier dashboard, Steadfast parcel lists and return requests. Default for new
    Staff: **on**. Not sensitive.
  - `courier.manage` (group Orders): book or retry a parcel, bulk booking, refresh, pickup requests, return
    requests. Default **off**. Sensitive.
  - PRM-05: `courier.manage` implies `courier.view`.

### B.3 Booking

- **CRR-03 Auto-booking.**
  - **Trigger.** When an order becomes Confirmed and auto-booking is on, the system books it with Steadfast in
    the background (Django-Q). Confirming never waits for Steadfast.
  - **Payload:**
    - `invoice` = order number
    - recipient name and phone
    - address = address line, thana, district
    - `cod_amount` = order total for COD, 0 for bKash/Nagad
    - `note` = order note
    - `item_description` = "<N> items, <total weight> kg"
  - **On success.** The consignment ID, tracking code and tracking link are stored and the order moves to
    **Shipping** automatically. This writes the usual timeline entry by "System" and the status email.
- **CRR-04 Booking safety.**
  - A parcel is booked only for a Confirmed order with no Steadfast parcel yet.
  - The invoice is the order number and Steadfast refuses duplicate invoices, so a retry cannot double-book.
- **CRR-05 Booking failure.**
  - If Steadfast rejects the data (400/422), the order stays Confirmed and is flagged **"Booking failed"** with
    Steadfast's field messages. It is not retried automatically.
  - If Steadfast is unreachable or answers 5xx, the booking is retried by the queue (3 attempts in all), then
    flagged.
  - Staff fix the address or phone and press **Book with Steadfast** (`courier.manage`), or ship by hand (ORD-10).
- **CRR-06 Lockout guard.** A 401 or 403 from Steadfast stops every courier call and shows "Steadfast keys rejected,
  check Admin → Settings → Courier" on the Courier pages and on order detail. Calls resume when the courier settings
  are saved again. The system never retries a 401 or 403, because Steadfast locks the client out for 60 minutes
  after 10 failures.
- **CRR-07 Bulk booking.** The admin order list has a **Book with Steadfast** bulk action for Confirmed orders that
  are not booked (`courier.manage`). It uses Steadfast's bulk endpoint (up to 500 per request) and reports each
  failure per order, like bulk Confirm (ORD-07). Successful orders move to Shipping.

### B.4 Status updates

- **CRR-08 Webhook.** `POST /api/v1/webhooks/steadfast/` accepts Steadfast's events:
  - It requires `Authorization: Bearer <token>` and an `X-Signature` equal to the hex HMAC-SHA256 of the raw body,
    keyed with the webhook token and compared in constant time. Otherwise it answers 401.
  - An event whose `Idempotency-Key` was already received is answered 200 and ignored.
  - Every event is stored, answered 200 at once, and processed in the background.
- **CRR-09 Status mapping.**

  | Steadfast `delivery_status` | Our order | Flag |
  |---|---|---|
  | `pending`, `unknown`, `in_review`, `hold`, `*_approval_pending` | no change | `hold` → "On hold at courier" |
  | `delivered` | → **Delivered** (COD marked collected, CHK-10) | if `cod_amount` ≠ order total: staff note |
  | `partial_delivered` | no change | **"Partly delivered"** (ORD-05: staff decide; partial returns are not supported) |
  | `cancelled` | no change | **"Courier returning parcel"**; staff mark Returned when the goods arrive (restock) |
  | `exceptional` | no change | **"Lost or damaged at courier"** |

  The Steadfast status and flag are shown on order detail and in the order list. A Delivered or Returned order is
  never changed by a later event.
- **CRR-10 Tracking steps.** Each `tracking_update` event, and each step read from `trackings_by_invoice`, is stored
  once as a courier step (message and time). Other events (`return_request`, `cancel_request`,
  `consignment_update`, `pickup_request`) add a staff-only timeline note. Remaining events are stored only.
- **CRR-11 Reconciliation.** Every 2 hours a scheduled task does three things:
  - re-reads the status of Shipping orders with no courier update for 6 hours (`status_by_cid`), applying CRR-09
  - back-fills missing steps (`trackings_by_invoice`)
  - for parcels flagged "Courier returning parcel", reads the return status and shows **"Parcel back with you"**
    once Steadfast reports it received

  This makes a missed webhook harmless and covers environments with no public webhook URL.

### B.5 Admin pages

- **CRR-12 Courier dashboard.** **Admin → Courier** (`courier.view`) shows:
  - the Steadfast balance
  - the four dashboard states (In review, Delivery processing, COD processing, Return requests) with parcel count
    and COD, each opening a paged list of those parcels
  - stats (counts and COD per outcome) for a chosen date range

  Values are read from Steadfast and cached for 60 seconds.
- **CRR-13 Pickups.** **Admin → Courier → Pickups** (`courier.manage`) sends a pickup request (address, location,
  service type, estimated quantity, note) and lists the requests sent from this system.
- **CRR-14 Returns.** **Admin → Courier → Returns** (`courier.view` to list, `courier.manage` to create) lists
  Steadfast return requests with their status. Order detail has **Ask Steadfast to return** for a Shipping order
  (reason, 3–500 characters). Steadfast refuses delivered parcels and duplicate open requests, and its message is
  shown.
- **CRR-15 Customer delivery record.** On a Draft or Confirmed order, **Check delivery record** (`orders.view`) shows
  Steadfast's record for the customer's phone across all merchants:
  - delivered and cancelled ratios
  - volume band
  - report count and categories

  A ratio with no data shows "No record", never 0. It is a signal for staff, not an automatic decision, and it is
  only fetched when the button is pressed.

### B.6 Storefront

- **CRR-16 Customer tracking.** The Track Order page (ACC-09) and the account order page (ACC-06) show the courier
  steps (CRR-10) under the status timeline, newest first, plus a **Track on Steadfast** link. They read from our
  database only and never call Steadfast while the customer waits.
- **ORD-04 (adds).** Once a parcel is booked the order is in Shipping, so the customer Cancel button is already
  gone. Cancelling a booked parcel is done in the Steadfast dashboard, and the resulting `cancelled` event flags the
  order (CRR-09).

### B.7 Data model, API, NFR

- **§6.**
  - `courier_shipment`: order (one-to-one), consignment_id (unique), tracking_code, tracking_link, courier_status,
    status_at, attention (blank / booking_failed / hold / partial / returning / returned_to_merchant / exceptional),
    last_error, booked_at, booked_by.
  - `courier_event`: order, kind (status / tracking), status, message, occurred_at, source (booking / webhook /
    poll). Unique on order + kind + message + occurred_at.
  - `courier_webhookreceipt`: idempotency_key (unique), notification_type, payload, received_at, processed_at,
    error.
  - `courier_pickuprequest`: the request fields, steadfast id, status, requested_by.
  - `core_sitesettings` adds the CRR-01 fields and a lockout marker.
- **§7.** Public adds `POST webhooks/steadfast/`. `GET orders/{number}/` and `POST track/` add `courier_steps[]`
  and `tracking_link`. Admin adds `courier/ping/`, `courier/dashboard/`, `courier/parcel-states/{state}/`,
  `courier/orders/{id}/book/`, `courier/orders/{id}/refresh/`, `courier/orders/{id}/return/`, `courier/bulk-book/`,
  `courier/pickups/`, `courier/returns/` (+ `{id}/`) and `courier/fraud-check/?phone=`. Admin `orders/` adds a
  `courier_status` and `attention` column and a `?attention=` filter.
- **§9 security.** The webhook is rate-limited and signature-checked. Steadfast keys stay on the server only.
- **§13 risks.** Steadfast has no sandbox, so every booking is a real parcel. Automated tests mock every Steadfast
  call. The first live test is one low-value order with the owner, cancelled in the Steadfast dashboard. The webhook
  needs the public HTTPS domain, and until then CRR-11 keeps statuses current.

### B.8 Acceptance scenarios (§12, new)

31. A new product saved without a weight gets 100 g. A variant with 250 g overrides it. An order line placed for that
    variant keeps 250 g after the variant is changed to 300 g. The delivery slip shows the order total weight.
32. Staff confirm a COD order with auto-booking on. Steadfast (mocked) returns a consignment. The order moves to
    Shipping with courier Steadfast and the tracking code, `cod_amount` sent = order total, and the timeline shows
    the change by System.
33. Steadfast rejects the phone (400). The order stays Confirmed, flagged "Booking failed" with the field message.
    After the phone is corrected, **Book with Steadfast** books it.
34. Steadfast answers 401. No further courier call is made until the courier settings are saved. The Courier page
    shows the keys-rejected message.
35. A webhook with a wrong `X-Signature` gets 401 and changes nothing. The same valid event sent twice with one
    `Idempotency-Key` is processed once.
36. A `delivery_status: delivered` webhook moves a Shipping COD order to Delivered and marks COD collected. A
    `cancelled` webhook flags the order "Courier returning parcel" without changing its status or stock.
37. No webhook arrives for a Shipping order for 6 hours. The reconciliation task reads `delivered` and moves it to
    Delivered, and back-fills two tracking steps without duplicating existing ones.
38. A guest tracking by order number + phone sees the courier steps and the Track on Steadfast link. The page makes
    no Steadfast call.
39. Bulk **Book with Steadfast** on 3 Confirmed orders where one has a duplicate invoice: two move to Shipping, and
    the third is reported with its error.
40. A Staff user with `courier.view` only opens the Courier dashboard but gets 403 on booking, pickups and creating
    returns. Removing `courier.view` hides the Courier menu.

### B.9 Traceability and files

- Part A: `apps/catalog` (models, serializers, migration), `apps/shop` (OrderItem snapshot, checkout, admin
  serializer, migration), `pages/admin/products/[id].vue`, `components/admin/PrintSlip.vue`, `OrderPanel.vue`.
- Part B: new `apps/courier` (client, models, services, webhook view, admin views, schedule migration, tests),
  `apps/core` (settings fields, serializer, audit masking), `apps/accounts/permissions.py`, `apps/shop/orders.py`
  (Confirmed hook), `apps/shop/serializers.py`, admin pages under `pages/admin/courier/`, `settings.vue`,
  `orders/index.vue`, `OrderPanel.vue`, `AdminSidebar.vue`, `pages/track.vue`, the account order page.
- Test plan: unit and API tests for every CRR ID and for scenarios 31–40 with Steadfast mocked at one function
  (`apps.courier.steadfast.request`), plus frontend unit tests for the product weight payload and the courier block.
