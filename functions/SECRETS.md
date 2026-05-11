# Firebase Secret Manager — Orange Money API Credentials

## Overview

All Orange Money Mali API credentials are stored in **Firebase Secret Manager** and accessed exclusively by Cloud Functions at runtime. These secrets are **NEVER** exposed to the Flutter client app.

This ensures compliance with **Requirement 6 AC2**: Payment_Service SHALL NOT store Orange Money credentials or API secrets in the Flutter app; all API calls SHALL be made from Cloud Functions.

---

## Required Secrets

| Secret Name | Purpose |
|---|---|
| `ORANGE_MONEY_API_KEY` | API key for authenticating requests to the Orange Money Mali API |
| `ORANGE_MONEY_BASE_URL` | Base URL for the Orange Money API (e.g., `https://api.orange-money.com/v1`) |
| `ORANGE_MONEY_CALLBACK_URL` | Public HTTPS endpoint URL that Orange Money calls when payment status changes |
| `ORANGE_MONEY_CALLBACK_SECRET` | HMAC-SHA256 shared secret used to validate callback request signatures |

---

## Setup Instructions

Use the Firebase CLI to set each secret. You will be prompted to enter the value interactively (values are never echoed to the terminal).

```bash
# 1. Set the Orange Money API key
firebase functions:secrets:set ORANGE_MONEY_API_KEY

# 2. Set the Orange Money API base URL
firebase functions:secrets:set ORANGE_MONEY_BASE_URL

# 3. Set the public callback URL for payment status updates
firebase functions:secrets:set ORANGE_MONEY_CALLBACK_URL

# 4. Set the HMAC shared secret for callback signature validation
firebase functions:secrets:set ORANGE_MONEY_CALLBACK_SECRET
```

After setting secrets, redeploy the Cloud Functions so they pick up the new values:

```bash
firebase deploy --only functions
```

---

## How Secrets Are Used in Code

Secrets are referenced using `defineSecret` from `firebase-functions/params` and declared at the module level:

```typescript
import { defineSecret } from "firebase-functions/params";

const orangeMoneyApiKey = defineSecret("ORANGE_MONEY_API_KEY");
const orangeMoneyBaseUrl = defineSecret("ORANGE_MONEY_BASE_URL");
const orangeMoneyCallbackUrl = defineSecret("ORANGE_MONEY_CALLBACK_URL");
const orangeMoneyCallbackSecret = defineSecret("ORANGE_MONEY_CALLBACK_SECRET");
```

Each Cloud Function that needs a secret lists it in its options:

```typescript
export const initiatePayment = onCall(
  { secrets: [orangeMoneyApiKey, orangeMoneyBaseUrl, orangeMoneyCallbackUrl] },
  async (request) => { /* ... */ }
);

export const orangeMoneyCallback = onRequest(
  { secrets: [orangeMoneyCallbackSecret] },
  async (req, res) => { /* ... */ }
);
```

At runtime, access the value with `.value()`:

```typescript
const apiKey = orangeMoneyApiKey.value();
```

---

## Security Notes

1. **Client isolation** — Secrets are injected into Cloud Functions at runtime by Firebase. The Flutter app has zero access to these values.
2. **Least privilege** — Each function only declares the secrets it actually needs (e.g., the callback handler only needs `ORANGE_MONEY_CALLBACK_SECRET`).
3. **No hardcoding** — Secret values must never appear in source code, environment files committed to version control, or client-side configuration.
4. **Rotation** — To rotate a secret, run `firebase functions:secrets:set SECRET_NAME` with the new value, then redeploy functions.
5. **Access control** — Only project owners and editors with the `secretmanager.secretAccessor` IAM role can view or modify secrets in the Google Cloud Console.
6. **Audit logging** — Secret access is logged by Google Cloud's audit infrastructure.

---

## Verifying Secrets Are Set

To list all secrets currently configured for the project:

```bash
firebase functions:secrets:get
```

To check a specific secret exists (does not reveal the value):

```bash
firebase functions:secrets:access ORANGE_MONEY_API_KEY
```

---

## Troubleshooting

| Issue | Solution |
|---|---|
| Function fails with "Secret not found" | Run `firebase functions:secrets:set SECRET_NAME` and redeploy |
| Permission denied accessing secrets | Ensure your service account has `secretmanager.secretAccessor` role |
| Callback signature validation fails | Verify `ORANGE_MONEY_CALLBACK_SECRET` matches the value configured in the Orange Money merchant dashboard |
| API returns 401 Unauthorized | Verify `ORANGE_MONEY_API_KEY` is correct and not expired |
