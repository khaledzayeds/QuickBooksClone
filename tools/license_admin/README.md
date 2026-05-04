# LedgerFlow License Admin Tool

> Tools for generating real signed license packages from offline request codes.

## Install Python dependency

```bash
pip install cryptography
```

---

## 1. Generate Ed25519 keypair

```bash
python tools/license_admin/generate_keypair.py
```

The output contains:

```text
PRIVATE KEY BASE64 — KEEP SECRET
PUBLIC KEY BASE64 — paste into Flutter LicensePublicKeyConfig
```

Rules:

```text
Private key stays with the software owner only.
Public key can be shipped in the customer app.
Never commit the real private key to GitHub.
```

Paste the public key into:

```text
QuickBooksFlutter/ledgerflow/lib/features/settings/data/license_public_key.dart
```

---

## 2. Customer generates request code

Inside the customer app:

```text
Settings → License → Offline Activation Request → Generate Request Code
```

Customer sends you:

```text
LFREQ.<base64url payload>
```

---

## 3. Generate signed license package

Solo example:

```bash
python tools/license_admin/generate_license_package.py \
  --request-code "LFREQ.PASTE_CUSTOMER_REQUEST_CODE_HERE" \
  --private-key "PASTE_PRIVATE_KEY_BASE64_HERE" \
  --serial "LF-SOLO-2026-0001" \
  --customer-name "ABC Store" \
  --edition solo \
  --status active
```

Network example:

```bash
python tools/license_admin/generate_license_package.py \
  --request-code "LFREQ.PASTE_CUSTOMER_REQUEST_CODE_HERE" \
  --private-key "PASTE_PRIVATE_KEY_BASE64_HERE" \
  --serial "LF-NET-2026-0001" \
  --customer-name "ABC Store" \
  --edition network \
  --max-users 5 \
  --max-devices 3 \
  --enable-feature advancedInventory
```

Hosted/subscription example with expiry:

```bash
python tools/license_admin/generate_license_package.py \
  --request-code "LFREQ.PASTE_CUSTOMER_REQUEST_CODE_HERE" \
  --private-key "PASTE_PRIVATE_KEY_BASE64_HERE" \
  --serial "LF-HOSTED-2026-0001" \
  --customer-name "ABC Store" \
  --edition hosted \
  --max-users 10 \
  --max-devices 10 \
  --expires-at "2027-05-04T00:00:00Z"
```

---

## 4. Customer applies package

The tool prints:

```text
base64url(payloadJson).base64url(ed25519Signature)
```

Customer pastes it into:

```text
Settings → License → Signed / Offline License Package → Apply Package
```

The app verifies the package using the embedded public key.

---

## Security Notes

- Do not ship the private key with the app.
- Do not save the private key in the repository.
- Use different keys for development and production.
- For hosted/online activation, keep signing on the server only.
- The Flutter app should only verify packages with the public key.
