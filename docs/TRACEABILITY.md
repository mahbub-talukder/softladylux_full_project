# Traceability: SRS ID → code → tests

Updated at the end of each milestone. Paths are relative to each repo.

## M0 Foundation
| SRS ID | Backend / frontend code | Tests |
|---|---|---|
| ARC-01 | `backend/config/settings/base.py`, `requirements.txt` | whole suite |
| ARC-02 | `frontend/nuxt.config.ts`, `package.json` | `frontend/tests/theme.test.ts` |
| ARC-03 | `frontend/nuxt.config.ts` (`routeRules`) | build |
| ARC-04 | `frontend/middleware/admin.global.ts`, `layouts/admin.vue` | — (M1 adds guard tests) |
| ARC-05 | `backend/config/urls.py`, `apps/core/urls.py` | `apps/core/tests/test_health.py` |
| ARC-06 | `apps/accounts/authentication.py`, `apps/accounts/tokens.py`, CORS in `base.py` | `test_authentication.py`, `test_cors.py` |
| ARC-08 | `.env.example` (both repos), `base.py` env reads | — |
| ARC-09 | `deploy/docker-compose.yml`, `docker-compose.dev.yml`, `nginx/default.conf` | compose smoke test |
| ARC-10 | `base.py` `Q_CLUSTER`, `worker` service | compose smoke test |
| ARC-11 | `apps/core/models.py` `TimeStampedModel` | `apps/accounts/tests/test_user.py` |
| ARC-12 | `frontend/plugins/theme.server.ts`, `utils/theme.ts` | `tests/theme.test.ts` |
| ACC-02 | `apps/core/sms/` (interface + fake provider) | `apps/core/tests/test_sms.py` |
| ACC-10 | `apps/accounts/models.py` (roles) | `test_user.py` |
| ACC-14 | `apps/accounts/models.py`, `apps/core/phone.py` | `test_user.py`, `test_phone.py` |
| THM-01/03/05, UI-09 | `frontend/assets/css/tokens.css`, `tailwind.config.ts`, `scripts/check-colors.mjs` | `npm run lint` |
| THM-13 | `tokens.css` (Signature defaults) | — |
| §7 conventions | `apps/core/exceptions.py`, `pagination.py` | `test_exceptions.py` |
| §9 Observability, Testability | `apps/core/views.py`, `backend/conftest.py` (route gate), `.github/workflows/ci.yml` | `test_health.py` |

## M1 Settings, theme, permissions and content
| SRS ID | Backend / frontend code | Tests |
|---|---|---|
| §2.2, PRM-01/02/05/06 | `backend/apps/accounts/permissions.py` (catalogue, defaults, dependencies), `models.StaffPermission`; `frontend/pages/admin/users.vue` | `accounts/tests/test_permissions.py`, `test_admin_api.py` |
| PRM-03/04/08 | `permissions.require()`, `apps/accounts/views_admin.py` (`me/`), `frontend/middleware/admin.global.ts`, `utils/adminAccess.ts`, `components/admin/AdminSidebar.vue` | `core/tests/test_permission_matrix.py`, `frontend/tests/adminAccess.test.ts` |
| PRM-07, ACC-10, ACC-03 | `views_admin.py` (login/refresh/logout, lock, user create/deactivate/reset) | `test_admin_api.py` |
| ADM-01/06/10 | `core/views_admin.py` (`AuditLogView`), `core/audit.py`; `pages/admin/{login,users,audit-log,no-access}.vue` | `core/tests/test_admin_website.py`, `test_admin_api.py` |
| SET-01..05, SET-09, SET-06/07/08 | `core/models.SiteSettings`, `serializers.py`, `views_admin.AdminSettingsView`, `views_public.PublicSettingsView`; `pages/admin/settings.vue`, `components/store/StoreFooter.vue` | `core/tests/test_admin_settings_theme.py`, `test_public_api.py` |
| ACC-02 (credentials) | `SiteSettings.mimsms_*` write-only in `AdminSettingsSerializer`; `apps/core/sms` (MiMSMS JSON API) | `test_sms_credentials_write_only_and_not_audited`, `apps/core/tests/test_sms.py` |
| NTF-02 (order SMS, v1.6) | `apps/shop/notifications.send_order_sms` | `apps/shop/tests/test_order_sms.py` |
| NTF-05 (header WhatsApp/Call, v1.6) | `StoreHeader.vue`, `utils/contact.ts` | `frontend/tests/storefrontV16.test.ts` |
| WEB-02 / WEB-11 (banners, promo popup, v1.6) | `Banner` placements, `BannerViewSet ?placement=`, `HomeView`, `StorePromoModal.vue` | `test_banners_fixed_placements_edit_only`, `test_home_popup_and_signature_banner` |
| WEB-03 (category carousel, v1.6) | `components/store/CategoryCarousel.vue` | manual (autoplay, drag, loop) |
| CAT-23 (Best seller, v1.6) | `Product.is_bestseller`, `set_flag`, `HomeView.bestsellers` | `test_home_sections_fill_from_flags`, bulk `set_flag` test |
| INS-05 (GA4 shape, v1.6) | `utils/ecommerce.ts`, `composables/useTrack.ts` | `frontend/tests/storefrontV16.test.ts`, `tests/consent.test.ts` |
| THM-01/02/03/04/07/13/14 | `core/theme.py`, `ThemeSettings`, `views_admin.AdminThemeView/ThemeResetView`; `utils/themeDerive.ts`, `pages/admin/theme.vue` | `core/tests/test_theme.py`, `test_admin_settings_theme.py`, `frontend/tests/themeDerive.test.ts` (server parity) |
| THM-06, ARC-12 | `views_public.PublicThemeView` (<2 KB, cached), `frontend/plugins/theme.server.ts` | `test_public_theme_default_signature_small`; manual SSR check |
| THM-08/09/10/18/19 | `ThemePalette`, `PaletteViewSet`, seed `core/migrations/0002_seed_defaults.py`; theme screen | `test_admin_settings_theme.py` |
| WEB-01..08, WEB-10 | `core/models.py`, `views_admin.py` (website viewsets), `views_public.HomeView/PublicPageView`; `pages/admin/website.vue`, `components/admin/ContentList.vue`, `components/store/*`, `pages/index.vue`, `pages/pages/[slug].vue` | `test_admin_website.py`, `test_public_api.py` |
| WEB-09, SD-02 | `serializers.MediaUploadSerializer`, `components/admin/MediaField.vue`, `utils/media.ts`, `nuxt.config.ts` (`image.dir`) | `test_upload_*`, `frontend/tests/media.test.ts` |
| §9 route gate | `backend/conftest.py` (viewset method filtering, route normalisation) | whole suite |
| Scenarios | 1, 11, 15, 16, 17, 19, 27, 28 (API level + manual SSR check); 18 via `npm run lint` | see above |

Deferred inside M1 scope: `home/` `categories` stays empty until M2 (WEB-03); THM-11 (emails/print colours) until M3; theme/preview visual check of scenario 26 (WebP via Nuxt Image) needs the `media` volume mounted on the frontend container (done in compose; recreate the stack to apply).

## M2 Catalogue
| SRS ID | Backend / frontend code | Tests |
|---|---|---|
| CAT-01, CAT-17, CAT-18, CAT-21 | `backend/apps/catalog/models.py` (Category, SubCategory + constraints), `serializers.CategorySerializer` (nested one-save sub-categories), `views_admin.CategoryViewSet`, seed `migrations/0002_seed.py`; `frontend/pages/admin/categories.vue` | `catalog/tests/test_rules.py`, `test_admin_api.py` |
| CAT-02, CAT-05, CAT-06, CAT-07 | `models.Product` (`discount_pct`, `on_offer`), `services.new_arrivals_q/offers_q`, `unique_slug` | `test_rules.py` |
| CAT-03, ADM-03 (opening stock), INV-08/09 | `models.Variant`, `services.create_variant`, `apps/inventory/{models,services}.py` (immutable `StockMovement`, row-locked `record_movement`) | `test_rules.py`, `test_admin_api.py` |
| CAT-04 | `views_admin.ImageViewSet` (multi-upload, primary, reorder, colour, delete), `services.check_publishable`; `frontend/pages/admin/products/[id].vue` | `test_admin_api.py` |
| CAT-08 | `models.SizeChart`, public + admin `size-charts/`; `frontend/utils/sizeCalc.ts`, `pages/size-guide.vue` | `test_public_api.py`, `frontend/tests/sizeCalc.test.ts` |
| CAT-09, CAT-10, CAT-13 | `catalog/public.py` (filters, sort, facets), `views_public.py` (`products/`, `search/suggest/`); `components/store/ShopListing.vue`, `StoreSearch.vue`, `ProductCard.vue`; `utils/listingQuery.ts` | `test_public_api.py`, `frontend/tests/listingQuery.test.ts` |
| CAT-11, CAT-22 | `public.detail`, `ProductDetailView`; `frontend/pages/product/[slug].vue` (breadcrumb Home > Category > Sub-category) | `test_public_api.py` |
| CAT-14 | `ProductViewSet.perform_destroy` (deactivate when ordered or has stock history); `Product.has_orders()` hook (orders in M3) | `test_admin_api.py` |
| CAT-15 | `ProductViewSet.bulk` / `export`; `frontend/pages/admin/products/index.vue` | `test_admin_api.py` |
| CAT-19 | `services.check_taxonomy`, `ProductSerializer.validate`; dependent drop-down in `products/[id].vue` | `test_rules.py`, `test_admin_api.py` |
| CAT-20 | `public.facets` (`subcategories` vs `categories`), `category` CSV; `ShopListing.vue` filter group swap, `pages/shop/*` | `test_public_api.py` |
| WEB-03, WEB-06 | `views_public.HomeView` (`categories`, `new_arrivals`, `signature`, `offers`); `pages/index.vue` | `core/tests/test_public_api.py`, `catalog/tests/test_public_api.py` |
| PRM-03/05/08 | `require_by_method("products.view","products.manage")`, matrix rows in `core/tests/test_permission_matrix.py` | same |
| §10 image >= 600 px | `core/serializers.MediaUploadSerializer.validate` | `test_image_rules` |
| WEB-09 / scenario 26 | `NuxtImg format="webp"`, `NUXT_IMAGE_DIR=/media` volume | manual: `/_ipx/f_webp,...` returns `image/webp` |
| Scenarios | 2, 13, 22, 23 (API tests + dev-stack run), 26 | see above |

Not in M2 (by plan): Add to bag / Quick Add (M3), wishlist heart (M4), admin screen for size charts (API only), CSV import (CAT-16, later).

## M3 Cart, checkout, orders, payments, inventory, coupons
| SRS ID | Backend / frontend code | Tests |
|---|---|---|
| §9 shared cache, §9 rate limits, CRT-08 throttle | `config/settings/base.py` (`CACHES` database cache, throttle rates), `apps/core/throttles.py`, `scripts/entrypoint.sh` (`createcachetable`) | `core/tests/test_cache.py`, `shop/tests/test_api_public.py` (429 tests) |
| CRT-01/02/07 | `frontend/utils/cart.ts`, `stores/cart.ts`, `plugins/cart.client.ts` | `frontend/tests/cart.test.ts` (22 tests: corrupt/old format, limits, expiry) |
| CRT-03/04/05/08/09 | `apps/shop/cart.py`, `views_public.CartValidateView/CouponValidateView`; `frontend/pages/cart.vue` | `shop/tests/test_api_public.py` |
| CHK-01..CHK-10, rules 2, 5, 10 | `apps/shop/checkout.py`, `views_public.CheckoutView`, `PaymentMethodsView`; `frontend/pages/checkout.vue`, `pages/order/[number].vue` | `shop/tests/test_checkout.py`, `test_api_public.py` |
| CPN-01..CPN-05 | `apps/shop/coupons.py`, `Coupon`, `views_admin.CouponViewSet`; `frontend/pages/admin/coupons.vue` | `shop/tests/test_coupons.py`, `test_api_admin.py` |
| ORD-01..ORD-13, INV-02..06/09 | `apps/shop/orders.py` (locked transitions, `OrderStatusLog`), `views_admin.OrderViewSet`; `frontend/pages/admin/orders/`, `components/admin/OrderPanel.vue` | `shop/tests/test_orders.py` (incl. concurrent confirm), `test_api_admin.py` |
| PAY-01..PAY-08 | `Payment` (unique method+TrxID), `orders.verify/reject/edit_payment` | `test_orders.py`, `test_api_admin.py` |
| INV-07/08/10/11/12 | `apps/inventory/views_admin.py` (list, movements, adjust, CSV); `frontend/pages/admin/inventory.vue` | `test_api_admin.py` |
| ORD-08, SD-11 (invoice, slip) | `components/admin/PrintInvoice.vue`, `PrintSlip.vue`, `layouts/print.vue`, `pages/admin/orders/[id]/*` | manual (print pages load) |
| CAT-12, CAT-14 | `components/store/QuickAdd.vue`, `catalog/public.card()` variants; `Product.has_orders()` | `catalog/tests/*` |
| NTF-02/03/06, THM-11 | `apps/shop/notifications.py`, `templates/shop/email/*`, SMTP env settings | `test_orders.py` (outbox, theme colour, failure never blocks) |
| ACC-09, ORD-04 (guest track + cancel), ACC-06 (mine) | `views_public.TrackView/OrderCancelView/MyOrders*` | `test_api_public.py` |
| Scenarios | 3, 4, 5, 6, 7, 8, 9, 10, 14, 20 (API tests + dev-stack run), 25 (pages load; print not checked in a browser) | see above |

Not in M3 by plan: `/track` page, account order history UI (M4); dashboard widgets (M5); real SMTP provider (env only).

## M4 Accounts and engagement
| SRS ID | Backend / frontend code | Tests |
|---|---|---|
| ACC-01 (register, OTP limits), §9 OTP hashed | `apps/accounts/otp.py` (6 digits, 5 min, 5 attempts, 60 s resend, 5/hour, 10/day, keyed hash), `views_customer.RegisterView/RegisterVerifyView`; `frontend/pages/login.vue`, `utils/otp.ts` | `accounts/tests/test_customer_auth.py`, `frontend/tests/wishlistOtp.test.ts` |
| ACC-02 (SMS via queue, clear failure, provider interface) | `otp.deliver` (Django-Q2 task, `Otp.sms_status`), `OtpStatusView`, `apps/core/sms/mimsms.py` (configuration-driven, unverified), Settings → SMS tab | `test_otp_status_reports_sms_failure`, `core/tests/test_mimsms.py` (mocked HTTP) |
| ACC-03/10/12/14 | `LoginView` (5 failures lock 15 min, remember-me), staff/customer separation, password rules, unique mobile | `test_customer_auth.py` |
| ACC-11 (forgot/reset, other sessions signed out) | `ForgotPasswordView`, `ResetPasswordView`, `User.token_version` + `CookieJWTAuthentication`/refresh checks | `test_scenario_12_forgot_and_reset_signs_out_other_sessions` |
| ACC-13 (link guest orders), ACC-09 | `link_guest_orders`, `shop/views_public.TrackView`; `frontend/pages/track.vue` | `test_scenario_29_guest_orders_link_*` |
| ACC-04/05/06/08 | `MeView` (profile, deletion/anonymisation), `AddressViewSet` (≤5, one default), `MyOrdersView`; `pages/account/index.vue`, `pages/account/orders/[number]/invoice.vue`, checkout prefill | `test_customer_account.py` |
| ACC-07 (wishlist, guest merge) | `shop/views_wishlist.py`, `shop.WishlistItem`; `stores/customer.ts`, `utils/wishlist.ts`, `components/store/WishHeart.vue` | `test_customer_account.py`, `wishlistOtp.test.ts` |
| NTF-01/02/04/06 | `core/views_engagement.py` (contact with honeypot + throttle, newsletter), `core/notifications.py` + templates; `pages/contact.vue`, footer newsletter band; `pages/admin/messages.vue` | `core/tests/test_engagement.py`, permission matrix |
| UI-08 (mobile bottom nav, header icons) | `components/store/BottomNav.vue`, `StoreHeader.vue` | manual |
| Scenarios | 12 and 29 (API tests + dev-stack run with the real queue worker) | see above |

Built without a board, for review: `/track`, admin Messages (contact messages + newsletter export), the MiMSMS fields in Settings → SMS, the forgot/reset steps layout.
Not verified: MiMSMS against the real service (no account/docs yet); real SMTP.

## M5 Reports, analytics, hardening
| SRS ID | Backend / frontend code | Tests |
|---|---|---|
| RPT-01..07 | `apps/reports/services.py` (ranges, sales, funnel, inventory, coupons), `views.py` (`reports/*`, CSV via `?export=csv&section=`); `frontend/pages/admin/reports.vue`, `components/admin/BarChart.vue` | `reports/tests/test_reports.py` (presets, custom range, exclusions, every CSV section) |
| ADM-02, PAY-08, ORD-12, INV-11 | `services.dashboard()` (widgets per permission), `DashboardView`; `frontend/pages/admin/index.vue` | `test_dashboard_*`, `test_dashboard_widgets_follow_permissions` |
| ADM-09 (mobile admin) | `frontend/layouts/admin.vue` (slide-in menu on phones) | manual |
| INS-01/06 | `services.wishlist_overview/savers`, `WishlistInsightView`; `frontend/pages/admin/insights.vue` (GA4 link) | `test_wishlist_overview_savers_and_conversion` |
| INS-03/04 (consent, GTM only after Accept, Consent Mode denied, Decline remembered), scenario 21 | `frontend/stores/consent.ts`, `components/store/CookieBanner.vue`, `plugins/analytics.client.ts`, `utils/consent.ts`; privacy text migration `core/migrations/0004_default_privacy_text.py` | `frontend/tests/consent.test.ts`, `consentStore.test.ts` |
| INS-05 (event contract, `data-track` → `ui_click`, no personal data) | `composables/useTrack.ts`, `plugins/analytics.client.ts`, `ShopListing.vue`/`product/[slug].vue` events, `TRACKING.md` | `consent.test.ts` (sanitiser, click info), `tracking.test.ts` (every name documented) |
| §9 SEO (sitemap, robots, structured data, OG, canonical) | `utils/seo.ts`, `server/routes/sitemap.xml.ts`, `robots.txt.ts`, `layouts/default.vue`, `pages/product/[slug].vue` | `frontend/tests/seo.test.ts`; live `/sitemap.xml`, `/robots.txt` |
| §9 accessibility basics | skip link, `main` landmark, labelled controls, bar-chart text alternative | manual |
| §9 rate limiting | `LoginThrottle` on admin login; customer login, forgot and OTP-per-IP 429 tests | `test_customer_auth.py`, `test_admin_login_is_rate_limited` |
| §9 Reliability, scenario 30 | `backend/scripts/backup.sh`, Dockerfile `postgresql-client`, readme restore steps | `core/tests/test_backup_script.py`; real run on the dev stack |
| §16 CI both repos, scenario 24 | `frontend/.github/workflows/ci.yml`; backend route gate (`conftest.py`) | gate shown to fail (exit 1, 150 routes listed) when only one test file runs |
| Scenarios | 21 (store logic tested; no browser click-through), 24, 30 | see above |

Built without a board, for review: Reports tabs (funnel, inventory, coupons), delivery-area block, wishlist "who saved it", dashboard payments-to-verify widget.
Not verified: GA4/GTM against a real container (needs an ID and the owner's Google account); real SMTP; MiMSMS.

## M6 Release
| Item | Code | Verification |
|---|---|---|
| Production Docker (non-root, healthchecks, log rotation, optional `backup` service) | `deploy/docker-compose.prod.yml`, `backend/Dockerfile`, `frontend/Dockerfile`, `.dockerignore` files | Built and run end to end under a separate project (`sllprod`): all services healthy |
| Nginx + TLS (cert files mounted) and provider-proxy variant, maintenance page | `deploy/nginx/default.conf`, `proxy-tls.conf`, `maintenance.html`, `docker-compose.proxy-tls.yml`, `deploy/certs/` | `nginx -t` on both; HTTPS 200, HTTP→HTTPS 301, HSTS once, security headers, 502 shows the maintenance page and recovers |
| Env docs + safety check (§9 Security) | `backend/.env.production.example`, `apps/core/envcheck.py`, `scripts/entrypoint.sh`, `config/settings/prod.py` | `core/tests/test_envcheck.py` (22); CI job refuses the unfilled template; `check --deploy` clean |
| Seed data: Owner + staging demo | `manage.py create_owner`, `manage.py seed_demo` (`--reset`, `--photos-dir`, staging only) | `core/tests/test_commands.py` (13) |
| Backup / restore runbook (SRS §9, scenario 30) | `scripts/backup.sh`, `scripts/restore.sh`, `docs/RUNBOOK.md` | `test_backup_script.py`, `test_restore_script.py`; real drill with matching row counts |
| Smoke + release checklist | `scripts/smoke.sh`, `docs/RELEASE_CHECKLIST.md`, `docs/DEPLOYMENT.md` | `smoke.sh` all checks passed against the TLS stack |
| Error pages | `frontend/error.vue` | `tests/errorPage.test.ts`; live 404 renders the branded page, no stack trace |
| Upload limit | nginx `client_max_body_size 30m`; batched uploads in `pages/admin/products/[id].vue` | one request with 5 photos (25 MB) returned 201 through nginx + TLS |
| CI release job | `backend/.github/workflows/ci.yml`, `frontend/.github/workflows/ci.yml` | YAML validated; not run on GitHub from here |

Bugs found only by running the production stack: `ipx` missing from the production bundle (now a direct dependency, `sharp` 0.33 prebuilt), SSR calls rejected by `ALLOWED_HOSTS` and the SSL redirect, root-owned media volume, `pg_dump` 17 vs PostgreSQL 16, duplicate HSTS header, image source dir fixed at build time.

## Storefront polish (hero background, quick add, compact layout)
| SRS ID | Frontend / backend code | Tests |
|---|---|---|
| WEB-09, UI-05 | `components/store/HomeHero.vue` (literal CSS background, `cover`/`no-repeat`/`center`, fixed box per breakpoint, `mobile_media` below 640 px, IPX `image-set()`, first slide preloaded), `StoreTile.vue` and `.media-cover` (other images stay `object-fit: cover` in fixed boxes), `pages/index.vue` (video thumb width/height), `pages/admin/website.vue` (upload hints) | manual: extreme uploads keep the box size (browser check) |
| CAT-12, CAT-13, UI-02 | `components/store/ProductCard.vue`, `composables/useQuickAdd.ts` (idle/picking/added state, chips from all variants, out-of-stock disabled, add by variant id), `.qa-bar` / `.qa-touch` in `assets/css/main.css`, `catalog/public.card()` (variant `sku`, `price`) | `frontend/tests/quickAdd.test.ts`, `catalog/tests/test_public_api.py::test_card_shape_badge_soldout_no_stock_leak` |
| UI-01, UI-02 | `tailwind.config.ts` (`fontSize` heading tokens), `assets/css/main.css` (`.h-display`, `.h-page`, `.h-section`, `.h-sub`, `.h-card`, `.section`, `.btn`, `.lnk`), storefront headings migrated to the tokens; header 56/72 px, announcement bar clamped to two lines, tablet category row scrolls, 44 px footer/search/menu links, no text below 12 px | manual: overflow, tap-target and font-size audit at 360, 390, 768, 1024, 1280, 1536 px (see report) |

## Admin portal improvements and theme colours
| SRS ID | Frontend / backend code | Tests |
|---|---|---|
| THM-06/08, ARC-12 | `assets/css/tokens.css` (`:where(:root)` defaults + `.admin-scope`), `plugins/theme.server.ts` (`tagPriority`), `plugins/theme.client.ts`, `composables/useTheme.ts` | live check: `--color-primary` on `/` equals the saved palette; `tests/theme.test.ts` |
| THM-02/03/04/07/14/18/19 (draft amendment) | `apps/core/theme.py` (`derive_neutrals`, `readability_issues`), `models.ThemePalette/ThemeSettings` + migration `0006`, `views_admin` (`ThemeInputSerializer`, `_apply_theme`), `PublicThemeView`, `utils/themeDerive.ts`, `pages/admin/theme.vue` | `apps/core/tests/test_theme.py`, `test_admin_settings_theme.py`, `frontend/tests/themeDerive.test.ts` (parity fixtures from Python) |
| ADM-07, UI-06 | `composables/useApi.ts`, `stores/adminUi.ts`, `components/admin/AdminLoader.vue`, `AdminToasts.vue`, `utils/apiError.ts` | `frontend/tests/apiError.test.ts` |
| UI-06, §10 | `utils/validators.ts`, `composables/useFormValidation.ts`, `components/admin/AdminFormField.vue`; applied on products, categories, coupons, users, settings, theme, size charts, inventory, login, website content, media upload, order panel | `frontend/tests/validators.test.ts` |
| SET-08, ADM-12 (draft) | `layouts/admin.vue`, `layouts/print.vue` (tab title `{company} \| Admin Panel`), `AdminSidebar.vue` | browser check |
| CAT-03, ADM-03 | `utils/sku.ts`, `pages/admin/products/[id].vue` (live SKU preview, auto/custom, "Use ..." for saved rows) | `frontend/tests/sku.test.ts` (parity with `make_sku`) |
| CAT-02/04/15 (draft) | `pages/admin/products/[id].vue` (Status card, publish pre-checks), `products/index.vue` (Published/Unpublished) | `catalog/tests/test_admin_api.py::test_bulk_activate_requires_publishable` |
| WEB-09, §10 (draft: 300 px) | `apps/core/serializers.py` (`PRODUCT_MIN_SIDE`), `views_admin.ImageViewSet.create` (validate all, then save atomically, name the failing file), `utils/imageCheck.ts`, `MediaField.vue` | `test_admin_api.py::test_image_rules`, `::test_image_batch_is_all_or_nothing_and_names_the_bad_file`, `tests/imageCheck.test.ts` |
| ORD-09, §10 | `apps/shop/orders.py` (`EDIT_MAX` column limits) | `apps/shop/tests/test_orders.py` |
| CAT-15, RPT-07, INV-* | `composables/useDownload.ts` (CSV exports report failures) | browser check |


## M7 Phase 1: product weight (SRS v1.7)
| SRS ID | Backend / frontend code | Tests |
|---|---|---|
| CAT-24 | `backend/apps/catalog/models.py` (`Product.weight_grams`, `WEIGHT_VALIDATORS`), migration `catalog/0004`; `frontend/pages/admin/products/[id].vue` (Weight field) | `apps/catalog/tests/test_weight.py` (`test_new_product_defaults_to_100_grams…`, `test_weight_bounds_rejected`) |
| CAT-25 | `Variant.weight_grams`, `Variant.weight`; `VariantSerializer`; variant "Weight (g)" column; `frontend/utils/weight.ts` (`variantWeightPayload`) | `test_variant_override_and_effective_weight`; `frontend/tests/weight.test.ts` |
| CAT-26 | `OrderItem.weight_grams` (migration `shop/0003`), `Order.total_weight_grams`, `apps/shop/checkout.py` snapshot, `AdminItemSerializer`; `components/admin/PrintSlip.vue`, `OrderPanel.vue`, `formatWeight` | `test_scenario_31_order_line_keeps_weight_snapshot`, `test_customer_order_payload_has_no_weight`; `frontend/tests/weight.test.ts` |
| §10 weight | `WEIGHT_MSG` (backend), product form rule (frontend) | `test_weight_bounds_rejected` |

## M7 Phase 2: Steadfast courier (SRS v1.7 §4.18)
Backend paths are under `backend/apps/courier/` unless noted; tests under `apps/courier/tests/`.
| SRS ID | Backend / frontend code | Tests |
|---|---|---|
| CRR-01 | `core/models.py` `steadfast_*`, `core/serializers.py` write-only fields; `pages/admin/settings.vue` Courier tab | `test_admin_api.py::test_courier_keys_are_write_only…` |
| CRR-02 | `views_admin.PingView`, `steadfast.ping/balance`; Settings → Test connection | `test_ping_reports_reachability_and_keys` |
| CRR-03 | `services.book/book_task/queue_auto_book/payload`, `shop/orders.py` Confirm hook | `test_booking.py::test_scenario_32…`, `test_prepaid_order_sends_zero_cod`, `test_auto_booking_off…` |
| CRR-04 | `services.book` lock + state check, `_recover_duplicate` | `test_book_twice_or_wrong_state…`, `test_duplicate_invoice_recovers…` |
| CRR-05 | `services._mark_failed`, `SteadfastError.retryable`, `BookOrderView`; `components/admin/CourierBlock.vue` Retry | `test_scenario_33…`, `test_manual_book_rejection…`, `test_unreachable_is_retryable…` |
| CRR-06 | `steadfast.call` 401/403 → `steadfast_keys_rejected`; serializer `update` lifts it | `test_scenario_34…`, `test_client_error_shapes` |
| CRR-07 | `services.bulk_book`, `BulkBookView`; `pages/admin/orders/index.vue` bulk + "To book" tab | `test_scenario_39…`, `test_bulk_book_needs_ids`, `test_unbooked_filter…` |
| CRR-08 | `views_public.SteadfastWebhookView`, `signature_ok`, `WebhookReceipt` | `test_webhook.py::test_scenario_35…` (both), `test_webhook_refused_when_no_token…`, `test_non_json_body_is_400` |
| CRR-09 | `services.apply_status`, `FLAG_FOR`; order list column + "Courier attention" tab | `test_scenario_36…` (both), `test_flags_for_other_outcomes`, `test_hold_clears…`, `test_cod_mismatch…` |
| CRR-10 | `services.add_event/process_webhook/backfill_tracking`, `CourierEvent` | `test_scenario_35_duplicate…`, `test_unknown_parcel_and_staff_note_events`, `test_scenario_37…` |
| CRR-11 | `services.reconcile/refresh`, migration `courier/0002` schedule, `RefreshOrderView` | `test_scenario_37…`, `test_reconcile_skips_fresh…`, `test_refresh_and_return_request` |
| CRR-12 | `DashboardView`, `ParcelStateView`; `pages/admin/courier/index.vue`, sidebar | `test_dashboard_and_cache`, `test_scenario_34…` |
| CRR-13 | `services.create_pickup`, `PickupView`, `PoliceStationsView`, `PickupRequest`; `pages/admin/courier/pickups.vue` | `test_pickups_and_police_stations` |
| CRR-14 | `services.request_return`, `ReturnOrderView`, `ReturnListView/DetailView`; `pages/admin/courier/returns.vue`, CourierBlock | `test_refresh_and_return_request`, `test_return_requests_list_and_detail` |
| CRR-15 | `FraudCheckView`; CourierBlock "Check delivery record" | `test_fraud_check` |
| CRR-16 | `courier/serializers.customer_courier_steps`, `shop/serializers.CustomerOrderSerializer`; `components/store/CourierSteps.vue` on `/track` and account | `test_scenario_38…` |
| §2.2 / PRM-05 | `accounts/permissions.py` `courier.view`, `courier.manage` | `test_scenario_40_courier_permission_matrix`, `accounts/tests/test_permissions.py` |

## M8 Theme fonts (SRS v1.9)
| SRS ID | Backend / frontend code | Tests |
|---|---|---|
| THM-20 | `backend/apps/core/theme.py` `FONT_PAIRINGS` (9 pairings, Google css2 URLs) | `apps/core/tests/test_theme_fonts.py::test_catalogue_has_nine_pairings…` |
| THM-21 | `ThemeSettings.storefront_font/admin_font` (migration `core/0010`), `theme.font_pairing`; `utils/theme.ts` `fontForPath` | `test_scenario_41_42…`, `test_unknown_saved_key…`; `frontend/tests/themeFonts.test.ts` |
| THM-22 | `views_public.PublicThemeView` `fonts`; `utils/theme.ts` `fontToCss`; `tailwind.config.ts` `var(--font-*)`; `assets/css/main.css` fallbacks | `test_defaults_are_signature_and_public_payload`; `themeFonts.test.ts` |
| THM-23 | `plugins/theme.server.ts` (SSR tokens + one stylesheet), `plugins/theme.client.ts` (live per area), `fontLinks`; migration clears the public cache | `themeFonts.test.ts`; browser check (one css2 request) |
| THM-24 | `views_admin.AdminThemeView` font-only PUT, `FontInputSerializer`; `pages/admin/theme.vue` Fonts section | `test_scenario_41_42…`, `test_fonts_saved_with_colours` |
| THM-25 | `FontInputSerializer` choices, `require("theme.manage")`, `_apply_fonts` audit | `test_scenario_43_validation_permission_audit` |
| THM-26 | model defaults, `ThemeResetView` resets fonts, "Reset fonts" button | `test_scenario_44_reset_restores_signature_fonts` |

## M8 Theme fonts, tuning (SRS v1.10)
| SRS ID | Backend / frontend code | Tests |
|---|---|---|
| THM-27 | `backend/apps/core/theme.py` x-height + factor per font, `font_adjust`, `_adjust` | `test_theme_fonts.py::test_signature_standard_sends_no_adjustment`, `test_adjust_values_in_range…` (27 cases) |
| THM-28 | `TEXT_SIZES`, `ThemeSettings.storefront_text_size/admin_text_size` (migration `core/0011`, clears public cache) | `test_text_size_multipliers`, `test_text_size_saved_audited_public_and_reset` |
| THM-29 | public theme `display_adjust`/`sans_adjust`; `frontend/utils/theme.ts` `safeAdjust`, `fontToCss`; `assets/css/main.css` `font-size-adjust` rules | `frontend/tests/themeFonts.test.ts` |
| THM-30 | admin theme payload `text_sizes`, per-pairing `adjust`; `pages/admin/theme.vue` Text size selector, tuned samples | `test_admin_catalogue_carries_adjust_per_size` |
| THM-31 | `frontend/scripts/typography-audit.js` (dev-only browser audit) | audit run recorded in the v1.10 change record |

## v1.11 Client requests (SRS v1.11, change record `SRS_AMENDMENT_v1.11_DRAFT.md`)
Branch `feat/v1.11-client-requests` in both repos. All v1.11 items implemented (2026-11-24).

| SRS ID | Backend / frontend code | Tests |
|---|---|---|
| NTF-07 | `backend/apps/core/sms/__init__.py` (`send`, `log_pending`, `_update_log`, OTP masking), `apps/core/models.py` `SmsLog` (migration `core/0012`); callers `apps/accounts/otp.py` (`_queue`, `deliver`), `apps/shop/notifications.py` (`_order_sms_log`, `send_order_sms`), `apps/core/views_admin.py` `SmsTestView` | `apps/core/tests/test_sms_log.py` (sent/failed/retry/masked/logging-never-blocks/register OTP/test SMS) |
| ADM-14 | `apps/core/views_admin.py` `SmsLogView` + `SmsLogSerializer`, route `admin/sms-log/`; `frontend/pages/admin/sms-log.vue`, sidebar entry `components/admin/AdminSidebar.vue` | `test_sms_log.py::test_admin_list_filters`; `test_permission_matrix.py` (`/sms-log/`) |
| §2.2 / PRM `sms_log.view` | `apps/accounts/permissions.py` CATALOGUE (sensitive, not default) | `accounts/tests/test_permissions.py`, `test_admin_api.py` (18 codes), `test_permission_matrix.py` |
| CHK-11 | `apps/accounts/models.py` `OtpPurpose.CHECKOUT`, `VerifiedPhone` (migration `accounts/0004`); `apps/accounts/otp.py` (`DIGITS`, `ATTEMPTS`, `phone_is_verified`, `verify_checkout`); `apps/shop/checkout.py` `require_verified_phone`; `apps/shop/views_public.py` `CheckoutOtpView`, `CheckoutOtpVerifyView` (`checkout/otp/`, `checkout/otp/verify/`); `SiteSettings.checkout_otp_enabled` (migration `core/0013`); `frontend/components/store/CheckoutOtpDialog.vue`, `pages/checkout.vue` (`needsOtp`, `phone_unverified` retry), `pages/admin/settings.vue` SMS switch | `apps/shop/tests/test_checkout_otp.py` (7); `frontend/tests/v111Checkout.test.ts` |
| CHK-04 (Bank) | `apps/shop/models.py` `PayMethod.BANK`, `Payment.sender_name`, `trx_id` 30 (migration `shop/0004`); `apps/shop/checkout.py` `BANK_REF_RE`, `clean_trx`, `clean_sender_name`, `method_enabled`; `SiteSettings.bank_*` (migration `core/0014`), public settings; `pages/checkout.vue` Bank panel; `pages/admin/settings.vue` Payment tab | `apps/shop/tests/test_checkout.py` (`test_scenario_55…`, `test_bank_*`), `test_api_public.py::test_payment_methods_follow_settings` |
| PAY-01/02/08 | `apps/shop/orders.py` (`_confirm` needs verified Bank, `edit_payment` `sender_name`), `views_admin.payment_edit`, `serializers.PaymentSerializer`; `reports/services.py` queue; `components/admin/OrderPanel.vue`, `PrintInvoice.vue`, `pages/admin/orders/index.vue` filter | `test_checkout.py::test_bank_order_cannot_confirm_until_verified` |
| CHK-12 | `frontend/public/payments/bkash.svg` (from bkash.com), `nagad.png` (from nagad.com.bd), bank/cash icons in `pages/checkout.vue` | browser check |
| ORD-14 | `backend/apps/courier/models.py` `Shipment.queued_at`, `booking_in_progress` (migration `courier/0003`), `apps/courier/services.py` (`queue_auto_book`, `ready`, `_mark_booked`/`_mark_failed` clear the flag), `apps/shop/orders.py` `_refuse_while_booking`, `apps/shop/serializers.py` `steadfast_ready`; `frontend/components/admin/OrderPanel.vue` (Move to Shipping books with Steadfast, "Booking with Steadfast…" poll, Ship with another courier), `components/admin/CourierBlock.vue` | `apps/courier/tests/test_move_to_shipping.py` (5 tests) |
| ADM-13 | `frontend/pages/admin/products/[id].vue` (bottom Save before SEO, same `save(false)`) | browser check (2026-11-24) |
| CAT-10a | `frontend/components/store/StoreSearch.vue` (`order-1/2` below md) | browser check |
| CAT-12 (Buy dialog) | `frontend/components/store/ProductCard.vue` (Buy button), `components/store/StoreBuyDialog.vue`, `composables/useBuyDialog.ts`, `composables/buySelection.ts`, `components/store/StoreShell.vue` | `frontend/tests/buyDialog.test.ts`; `tests/quickAdd.test.ts` (shared helpers); browser check 375 px |
| CAT-27 | `frontend/components/store/ProductZoom.vue`, `pages/product/[slug].vue` | browser check (buttons, 200 %, reset) |
| WEB-01 / WEB-12 | `frontend/components/store/HomeHero.vue` (slides keyed by id, `.hero-box` aspect ratio + contain below 640 px) | browser check: DOM nodes persist across a slide move |
| STF-UI-01 (logo) | `frontend/components/store/StoreHeader.vue` (`logoH`, header heights) | browser check |
| STF-UI-02 (footer) | `frontend/components/store/StoreFooter.vue`, `utils/socialIcons.ts`, `assets/css/tokens.css` (`--brand-*`) | `tests/tracking.test.ts` (footer_social_*), browser check |
| STF-UI-03 (fade-in-up) | `frontend/plugins/reveal.ts`, `assets/css/main.css` (`.reveal`), `ProductCard.vue`, `StoreSection.vue` | browser check |
| STF-UI-04 (scroll top) | `frontend/app/router.options.ts` | typecheck; manual check on a phone recommended |

| Scenario | Tests |
|---|---|
| 51, 52 | `test_checkout_otp.py::test_scenario_51_52_new_guest_verifies_then_skips` |
| 53 | `test_checkout_otp.py::test_scenario_53_three_wrong_codes_kill_the_code`, `test_scenario_53_resend_wait` |
| 54 | `test_checkout_otp.py::test_scenario_54_unverified_guest_order_refused` |
| 55 | `test_checkout.py::test_scenario_55_bank_order_pending_and_duplicate_ref_refused` |
| 56 | `test_sms_log.py` (all) |
| 57, 58 | `apps/courier/tests/test_move_to_shipping.py` |
| 59 | `frontend/tests/buyDialog.test.ts`; browser: Buy → size → Checkout Now opened /checkout with the item |
| 60 | browser check at 375 px |
| 61 | browser check (zoom buttons); pinch needs a real touch device |
