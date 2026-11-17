# Admin login

Staff sign in with email. Phone login is for customers.

| Stack | Use | Admin URL | Email | Password |
|---|---|---|---|---|
| Dev | Everyday local testing | http://localhost:3000/admin/login | owner@softladylux.test | Slx-Owner-7Kq2-Test |
| Production test | HTTPS smoke test | https://localhost:8443/admin/login | owner@prod.test | prod-test-owner-pass-1 |

The production test stack uses a self-signed certificate. Accept the browser warning to continue.

Both accounts are throwaway. Change or delete them before any real deployment.
