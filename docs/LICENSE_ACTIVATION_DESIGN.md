# LedgerFlow License Activation Design

> هدف الملف: توثيق نظام الترخيص التجاري للبرنامج: السيريال، التفعيل الأونلاين، التفعيل الأوفلاين، بصمة الجهاز، حدود النسخ، وآلية القفل/الفتح داخل التطبيق.

---

## 1. Editions

النظام التجاري يدعم نفس البرنامج بترخيص مختلف:

| Edition | الاسم التجاري | التشغيل | قاعدة البيانات | المستخدمين | الأجهزة | ملاحظات |
|---|---|---|---|---:|---:|---|
| Trial | Trial / Demo | Demo + Local محدود | SQLite | 1 | 1 | للتجربة والديمو |
| Solo | Solo Desktop | جهاز واحد | SQLite / Local API | 1 | 1 | قريب من QuickBooks Desktop لجهاز واحد |
| Network | Network / LAN | سيرفر محلي + أجهزة LAN | SQL Server | حسب الترخيص | حسب الترخيص | مناسب للشركات الصغيرة |
| Hosted | Hosted / Cloud | API أونلاين | Hosted DB | حسب الاشتراك | حسب الاشتراك | اشتراك وتجديد |

---

## 2. License Features

كل License تتحكم في Feature Flags:

```text
localMode
lanMode
hostedMode
backupRestore
demoCompany
advancedInventory
payroll
```

أمثلة:

```text
Solo:
- localMode ✅
- lanMode ❌
- hostedMode ❌
- backupRestore ✅
- advancedInventory ❌
- payroll ❌
```

```text
Network:
- localMode ✅
- lanMode ✅
- hostedMode ❌
- backupRestore ✅
- advancedInventory ✅
- payroll optional
```

```text
Hosted:
- localMode ❌
- lanMode ❌
- hostedMode ✅
- backupRestore ✅
- advancedInventory ✅
- payroll optional
```

---

## 3. Serial vs Signed License

لا نعتمد على serial نصي فقط. السيريال يكون رقم مبيعات/تعريف، لكن التفعيل الحقيقي يكون Signed License Payload.

### Serial Example

```text
LF-SOLO-2026-7H8K-2M9Q
LF-NET-2026-D4Q9-P2LA
LF-CLOUD-2026-HOST-8X2M
```

السيريال وحده لا يكفي أمنيًا. العميل ممكن يكتبه في البرنامج، لكن البرنامج لازم يستلم License Payload موقّع من صاحب البرنامج أو من Activation Server.

---

## 4. Signed License Payload

الـ payload هو JSON فيه بيانات الترخيص:

```json
{
  "licenseId": "lic_2026_000001",
  "serial": "LF-SOLO-2026-7H8K-2M9Q",
  "customerName": "ABC Store",
  "edition": "solo",
  "status": "active",
  "maxUsers": 1,
  "maxDevices": 1,
  "offlineGraceDays": 30,
  "features": {
    "localMode": true,
    "lanMode": false,
    "hostedMode": false,
    "backupRestore": true,
    "demoCompany": true,
    "advancedInventory": false,
    "payroll": false
  },
  "issuedAt": "2026-05-04T00:00:00Z",
  "expiresAt": null,
  "deviceId": "optional-device-fingerprint-hash"
}
```

ثم يتم توقيع هذا payload بتوقيع رقمي:

```text
licensePackage = base64url(payloadJson) + "." + base64url(signature)
```

التطبيق يحتوي على Public Key فقط للتحقق من التوقيع. Private Key يظل مع صاحب البرنامج فقط أو في Activation Server.

---

## 5. Device Fingerprint

Device Fingerprint هو بصمة للجهاز تستخدم لربط الترخيص بجهاز معين.

### مصادر مقترحة للبصمة

```text
machineGuid / deviceId
computerName
OS user / install id
app installation id
motherboard/volume id if available
```

لا نخزن البيانات الخام. نعمل hash:

```text
deviceFingerprint = SHA256(normalizedDeviceInfo + appSalt)
```

### مهم

- البصمة لا تكون حساسة جدًا حتى لا تتغير مع تحديث ويندوز بسيط.
- الأفضل وجود Installation ID ثابت يتم توليده أول مرة.
- في Network edition، السيرفر هو الجهاز الأساسي، والعملاء لهم device slots.

---

## 6. Online Activation Flow

```text
1. العميل يدخل Serial داخل البرنامج
2. البرنامج يحسب Device Fingerprint
3. البرنامج يرسل للسيرفر:
   - serial
   - deviceFingerprint
   - appVersion
   - companyName optional
4. Activation Server يتحقق:
   - serial موجود
   - غير ملغي
   - لم يتجاوز max devices
   - لم ينتهِ
5. Server يرجع Signed License Payload
6. التطبيق يحفظ license package محليًا
7. التطبيق يتحقق من التوقيع عند كل تشغيل
```

### Endpoint مقترح

```http
POST /api/licenses/activate
```

Request:

```json
{
  "serial": "LF-SOLO-2026-7H8K-2M9Q",
  "deviceFingerprint": "sha256...",
  "appVersion": "1.0.0",
  "companyName": "ABC Store"
}
```

Response:

```json
{
  "licensePackage": "base64payload.base64signature"
}
```

---

## 7. Offline Activation Flow

ده مهم جدًا للعملاء اللي مافيهمش إنترنت.

### داخل البرنامج عند العميل

البرنامج يعرض Activation Request Code:

```text
REQ-LF-2026-XXXX-XXXX
```

الـ request code يحتوي أو يمثل:

```json
{
  "serial": "LF-SOLO-2026-7H8K-2M9Q",
  "deviceFingerprint": "sha256...",
  "requestedAt": "2026-05-04T00:00:00Z"
}
```

### عند صاحب البرنامج

صاحب البرنامج يأخذ Request Code من العميل، ويدخله في License Admin Tool.

الأداة تولد Offline Activation Code:

```text
OFF-LF-2026-XXXX-XXXX-XXXX
```

أو license package طويل موقّع.

### عند العميل

العميل يدخل Offline Activation Code داخل البرنامج، والبرنامج:

```text
1. يفك الكود
2. يتحقق من التوقيع بالـ Public Key
3. يتحقق أن deviceFingerprint مطابق
4. يحفظ الترخيص
```

---

## 8. Expiry / Renewal Rules

عند كل تشغيل:

```text
1. اقرأ license package
2. تحقق من التوقيع
3. تحقق من status
4. تحقق من expiresAt
5. تحقق من deviceFingerprint لو الترخيص مربوط بجهاز
6. تحقق من offline grace لو Hosted/Subscription
7. افتح أو اقفل الميزات
```

### Grace Period

لو Hosted أو Subscription:

```text
lastValidatedAt + offlineGraceDays
```

لو الفترة انتهت بدون تحقق أونلاين:

```text
تقفل الميزات المدفوعة أو تتحول لوضع read-only
```

---

## 9. License Gates داخل التطبيق

تمت إضافة skeleton داخل Flutter:

```text
LicenseFeature
LicenseSettingsModel.allows(feature)
LicenseGate widget
LicenseBlockedScreen
```

مثال:

```dart
LicenseGate(
  feature: LicenseFeature.backupRestore,
  child: BackupSettingsScreen(),
)
```

لو الترخيص لا يسمح بالميزة، تظهر شاشة:

```text
License Required
Open License Settings
Back to Settings
```

---

## 10. إصدار سيريال كصاحب البرنامج

### Online Mode

أنت كصاحب البرنامج تستخدم License Admin Panel:

```text
1. اختار العميل
2. اختار Edition: Solo / Network / Hosted
3. حدد users/devices/features/expiry
4. Generate Serial
5. العميل يدخل السيريال في البرنامج
6. البرنامج يفعّل أونلاين
```

### Offline Mode

```text
1. العميل يعطيك Request Code من البرنامج
2. تفتح License Admin Tool عندك
3. تدخل Request Code
4. تختار Edition/features/expiry
5. الأداة تطلع Offline Activation Code
6. تبعت الكود للعميل
7. العميل يدخله في البرنامج
```

---

## 11. أمان مهم

- لا تضع Private Key داخل تطبيق العميل.
- تطبيق العميل يحتوي Public Key فقط.
- لا تعتمد على serial pattern فقط.
- لا تعتمد على SharedPreferences وحدها في الإنتاج.
- خزن license package في مكان مناسب وممكن تعمل أكثر من نسخة:
  - app data
  - local secure storage
  - database settings
- أي تحقق مهم يجب أن يتم أيضًا في backend API وليس Flutter فقط.

---

## 12. خطوات التنفيذ القادمة

### Flutter

- [x] License skeleton screen/model/provider.
- [x] License gates helper.
- [x] Gate Backup Settings with `backupRestore`.
- [x] Gate Payroll with `payroll`.
- [ ] Gate Connection modes according to local/lan/hosted features.
- [ ] Gate Start Mode options according to license features.
- [ ] Add Activation Request Code screen.
- [ ] Add Offline Activation Code input.

### Backend

- [ ] Add license contracts.
- [ ] Add license verification service.
- [ ] Add public-key signature verification.
- [ ] Add activation endpoint for online activation.
- [ ] Add device registration table.
- [ ] Add license audit log.

### Admin Tool

- [ ] Build License Admin app/page.
- [ ] Generate serials.
- [ ] Generate signed license payloads.
- [ ] Generate offline activation codes.
- [ ] Track customers/devices/renewals.
