# Privacy Policy — Prani Doctor User App

**Effective date:** 2026-05-22  
**App:** Prani Doctor (Android)  
**Package:** `com.pranidoctor.user.pranidoctor_user`  
**Operator:** Prani Doctor / Animal Doctors  

> **Note:** Publish this document at a public HTTPS URL (e.g. `https://pranidoctor.com/privacy`) and set `PRIVACY_POLICY_URL` in release builds. The in-app Settings screen links to that URL.

---

## 1. Overview

Prani Doctor helps pet and livestock owners book veterinary and related services. This policy describes what data the mobile app collects, how it is used, stored, and how you can request deletion.

---

## 2. Data we collect

| Data | Purpose | Sent to server |
|------|---------|----------------|
| **Phone number** | Account login (OTP/password) | Yes |
| **Name, email** | Profile and service communication | Yes |
| **Location hierarchy** (division, district, upazila, union, village) | Service area matching | Yes |
| **Animal profiles** | Bookings and treatment context | Yes |
| **Device identifier** | Session and device registry | Yes |
| **FCM push token** | Appointment and service notifications (when push enabled) | Yes |
| **App version & platform** | Support and compatibility | Yes |

We do **not** sell personal data to third parties.

---

## 3. Local cache (on your device)

The app stores data locally for performance and offline use:

| Storage | Content | Retention |
|---------|---------|-----------|
| **Secure storage** | Access and refresh tokens | Until logout |
| **Hive cache — profile** | Profile snapshot | Up to 24 hours, refreshed when online |
| **Hive cache — appointments** | Appointment list | Up to 24 hours |
| **Hive cache — area hierarchy** | Location picker data | Up to 7 days |
| **Hive outbox** | Pending bookings/updates while offline | Until synced or marked failed |

Cached data is encrypted at rest where supported by the platform (tokens in secure storage). Clearing app data or uninstalling removes local cache.

---

## 4. Notifications

When `ENABLE_PUSH=true` and Firebase is configured:

- We request notification permission (Android 13+).
- A Firebase Cloud Messaging (FCM) token is registered with our backend.
- We send notifications about appointments, service updates, and account-related messages.
- You can disable notifications in system settings; the app continues to work without push.

When push is disabled at build time (`ENABLE_PUSH=false`), no FCM token is collected.

---

## 5. Data retention (server)

- **Account data** — retained while your account is active.
- **Service and appointment records** — retained as required for veterinary service history and legal obligations.
- **Device tokens** — removed or updated on logout and token refresh.
- **Audit logs** — retained per internal policy and applicable law.

Exact retention periods may vary by record type and regulatory requirements in Bangladesh.

---

## 6. Data deletion

You may request account and personal data deletion by contacting:

- **Email:** support@pranidoctor.com  
- **In-app:** Settings → sign out (clears local session; server deletion requires support request)

After verified deletion:

- Profile and authentication credentials are removed or anonymized where legally permitted.
- Local app data is cleared on logout or uninstall.
- Some transactional records may be retained where required by law.

---

## 7. Third-party services

| Service | Purpose |
|---------|---------|
| **Firebase Cloud Messaging** | Push delivery (Google) |
| **Google Play** | App distribution |

Third-party processors operate under their own privacy terms.

---

## 8. Security

- API communication uses HTTPS in production builds.
- Auth tokens are stored in platform secure storage.
- Release builds require a configured production API URL.

---

## 9. Children

The app is not directed at children under 13. Accounts should be created by account holders or guardians.

---

## 10. Changes

We may update this policy. Material changes will be reflected in the effective date and, where appropriate, in-app notice.

---

## 11. Contact

**Prani Doctor Support**  
Email: support@pranidoctor.com  

---

*Template for legal review before Play Store publication.*
