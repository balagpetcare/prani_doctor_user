# Translation Glossary — Prani Doctor User App (Canonical)

**Locales:** `bn` (primary), `en` (secondary)  
**Rule:** One meaning → one Bangla phrase app-wide.  
**Companion:** [BN_LANGUAGE_STYLE_GUIDE.md](./BN_LANGUAGE_STYLE_GUIDE.md), [FINAL_LANGUAGE_AUDIT.md](./FINAL_LANGUAGE_AUDIT.md)

Format: **English | Bangla | Usage | Reason**

---

## Auth & session

| English | Bangla | Usage | Reason |
|---------|--------|-------|--------|
| Sign in | প্রবেশ করুন | Login button, link | Meaning-first; not লগইন |
| Log in | প্রবেশ করুন | Same as Sign in | Single term |
| Create account | নতুন অ্যাকাউন্ট খুলুন | Register CTA | Rural-friendly |
| Welcome back | আবার স্বাগতম | Login header | Warm tone |
| Sign in to manage your farm… | খামার, পশু ও ডাক্তারি সেবা দেখতে প্রবেশ করুন। | Login subtitle | Explains value |
| Session expired | সময় শেষ | Error title | Short |
| Session expired. Please sign in again. | সময় শেষ। আবার প্রবেশ করুন। | Alert body | Action clear |
| This field is required | এই তথ্য দিন | Validation | Not আবশ্যক ক্ষেত্র |
| OTP | ওটিপি | SMS flow | Pronunciation, not translation |
| Password | পাসওয়ার্ড | Form label | Standard loan word |
| Email | ইমেইল | Form label | Standard loan word |
| Log out | বের হন | Menu | Not লগআউট |

---

## Common actions

| English | Bangla | Usage | Reason |
|---------|--------|-------|--------|
| Save | সংরক্ষণ করুন | Generic button | Not সেভ |
| Save details | তথ্য সংরক্ষণ করুন | Profile save | Specifies data |
| Submit | সংরক্ষণ করুন | Forms | Farmers expect “save” |
| Cancel | বাতিল | Dialogs, chips | Short |
| Delete | মুছে ফেলুন | Destructive | Clear |
| Edit | সম্পাদনা | Lists | Standard |
| Add | যোগ করুন | CTAs | Standard |
| Try again | আবার চেষ্টা করুন | Errors | Not পুনরায় প্রয়াস |
| Continue | এগিয়ে যান | Flow | Standard |
| Back | পিছনে | Navigation | Onboarding |
| Next | পরের ধাপ | Onboarding | Step clarity |
| Get started | শুরু করুন | Onboarding end | Action |
| OK | ঠিক আছে | Dialogs | Not ওকে |
| Dismiss | বন্ধ করুন | Banners | Plain |
| Refresh / Update | আপডেট করুন | Pull, sync | Not রিফ্রেশ |
| Loading | লোড হচ্ছে | Wait states | Familiar |

---

## Status & filters (use only these)

| English | Bangla | Usage | Reason |
|---------|--------|-------|--------|
| All | সব | Filters | One word |
| Active | সক্রিয় | Status | Livestock context |
| Inactive | বন্ধ | Status | Short |
| Draft | খসড়া | Fattening batch | Not English “Draft” |
| Pending | অপেক্ষমাণ | Orders, sync | One term |
| Completed | সম্পন্ন | Orders | One term |
| Cancelled | বাতিল | Orders | Matches Cancel |
| Failed | কাজ সম্পন্ন হয়নি | Jobs | Not “Failed” alone |
| Something went wrong | সমস্যা হয়েছে | Generic error | No “Error 500” |

---

## Location (use **লোকেশন** only)

| English | Bangla | Usage | Reason |
|---------|--------|-------|--------|
| Location | লোকেশন | Section title, permission | Consistent loan word |
| Select your location | আপনার লোকেশন বেছে নিন | Area picker | Not অবস্থান |
| Allow location access | লোকেশন ব্যবহারের অনুমতি দিন | Permission | System-style |
| Selected location | নির্বাচিত লোকেশন | Area summary | — |
| Farm location | খামারের লোকেশন | Profile step | Domain |

Do **not** mix অবস্থান and লোকেশন in the same app.

---

## Farm & animals

| English | Bangla | Usage | Reason |
|---------|--------|-------|--------|
| Farm | খামার | All modules | Not ফার্ম |
| Animal | পশু | Lists, forms | Primary term |
| Cow | গরু | Species | — |
| Add animal | পশু যোগ করুন | CTA | — |
| Create animal | নতুন পশু যোগ করুন | Form title | User-requested UX |
| Animal details | পশুর বিবরণ | Screen title | — |
| Breed | জাত | Field | — |
| Weight | ওজন | Field | Always with কেজি in inputs |

---

## Services & clinical

| English | Bangla | Usage | Reason |
|---------|--------|-------|--------|
| Doctor | ডাক্তার | UI | Not চিকিৎসক |
| Service booking | সেবা বুকিং | Appointments | Not অ্যাপয়েন্টমেন্ট |
| Book a doctor | ডাক্তার ডাকুন | Home CTA | Action |
| Treatment | চিকিৎসা | Module | — |
| Vaccine | টিকা | Module | — |
| Symptoms | লক্ষণ | Form | — |
| Emergency | জরুরি | Search, filter | — |

---

## Inventory & stock

| English | Bangla | Usage | Reason |
|---------|--------|-------|--------|
| Inventory | মজুদ | Module title | Not ইনভেন্টরি |
| Feed stock | খাদ্য মজুদ | Subsection | — |
| Medicine stock | ওষুধ মজুদ | Subsection | — |
| Add stock | মজুদ যোগ করুন | CTA | — |
| Select a farm first | আগে খামার বেছে নিন | Gate | — |
| No feeding logs yet. | এখনো খাওয়ানোর তথ্য নেই। | Empty | Natural |

---

## Fattening

| English | Bangla | Usage | Reason |
|---------|--------|-------|--------|
| Fattening | মোটাতাজাকরণ | Module | Domain term |
| Fattening batches | মোটাতাজাকরণ ব্যাচ | List title | — |
| Create fattening batch | নতুন ব্যাচ তৈরি করুন | CTA | — |
| Record weight | ওজন লিখুন | CTA | Action |
| Weight history | ওজনের তালিকা | Screen | — |

---

## Offline & sync

| English | Bangla | Usage | Reason |
|---------|--------|-------|--------|
| Offline | অফলাইন | Banner | Loan word |
| Online | অনলাইন | Status | Loan word |
| Saved offline — will sync when online | অফলাইনে সংরক্ষিত — অনলাইনে গেলে যুক্ত হবে | Snackbar | Full meaning |
| Offline mode — showing last saved data | অফলাইন মোড — সর্বশেষ সংরক্ষিত তথ্য দেখানো হচ্ছে | Home banner | — |

---

## API errors (code → message)

| English | Bangla | Usage | Reason |
|---------|--------|-------|--------|
| USER_NOT_FOUND | ব্যবহারকারী খুঁজে পাওয়া যায়নি | API map | No raw code in UI |
| NETWORK_ERROR | ইন্টারনেট সংযোগ পরীক্ষা করুন | API map | Actionable |
| OFFLINE | আপনি অফলাইনে আছেন | API map | Plain |

---

## Media & tech

| English | Bangla | Usage | Reason |
|---------|--------|-------|--------|
| Camera | ক্যামেরা | Picker | Loan word |
| Gallery | গ্যালারি | Picker | Loan word |
| Add photo | ছবি দিন | Upload CTA | User-requested |
| QR code | কিউআর কোড | Animal tag | — |
| AI assistant | এআই সহকারী | Search | — |
| Language | ভাষা | Settings | — |
| Bangla | বাংলা | Picker label | Native script |
| English | English | Picker label | Keep Latin for EN option |

---

## Rejected alternatives (do not use)

| Avoid | Use instead |
|-------|-------------|
| লগইন করুন | প্রবেশ করুন |
| সেভ করুন | সংরক্ষণ করুন / তথ্য সংরক্ষণ করুন |
| অবস্থান (mixed with লোকেশন) | লোকেশন only |
| প্রমাণীকরণ | যাচাই করুন |
| নিবন্ধীকরণ | নতুন অ্যাকাউন্ট খুলুন |
| ত্রুটি | সমস্যা হয়েছে |
| ইনভেন্টরি | মজুদ |

---

## Change log

| Date | Change |
|------|--------|
| 2026-05-24 | Reformatted to English \| Bangla \| Usage \| Reason |
| 2026-05-24 | Finishing pass: status filters, fattening, location consistency |

---

*Hand-reviewed overrides: `assets/i18n/bn_curated.json`. Regenerate: `dart run tool/i18n/build_localization.dart`.*
