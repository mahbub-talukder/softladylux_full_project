# Steadfast Courier API: notes and integration plan

Collected 2026-11-15 from the merchant dashboard: `/user/api/guide` (API guide), `/user/webhook/add` (Webhook),
`/user/api` (API keys). No keys or secrets are stored in this file. Keys live only in the server configuration
(see §5).

Status: **reference + proposal**. The SRS v1.4 lists "courier API integration" as **out of scope** (§1, §15) and
ORD-10 says courier/tracking are free text. Building this needs an SRS amendment approved by the owner first.

---

## 1. API facts

| Item | Value |
|---|---|
| Base URL | `https://portal.packzy.com/api/v1` |
| Auth | Headers `Api-Key`, `Secret-Key` on every call; `Content-Type: application/json` on POST. No token/login. |
| Sandbox | **None.** Every `create_order` books a real parcel. Tests must mock HTTP. |
| Rate limits | 1,000 req/min (6,000 for booking). |
| Lockout | 10 auth failures in 5 min from one IP+key → **429 for 60 min, even with correct keys**. Never retry 401. |
| Caching | Status endpoints cached 60 s. Prefer webhooks over polling. |
| Sanitising | `{ } ; < > $` replaced by a space. Long values truncated, not refused (invoice 100, name 100, phone 40, address 490, note 480). |
| Duplicate invoice | Refused, so a retry with the same invoice cannot double-book. |
| Keys | Up to 5 keys per profile, named, revocable. Currently 1 unnamed key on the main account. Create a named key (e.g. "SoftLadyLux website") for this integration. |

Response codes: 200 (read the body, bulk calls report per-item failure inside 200), 400 bad payload / rejected field
(`errors`), 401 bad keys or not your parcel, 403 inactive account / KYC, 422 field rejected, 429 throttled/locked,
500 their fault (retry with same invoice).

### 1.1 Endpoints we need

**`GET /ping`**: no keys. Connectivity check (admin "Test connection").

**`POST /create_order`**: book one parcel.

| Field | Req | Notes |
|---|---|---|
| `invoice` | yes | Letters, digits, `-`, `_`; unique; ≤100. Use `Order.number` (`SLL-YYMMDD-NNNN`). |
| `recipient_name` | yes | ≤100 |
| `recipient_phone` | yes | 11 digits starting `01` |
| `recipient_address` | yes | ≤490 |
| `cod_amount` | yes | BDT; `0` for prepaid; max 1,000,000 |
| `note` | no | ≤480, rider instructions |
| `alternative_phone` | no | 11 digits `01…` |
| `recipient_email` | no | domain is checked, so omitting it is safer |
| `item_description` | no | ≤255 |
| `total_lot` | no | default 1 |
| `delivery_type` | no | 0 home (default), 1 point |
| `exchange` | no | bool, default false |

Success: `{"status":200,"consignment":{"consignment_id":1424107,"invoice":"…","tracking_code":"15BAEB8A",
"tracking_link":"https://steadfast.com.bd/tl/…","status":"in_review",…}}`. Keep `consignment_id`,
`tracking_code`, `tracking_link`. Rejected: `{"status":400,"errors":{…}}` (not booked). Every parcel starts `in_review`.

**`GET /status_by_cid/{consignment_id}`**: `{"status":200,"delivery_status":"delivered"}`. Used for reconciliation.
(Same answer via `/status_by_invoice/{invoice}` and `/status_by_trackingcode/{code}`.)

**`GET /trackings_by_invoice/{invoice}`**: full step list:
`{"tracking":[{"consignment_id":…,"tracking_type":1,"text":"Parcel received at Dhanmondi hub.","created_at":"…"}]}`.
Their docs: "This is what to show a customer asking 'where is my order?'". Used to back-fill the timeline.

### 1.2 Endpoints we do not need (for now)

Bulk booking (we book one per confirmation), `status_with_return_status_by_cid` (only for return-stock reconciliation),
`parcel_states`, `stats`, `create_pickup_request` (pickups arranged in the dashboard), returns, balance/payments,
`police_stations`.

Optional later: **`GET /fraud_check/score/{phone}`** shows a customer's delivered/cancelled ratios across all
merchants. Useful on admin order detail before confirming a COD order. Rate-limited relative to booking volume.
`score`/`level` are always null now; read `delivery_ratio`, `cancellation_ratio`, `volume_band`; null ≠ 0.

### 1.3 Delivery statuses (API)

`in_review` (just created) · `pending` (with courier, not yet attempted) · `hold` · `*_approval_pending` (rider's
claim, **not final**) · `delivered` · `partial_delivered` · `cancelled` (not delivered, coming back) ·
`exceptional` (lost/damaged) · `unknown`.

## 2. Webhook

Configured at `/user/webhook/add`: one HTTPS callback URL per profile + optional auth token
(letters, digits, `- _ . =`). Steadfast POSTs JSON and waits **5 s** for a 2xx.

Headers: `Authorization: Bearer <token>`, `X-Signature` = hex HMAC-SHA256 of the **raw body** keyed with the token,
`Idempotency-Key` (same on retries), `User-Agent: Steadfast-Webhook/1.0`.

Retries: on 5xx/unreachable, after 30 s and 2 min (3 attempts total). **4xx is not retried.**

Events we use:

```json
{"notification_type":"delivery_status","consignment_id":12345,"invoice":"INV-67890","cod_amount":1500.0,
 "status":"delivered","delivery_charge":100.0,"tracking_message":"…","updated_at":"2025-03-02 12:45:30"}
```
`status` ∈ `pending, delivered, partial_delivered, cancelled, unknown`.

```json
{"notification_type":"tracking_update","consignment_id":12345,"invoice":"INV-67890",
 "tracking_message":"Package arrived at the sorting center.","updated_at":"2025-03-02 13:15:00"}
```

Other events (log and acknowledge, no action in v1): `consignment_update`, `cancel_request`, `return_request`,
`return_list_accepted`, `payment_request`, `pickup_request`, `user_update`.

## 3. Phase 1: product weight (before the courier integration)

Owner decision 2026-11-15: add weight first, then integrate Steadfast.

Note: the API guide (checked 2026-11-15) has **no weight field** on `create_order`, so booking does not depend on it.
Weight is still useful because Steadfast's delivery charge depends on parcel weight, staff need it on the delivery
slip, and it can go into `item_description`. Where Steadfast asks for weight (dashboard booking form, plugin,
rate card) is still [unconfirmed].

Proposed shape:
- `catalog_product.weight_grams` (positive int) is the default for all variants. Required on new products; existing
  products stay null with a "weight missing" warning in admin.
- `catalog_variant.weight_grams` (nullable) is an optional per-variant override. Effective weight = variant ?? product.
- `shop_orderitem.weight_grams` is a snapshot at placement (rule 10: history never changes). `shop_order` gets the total
  weight (sum of line weight × qty), shown on admin order detail and the delivery slip.
- Admin product form: weight field (grams) on the product, override on each variant row.

## 4. Recommended integration path (phase 2)

```
Staff confirms order (ORD-01)
  └─ on_commit → Django-Q task book_parcel(order)          [create_order, invoice = order.number]
        ├─ success → save consignment_id, tracking_code, tracking_link; courier="Steadfast";
        │            order → Shipping (auto), timeline entry
        └─ failure → order stays Confirmed, "Courier booking failed: <reason>" shown to staff + Retry button
                     (5xx/timeout: auto-retry; 400/422: no retry, staff fixes address/phone; 401/403: no retry, alert)

Steadfast webhook → POST /api/v1/webhooks/steadfast/
  ├─ verify Bearer token + X-Signature (constant-time), else 401
  ├─ dedupe on Idempotency-Key, store raw event, answer 200 fast; process in Django-Q
  ├─ tracking_update  → add CourierEvent (shown on Track Order + account order page)
  └─ delivery_status
        delivered          → order Delivered (COD collected, CHK-10)
        cancelled          → flag "Courier returning parcel"; staff marks Returned when goods arrive (restock is physical)
        partial_delivered  → flag for staff (partial returns are not supported, ORD-05)
        pending / unknown  → record only

Safety net: scheduled Django-Q task (e.g. every 2 h) polls status_by_cid for Shipping orders with no
update in N hours, and back-fills events from trackings_by_invoice. This also covers dev/staging with no
public webhook URL.

Track Order page (/track, ACC-06/09): reads from our DB only, never calls Steadfast live. Shows our status
timeline + courier steps + the Steadfast tracking_link.
```

Why this shape: one booking call per order and a webhook keep API use tiny (well inside limits). The DB is the
source the customer sees, so the public page never exposes keys, is not affected by Steadfast's 60 s cache, and
cannot trigger the auth lockout. The poller makes missed webhooks harmless.

## 5. Decisions needed from the owner (go into the SRS amendment)

1. **Auto-move to Shipping on booking** (recommended), or keep Confirmed until staff click Ship after handover.
2. **Credentials location**: Admin → Settings → Courier (write-only, like the v1.6 SMS settings; recommended for
   consistency) or environment variables.
3. **`cancelled` from Steadfast**: flag + staff marks Returned (recommended), or auto-Returned with restock.
4. **Staff cancel after booking**: the API has no cancel endpoint. Recommended: block Cancel on a booked order with
   "Cancel it in the Steadfast dashboard first", or allow and log a reminder.
5. **Manual courier still allowed?** Keep ORD-10 free text for RedX/Pathao or "book manually" (recommended: a
   "Book with Steadfast" default plus a manual fallback).
6. Fraud-check panel on admin order detail: now or later.

## 6. Go-live checklist

- Create a named API key ("SoftLadyLux website") in `/user/api`; keep keys only on the server.
- Public HTTPS domain is needed for the webhook (domain not chosen yet, SRS §15). Until then rely on the poller,
  or use a tunnel in staging.
- Generate an auth token in `/user/webhook/add`, set callback `https://<domain>/api/v1/webhooks/steadfast/`.
- First live test: one real low-value order, then cancel it in the Steadfast dashboard.

## 7. Implementation notes (2026-11-16)

- Read on 2026-11-16 for the pickup form: `create_pickup_request` needs `address_id` (from the Steadfast
  Pickup Addresses page) and `police_station_id` (from `/police_stations`); a pending duplicate answers 409.
- **[unconfirmed]** response shapes, read defensively in code: `/police_stations` (list of `{id, name,
  district}` assumed) and `/get_return_requests` (Laravel-style paging assumed).
- Bulk booking uses `/create_order/bulk-order/extended`. Its success entries may carry no `tracking_link`;
  those parcels then show no "Track on Steadfast" link.
