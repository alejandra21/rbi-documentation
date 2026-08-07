# Runbook — testing Extensions ↔ Finance in Bruno

Click-by-click pass over the `Servicing` collection, against a local backend on
branch `integration/extensions-finance`.

The companion doc in the backend repo
(`docs/testing/extensions-finance-qa.md`) explains *why* each check exists.
This one is just the order to click things in.

---

## Before you start

**Stack up?** From `servicing-backend`:

```bash
DB_HOST_PORT=3307 docker compose up -d && curl -s -o /dev/null -w '%{http_code}\n' localhost:3001/health
```

`200` and you're good.

**Pick the `Local` environment** in Bruno's environment selector (top right).
Nothing works without it — every request is `{{base_url}}`-templated.

**Your JWT expires 2026-08-08 13:34 CEST** (~24h from when it was minted). When
requests that worked start returning `403`, that's the first thing to check —
not a regression. Re-log into the POS QA portal and copy a fresh bearer into
`jwt_token`.

**Seed data already in your local DB:**

| Extension | Loan | Investor | Documents |
|---|---|---|---|
| `1` | 4199 | RBI Capital Fund LLC | — |
| `2` | 2042 | — | 3 (none a payment proof) |
| `3` | 2036 | — | — |
| `4` | 2059 | — | — |

Set `extension_id` = **2** and `loan_id` = **2042** for the document flow. Use
**1** when you get to CB-02, since it's the one with an investor attached.

No extension has a workflow row yet, so the first workflow PATCH creates one.

---

## Step 1 — API keys (folder `1 API Keys`)

> You already have two keys in the DB (`finance-local-test`,
> `servicing-read-local-test`) from an earlier run. Their plaintext is **gone** —
> it's shown exactly once and never stored. Just create new ones; duplicate
> labels are fine.

1. **`API Keys - Create (finance-proof)`** → Send.
   Copy `result.plaintext` into the `finance_api_key` environment variable.
   Copy `result.id` into `api_key_id`.
2. **`API Keys - Create (servicing-read)`** → Send.
   Copy its `plaintext` into `read_api_key`.
3. **`API Keys - List`** → Send. Confirm two things:
   - no `plaintext` and no hash anywhere in the response;
   - the envelope has **`availableScopes`** next to `result`. That's the field
     whose missing type broke the develop build (TS2353). If it's absent, the
     branch didn't get the fix.

---

## Step 2 — Scope isolation (folder `5 Scope Isolation`)

Do this **now**, while the keys are fresh. It's the highest-value folder and it
takes a minute.

**Every request here must fail.** A `200` is the bug.

| Request | Why it matters |
|---|---|
| `finance-proof key on read surface` | Finance's key must not read the servicing dataset |
| `finance-proof key on payoffs` | same, different route |
| `servicing-read key on borrower proof` | read access ≠ access to banking evidence |
| `no key at all` | fails closed |

Then the deactivation check:

1. `1 API Keys` → **`API Keys - Deactivate`** → Send (uses `api_key_id`).
2. `5 Scope Isolation` → **`deactivated key (must fail)`** → Send. Must be
   refused **on every scope**, not just narrowed.
3. Re-activate: edit the Deactivate request's body to `{"active": true}` and
   send again. Confirm `Borrower Proof - Get (302)` works once more.

If any of these pass, look at
[`src/routes/servicingApi.ts`](../../../../RBI/Servicing/servicing-backend/src/routes/servicingApi.ts):
the split depends on routes being registered **above or below**
`router.use(protectExternalRead)`. A route added above that line silently
escapes the read guard.

---

## Step 3 — FIN-04, the full proof chain (folders `2` and `3`)

This is the flow Finance actually walks. Four hops.

### 3a. Upload the proof

`2 Extensions` → **`Extensions - Upload Payment Proof`**

- In the Body tab, click the `file` row and pick any local PDF.
- Leave `category` exactly as `Borrower Payment Proof` — that's the ENUM value
  migration `20260806000006` added, and the only one the Finance endpoint looks
  for.
- Don't add a `Content-Type` header. Bruno generates the multipart boundary.

Send. Expect a created document.

> Nothing else happens. No webhook fires — FIN-02's `notifyProofUploaded` has no
> call site yet. That's expected, not a failure.

### 3b. Get the permanent URL as Finance

`3 Finance External API` → **`Borrower Proof - Get (302)`** → Send.

Expect **302**, not 200. This request has `followRedirects: false` on purpose —
you want to read the redirect, not chase it.

Check the `Location` header (Headers tab of the response):

- it should be **absolute** — `http://localhost:3001/api/public/v1/documents/signed/<token>`
- absolute because `SERVICING_PUBLIC_BASE_URL` is set. Unset it in `.env`,
  `docker compose up -d --force-recreate app`, and re-send: it degrades to a
  relative path. Legal, but it leaves Finance to resolve it. Put it back.

**Copy the token** out of that Location into the `signed_token` variable.

### 3c. Download it

`3 Finance External API` → **`Signed Document - Download`** → Send.

No API key, no JWT — the token *is* the credential. You should get the PDF.

### 3d. Break the token

Edit `signed_token` and re-send each time. All must fail, and the *wording*
matters:

| Tamper | Expect |
|---|---|
| change a character mid-token | rejected |
| chop the last few characters (signature) | rejected — **not a 500** |
| wait past the TTL | reports **expired**, not "invalid" |

To test expiry without waiting 5 minutes, set `DOCUMENT_URL_TTL_SECONDS=10` in
`.env`, recreate the app container, and redo 3b → 3c.

### 3e. Re-upload (FIN-07)

Upload a **second, different** PDF to the same extension (repeat 3a), then
re-run 3b. The endpoint must serve the **newest** proof — `findBorrowerPaymentProof`
orders by `id DESC`. This is the path after Finance rejects a proof.

---

## Step 4 — FIN-06, the finalize gate (folder `2`)

The gate wants two things: agreement signed **and** funds verified.

### 4a. See the blockers

**`Extensions - Get By ID`** → Send. Find `finalizeReadiness` in the response:

- `blockers` contains *"The borrower has not signed the extension agreement"*
- `verificationStatus` is `null` — no verification row exists

### 4b. Clear the first blocker

**`Extensions - Patch Workflow (sign agreement)`** → Send, then re-run
`Extensions - Get By ID`.

That blocker should be gone while `verificationStatus` stays `null`. That
half-open state is exactly what the gate is built around.

### 4c. Confirm it does *not* block yet

**`Extensions - Patch Stage`** → set a closing stage in the body → Send.

It should **succeed**, because `FINANCE_ENABLED=false`.

### 4d. Turn the gate on

```bash
sed -i '' 's/^FINANCE_ENABLED=.*/FINANCE_ENABLED=true/' .env
docker compose up -d --force-recreate app
```

Re-send `Extensions - Patch Stage`. Now it must be **refused**.

### 4e. The happy path needs SQL

There's no HTTP route that can set `FUNDS_VERIFIED` — the `finance:decision`
scope exists but nothing consumes it (FIN-05 isn't built). To see the gate
*open*, insert the row by hand:

```sql
-- mysql -h127.0.0.1 -P3307 -uroot -proot servicing_dev
INSERT INTO loan_extension_finance_verification
  (extension_id, status, verified_by, verified_at, verified_amount,
   reopened_count, deleted, created_at, updated_at)
VALUES
  (2, 'FUNDS_VERIFIED', 'manual-qa', NOW(), 1500.00, 0, 0, NOW(), NOW());
```

Re-run `Extensions - Get By ID` → `verificationStatus: "FUNDS_VERIFIED"` and no
blockers. `Extensions - Patch Stage` should now succeed even with the gate on.

### 4f. Put it back

```bash
sed -i '' 's/^FINANCE_ENABLED=.*/FINANCE_ENABLED=false/' .env
docker compose up -d --force-recreate app
```

**Don't leave it on.** With the gate enabled and nothing able to produce a
`FUNDS_VERIFIED` row, every fee-collecting extension is unclosable.

---

## Step 5 — CB-02, the broker carve-out (folder `2`)

The regression most worth catching, because it's a money bug and it's silent.

Switch `extension_id` to **1** (the one with an investor).

1. **`Extensions - Get By ID`** → note the **borrower total**. Write it down.
2. **`Extensions - Patch Workflow (CB-01 split + approver)`** → Send. It sets a
   10% broker share alongside the investor/RBI split, plus the exception
   approver fields.
3. **`Extensions - Get By ID`** again → the borrower total must be **identical**.

The broker fee is a *carve-out*: it comes out of RBI's share. If the borrower
total grew, CB-02 has regressed and the borrower is being overcharged.

While you're here, confirm the exception approver fields round-tripped
(`exceptionApproverName`, `exceptionApproverEmail`, `exceptionContext`).

---

## Step 6 — EXT-N7 / N8 (folder `2`)

- **N8** — **`Extensions - Patch Lien Search`**: Lien Search auto-flips to N/A
  for the investors configured for it. Check the auto behaviour first, then
  confirm this endpoint still overrides it manually.
- **N7** — exit strategy carries forward from a prior extension onto a new one
  for the same loan. Needs two extensions on one loan; none of the four seeded
  loans has that, so you'll have to create one.

---

## Step 7 — External read surface (folder `4`)

Quick sweep with `read_api_key` — all should return data, none should 401:
`Extensions - List (external)`, `Extensions - Config`, `Payoffs - List`,
`Payoffs - Summary`, `EPD Rules`, `Loan - Communications`,
`Loan - Servicing Fields`.

`loan_id` is already `2042` if you set it in step 0.

---

## What you cannot test, and why

Don't spend time hunting for these — they aren't wired:

- **FIN-02 outbound webhook.** `notifyProofUploaded` has zero call sites outside
  its own tests. Uploading a proof notifies nobody, and setting
  `FINANCE_API_BASE_URL` / `FINANCE_WEBHOOK_API_KEY` changes nothing.
- **FIN-05 decision callback.** The `finance:decision` scope exists; no route
  consumes it. Hence the SQL in step 4e.
