# LedgerFlow License Admin Tool — Development

> This folder contains development-only tools for generating license packages from offline request codes.

## Current Tool

```text
generate_license_package.py
```

It accepts the request code generated from the customer device in:

```text
Settings → License → Offline Activation Request → Generate Request Code
```

Then it returns a license package that can be pasted back into:

```text
Settings → License → Signed / Offline License Package → Apply Package
```

---

## Example

```bash
python tools/license_admin/generate_license_package.py \
  --request-code "LFREQ.PASTE_CUSTOMER_REQUEST_CODE_HERE" \
  --serial "LF-SOLO-2026-0001" \
  --customer-name "ABC Store" \
  --edition solo \
  --status active
```

For a network license:

```bash
python tools/license_admin/generate_license_package.py \
  --request-code "LFREQ.PASTE_CUSTOMER_REQUEST_CODE_HERE" \
  --serial "LF-NET-2026-0001" \
  --customer-name "ABC Store" \
  --edition network \
  --max-users 5 \
  --max-devices 3 \
  --enable-feature advancedInventory
```

For a subscription/hosted license with expiry:

```bash
python tools/license_admin/generate_license_package.py \
  --request-code "LFREQ.PASTE_CUSTOMER_REQUEST_CODE_HERE" \
  --serial "LF-HOSTED-2026-0001" \
  --customer-name "ABC Store" \
  --edition hosted \
  --max-users 10 \
  --max-devices 10 \
  --expires-at "2027-05-04T00:00:00Z"
```

---

## Output

The tool prints:

```text
base64url(payloadJson).base64url(signature)
```

Copy the package and send it to the customer.

---

## Important Production Warning

This tool currently uses a development signature placeholder:

```text
SHA256(payload + dev-secret)
```

This is not production-grade licensing security.

Before selling commercially, replace it with:

```text
Private-key signing in the admin tool/server
Public-key verification inside the customer app/API
```

Recommended production algorithms:

```text
Ed25519
RSA-PSS
ECDSA P-256
```

Never ship the private key with the customer app.
