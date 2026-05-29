# Bangla Language Style Guide — Prani Doctor User App

**Audience:** Translators, reviewers, product, and engineering  
**Locale:** `bn` (Bangladesh)  
**Companion:** [TRANSLATION_GLOSSARY.md](./TRANSLATION_GLOSSARY.md), [LOCALIZATION_MASTER_PLAN.md](./LOCALIZATION_MASTER_PLAN.md)

---

## 1. Purpose

Bangla copy in Prani Doctor is written for **farmers and livestock owners in Bangladesh**, many of whom use smartphones daily but do not read formal or literary Bengali. Every string should feel **friendly, short, and clear** — as if a trusted local vet or field worker is explaining the next step.

**Do not translate word-for-word from English.** Translate **meaning and intent**.

---

## 2. Core principles

| Principle | Explanation |
|-----------|-------------|
| Meaning first | Ask: “What is the user trying to do?” then write Bangla for that action. |
| Short | Prefer 2–6 words for buttons; one short sentence for hints. |
| Spoken, not literary | Use language heard in markets and villages, not newspapers. |
| One idea per string | Split long English into two UI lines if needed. |
| Consistent terms | Always use glossary terms for animals, farm, booking, etc. |
| Respect the user | No blame (“আপনি ভুল করেছেন”); say what to fix. |

---

## 3. Tone

| Do | Don't |
|----|-------|
| Warm, helpful | Cold, bureaucratic |
| “তথ্য দিন” | “আবেদনপত্র জমা দিন” |
| “যাচাই করুন” | “প্রমাণীকরণ সম্পন্ন করুন” |
| “অ্যাকাউন্ট খুলুন” | “নিবন্ধীকরণ করুন” |
| “সমস্যা হয়েছে” | “ত্রুটি ঘটেছে: Exception…” |
| “আবার চেষ্টা করুন” | “পুনরায় প্রয়াস করুন” |

**Person:** Use **আপনি** (polite) for instructions. Avoid overly formal **আপনাকে অনুরোধ করা হচ্ছে**.

**Punctuation:** Bengali full stop **।** optional in short labels; use consistently within a screen.

---

## 4. Technical and loan words

Common technology words stay in **Bangla pronunciation** (not unnatural pure Bengali). See glossary for the full list.

| English | Bangla UI form |
|---------|----------------|
| API | এপিআই |
| GPS | জিপিএস |
| SMS | এসএমএস |
| QR | কিউআর |
| OTP | ওটিপি |
| Camera | ক্যামেরা |
| Location | লোকেশন |
| Bluetooth | ব্লুটুথ |
| Online | অনলাইন |
| Offline | অফলাইন |
| Version | ভার্সন |
| Password | পাসওয়ার্ড |
| Email | ইমেইল |
| App | অ্যাপ |

**Do not** invent Bengali for widely used tech words (e.g. avoid “ছবি ধারণ যন্ত্র” for camera).

**Brand name:** **প্রাণী ডাক্তার** — do not translate “PraniDoctor” in user-facing Bangla unless legally required; subtitle may explain in Bangla.

---

## 5. Domain vocabulary (livestock & farm)

| Concept | Preferred Bangla | Notes |
|---------|------------------|-------|
| Animal | পশু | Generic |
| Cow | গরু | |
| Goat | ছাগল | |
| Farm | খামার | |
| Batch (group) | ব্যাচ / দল | Use **দল** if “batch” confuses; glossary picks one per screen |
| Vaccine | টিকা | |
| Treatment | চিকিৎসা | |
| Doctor (vet) | ডাক্তার | In context of service |
| Appointment / service booking | সেবা বুকিং | Not “অ্যাপয়েন্টমেন্ট” |
| Health record | স্বাস্থ্য তথ্য | |
| Feed | খাদ্য | |
| Milk | দুধ | |
| Weight | ওজন | Include unit: **কেজি** |
| Money | টাকা | Prefix **৳** in UI |

---

## 6. UI element patterns

### Buttons (actions)

| Intent | Bangla pattern |
|--------|----------------|
| Primary save | সংরক্ষণ করুন / তথ্য সংরক্ষণ করুন |
| Submit form | সংরক্ষণ করুন |
| Login | প্রবেশ করুন |
| Sign up | নতুন অ্যাকাউন্ট খুলুন |
| Cancel | বাতিল |
| Delete | মুছে ফেলুন |
| Retry | আবার চেষ্টা করুন |
| Continue | এগিয়ে যান |
| Back | পিছনে |
| Start (onboarding) | শুরু করুন |

### States

| State | Bangla |
|-------|--------|
| Loading | লোড হচ্ছে |
| Pending | অপেক্ষমাণ |
| Completed | সম্পন্ন |
| Failed / error | সমস্যা হয়েছে |
| Offline saved | অফলাইনে সংরক্ষিত — অনলাইনে গেলে যুক্ত হবে |

### Empty states

Structure: **What’s missing** + **what to do**.

- Example: “এখনো কোনো পশু যোগ করা হয়নি।” → button: “পশু যোগ করুন”

### Errors

Structure: **Plain problem** + **action** (no codes, no “Error 500”).

- Bad: `NetworkException: Connection refused`
- Good: “ইন্টারনেট সংযোগ নেই। আবার চেষ্টা করুন।”

### Notifications

Use **বার্তা** for notification channel/category labels, not “নোটিফিকেশন”.

---

## 7. Grammar and formatting

| Topic | Rule |
|-------|------|
| Numbers | Latin digits `0-9` for V1 (phone familiarity) |
| Currency | `৳১,২০০` or `৳ 1200` — match app `intl` format |
| Units | Always show unit: `৫০ কেজি`, `১০ লিটার` |
| Dates | Bengali month names optional V2; V1: `২৪ মে ২০২৬` or localized `DateFormat` |
| Plurals | “{count}টি পশু” — use ARB plural rules |
| Gender | Avoid gendered verbs where possible; use neutral “করুন” |

---

## 8. Words and phrases to avoid

| Avoid | Use instead |
|-------|-------------|
| আবেদনপত্র | তথ্য / ফর্ম |
| প্রমাণীকরণ | যাচাই |
| নিবন্ধীকরণ | অ্যাকাউন্ট খুলুন |
| পুনরায় প্রয়াস | আবার চেষ্টা |
| ত্রুটি (alone) | সমস্যা |
| ব্যবহারকারী | (omit) / “আপনি” |
| ইনভেন্টরি (Bangla script) | মজুদ / স্টক (see glossary) |
| ডিলিট | মুছে ফেলুন |
| সাবমিট | সংরক্ষণ করুন / পাঠান |

---

## 9. English residue

| Situation | Rule |
|-----------|------|
| Button must be one English word in EN locale | Full Bangla in bn locale |
| Product name (Qurbani) | **কুরবানি** — explain in subtitle if needed |
| Enum from API (`ACTIVE`, `COW`) | Never show raw; map to glossary |
| “OK” | **ঠিক আছে** |
| “N/A” | **নেই** / **জানা নেই** |

---

## 10. Review checklist (per string)

1. Would a farmer in Rajshahi understand this without help?
2. Is it the shortest clear version?
3. Does it match the glossary?
4. Any formal/literary word? Replace.
5. Any English word not in the technical allowlist? Replace or transliterate.
6. Does it fit a mobile button (roughly &lt; 30 characters)?

---

## 11. Examples (reference)

| English (meaning) | ✅ Good Bangla | ❌ Poor Bangla |
|-------------------|---------------|----------------|
| Login | প্রবেশ করুন | লগইন |
| Sign up | নতুন অ্যাকাউন্ট খুলুন | সাইন আপ |
| Save profile | তথ্য সংরক্ষণ করুন | সংরক্ষণ |
| Profile | প্রোফাইল | ব্যক্তিগত প্রোফাইল বিবরণ |
| Session expired | সময় শেষ — আবার প্রবেশ করুন | সেশন এক্সপায়ার্ড |
| Permission denied | এই কাজের অনুমতি নেই | অনুমতি প্রত্যাখ্যাত |
| Select a farm first | আগে খামার বেছে নিন | অনুগ্রহ করে খামার নির্বাচন করুন |
| Showing cached data | সংরক্ষিত তথ্য দেখানো হচ্ছে | ক্যাশড ডেটা প্রদর্শন |

---

*Changes to this guide require product + native reviewer sign-off before bulk ARB updates.*
