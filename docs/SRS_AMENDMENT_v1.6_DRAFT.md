# SRS amendment v1.6 (approved, applied)

**Approved by the owner on 2026-11-15 and applied to `SRS.md` as v1.6.** This file is kept as the change record.

## 1. SMS: live MiMSMS API, order-received SMS (changes §1 scope, ACC-02, NTF-02, §6, §7, §13, §15)

- **§1 out of scope.** "SMS order/marketing notifications (only OTP SMS is in v1)" becomes "SMS marketing
  notifications"; "order-status notifications by SMS" stays out of scope. The **order-received SMS** is in scope.
- **ACC-02 (replaces).** SMS goes through the **MiMSMS JSON API** (`POST <API URL>`, body `apiKey`, `userName`,
  `senderName`, `transactionType` = `T`, `mobileNumber` = `8801XXXXXXXXX`, `message`). A send succeeds when the reply
  has `statusCode` `"200"`. API key, username, sender name and API URL are entered in **Admin → Settings → SMS**:
  no SMS environment variables, no provider switch, **no fake sender**. Incomplete settings make every send fail with
  "SMS is not configured". The API key is write-only (never returned, logged or audited). MiMSMS only accepts calls
  from **whitelisted server IPs**: a refused IP is reported with the IP to add. Admin → Settings → SMS has
  **Send test SMS** (`POST admin/settings/sms-test/`, `settings.manage`, 10 per hour).
- **NTF-02 (adds).** On order placement the customer gets one SMS (ASCII, one part):
  `<Company>: Order <number> received. Total Tk <total>. We will call you to confirm. Thank you!`
  The owner can switch it off ("Send order confirmation SMS", default on). OTP SMS cannot be switched off.
- **NTF-06.** Unchanged: the order SMS goes through the Django-Q2 queue (3 attempts); failures are logged and never
  block checkout.
- **§6 `core_sitesettings`.** Adds `mimsms_api_key`, `mimsms_username`, `mimsms_sender_name`, `mimsms_url` (default
  `https://api.mimsms.com/api/V2/SMS`) and `sms_order_enabled`.
- **§13 risks.** "develop against a mock provider" becomes "tests replace the sender; whitelist the server IP in
  MiMSMS before go-live".
- **§15.** The 2026-11-04 fake-sender decision is withdrawn; MiMSMS credentials are no longer an open item (the
  hosting server's IP must be whitelisted in MiMSMS once hosting is bought).

## 2. Header contact icons (changes NTF-05, §4.15 header)

- **NTF-05 (replaces the last sentence).** The header shows a **WhatsApp** icon (`wa.me/<whatsapp_number>`, which
  opens the WhatsApp app when installed) and a **Call** icon (`tel:` link to the first support phone) immediately
  before Track Order, each with a tooltip and each hidden when its number is blank. National numbers (`01…`) are
  converted to the international form. There is still no floating chat button.

## 3. Home page and storefront (changes WEB-01, WEB-02, WEB-03, WEB-06, CAT-02, §6; new CAT-23, WEB-11)

- **WEB-01.** The hero carousel advances every **3 seconds** (was 6).
- **WEB-02 (replaces).** Four fixed banner placements, edit only: `home_promo` and `home_offer` (shown side by side,
  whole and uncropped in the uploaded picture's own proportions), `signature` (the big Signature collection panel;
  the line-art panel is the fallback when no image is set) and `popup` (WEB-11). A banner has image, heading, text,
  button label, link, on/off.
- **WEB-03 (adds).** The home category carousel keeps its layout (six tiles on desktop, arrows beside the heading)
  and moves right-to-left one tile every **3 seconds** in an endless loop. It can be dragged with the mouse (with
  flick momentum) or swiped on touch screens. It pauses on hover, focus, touch and drag, and does not move for
  visitors who prefer reduced motion.
- **CAT-02 / §6 `catalog_product`.** Section flags add `is_bestseller`.
- **CAT-23 (new) Best seller.** Products are marked by hand ("Best Seller" under "Show in sections", or the bulk
  action). The home "Offers & favourites" section has three tabs: Special offer · Best seller · Our favourites. A tab
  with no products is hidden.
- **WEB-11 (new) Promotional Ads Panel.** Admin → Website content → "Promotional Ads Panel" edits one popup: image
  (required to show), heading, text, button label and link, on/off. While it is on, the home page opens it as a
  dialog shortly after **every full load**. It closes with ×, Esc, the backdrop or "Continue browsing".
- **Storefront layout.** The header search placeholder types out the whole phrase "Search for <category>…" in turn
  (static for reduced motion); the search sits further left on wide screens to fit the extra icons. Product cards
  zoom slightly on mouse hover. The size guide page and the footer are more compact.
- **§6 `core_banner`.** Placements `home_promo`, `home_offer`, `signature`, `popup`; adds `button_label`.
- **§7 `GET home/`.** Adds `bestsellers`, `signature_banner`, `popup`.

## 4. Analytics event contract (changes INS-05)

- Ecommerce events use the GA4 shape `{event, ecommerce: {currency: "BDT", value, items[]}}`, preceded by
  `{ecommerce: null}`. Items carry `item_id`, `item_name`, `item_variant`, `price`, `quantity`, `item_category`.
  `purchase` adds `transaction_id`, `shipping` and `coupon`, and is pushed once per order (at order placement).
  New plain events `login` and `sign_up` (`method: "phone"`). `page_view` is pushed once per page.
- The personal-data filter keeps `item_name`, `item_list_name` and `button_name`; every other key containing "name"
  is still dropped.
- The importable GTM container is `frontend/docs/gtm-container.json` (setup in `frontend/TRACKING.md`).
