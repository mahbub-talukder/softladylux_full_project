You are building SoftLadyLux: an ecommerce website and admin portal for a Bangladeshi women's fashion and innerwear business. Two repos: backend (Django) and frontend (Nuxt). You are running in /home/mahbub/workspace/softladylux_project.

## Sources of truth (read these before writing any code)
1. docs/SRS.md (v1.4) is the requirements. Read all of it, especially §1.6 (scope decisions), §2.2 (roles and permissions), §5 (business rules), §6 (data model), §7 (API), §12 (acceptance scenarios 1–30), §15 (decisions) and §16 (implementation plan M0–M6). The SRS is final and every scope item is decided.
2. docs/design/ is the UI design reference. Read docs/design/README.md first, then the board for the page you are building (for example Checkout.dc.html, AdminOrders.dc.html). These are HTML sketches from a design tool. Use them for layout, copy, states, flows and the Signature palette. Do not copy them as code. Rebuild them as Nuxt/Vue components. docs/design/canvas.json maps every board. The live canvas is https://claude.ai/artifact/KXKN1xLSKTXeNLEjW1Hiob (use it only if you can open it).

If the SRS and the design disagree, or something is missing from both, STOP and ask me. Do not guess. SRS wins on behaviour and rules, design wins on look and layout. Change docs/SRS.md only after I approve.

## Repos
- backend/ (Django, existing git repo and remote)
- frontend/ (Nuxt, existing git repo and remote)
- docs/ (SRS, scope review, design)

## Fixed stack
- Backend: Django 5, Django REST Framework, PostgreSQL 16, Django-Q2 using the PostgreSQL broker (no Redis, no Celery) with a separate worker container.
- Frontend: Nuxt 3, Vue 3, TypeScript, Pinia, Tailwind driven by CSS-variable theme tokens, @nuxt/image, Google Tag Manager + GA4.
- Docker Compose services: db, backend, worker, frontend, nginx.
- The admin portal is inside the Nuxt app at /admin/ (separate route group and layout).


## How to work
1. Do not write code yet. First read everything above, then reply with: (a) a short summary of what you understood, (b) any contradictions or gaps you found between the SRS and the design, with a proposed fix for each, and (c) your concrete plan for every implementation plan (i.e MO,M1,M2) (foundation). Then wait for my approval.
2. After approval, build one milestone at a time in the order of SRS §16,Within a milestone: models and migrations, then business rules with tests, then API, then admin UI, then storefront UI, then compare against the design boards.
3. After each milestone: run all tests, show the results, list the SRS requirement IDs and acceptance scenarios covered, name the design boards you matched, and stop for my approval before the next milestone.
4. Use small commits with Conventional Commit messages, on feature branches with one PR per milestone. Never push to main without asking me.
5. Keep docs/TRACEABILITY.md mapping SRS IDs to code and tests, and update it as you go.
6. If anything is unclear, ask me. Do not invent requirements.

## Working style (keep it lean)
- Be direct. No long explanations, recaps or restating the SRS. Report only: what you did, test results, and what needs my decision.
- Read only what you need. Open the SRS section and the one design board for the task at hand, not every file each time. Use grep before reading large files.
- Do not paste large files or long logs into the chat. Summarise, and show only failing lines.
- Write code once, correctly. Reuse existing components and helpers instead of rewriting.
- Ask short questions with 2–3 options and a recommended default, and keep working on unblocked tasks while you wait.
- Do not add features, refactors, abstractions or dependencies the SRS does not require.
- At the end of each milestone, reply in 10 lines or fewer.

Do execute the next plan