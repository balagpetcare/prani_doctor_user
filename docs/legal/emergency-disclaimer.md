# Emergency Service Limitation Notice

**CMS setting:** Emergency limitation (`mobile` emergency limitation config)  
**Default version:** `2026-05-30.1`  
**Consent type:** `EMERGENCY_SERVICE`  
**Framework:** U0 / U1 / U2 / U3

---

## 1. What this notice covers

This notice applies when you use **urgent or emergency-oriented** features:

- Booking a service request marked **emergency doctor**
- **Instant care** sheet (phone dial + doctor discovery)
- AI outputs flagged as **possible emergency** (`aiEmergency` context)
- Pending emergency requests awaiting assignment

It does **not** replace professional judgment or local emergency procedures.

## 2. What Prani Doctor is not

Prani Doctor is **not**:

- A 24/7 veterinary clinic or hospital  
- An ambulance or emergency dispatch service  
- A guarantee that any doctor is available, online, or nearby  
- Responsible for clinical outcomes of independent providers  

## 3. How urgent booking actually works

When you request emergency doctor service:

1. A **service request** is created in **pending** status  
2. **Operations or admin** may assign a doctor — this is not automatic dispatch  
3. Doctor profiles may show `acceptsEmergency` — that is **intent**, not real-time on-call status  
4. We **do not promise** response times, arrival times, or outcomes in user-facing copy  

Internal SLA targets for operations are **not** user guarantees.

## 4. Instant care and phone dial

The instant care flow may:

- Display educational urgency information  
- Offer a **phone dial** to a configured emergency or support number  
- List doctors filtered for emergency acceptance  

Dialing a number does not mean Prani Doctor has dispatched help.

## 5. AI and emergency

If AI flags possible emergency:

- It is **guidance only** — not confirmation of diagnosis  
- Escalation strips explain that **human review ≠ treatment**  
- You must contact a **local veterinarian or emergency services** immediately for life-threatening situations  

## 6. Your responsibilities

You agree to:

- Seek **immediate in-person or local emergency care** when an animal’s life is at risk  
- Not delay treatment because you are waiting for app assignment  
- Provide accurate location and symptom information  
- Accept that assigned providers are **independent professionals**  

## 7. First emergency booking

The first time you book an **emergency doctor** service request, the app records acceptance of this notice version (`emergencyAcceptedVersion` / `LegalConsentEvent`).

## 8. Limitation of liability

To the extent permitted by law, Prani Doctor is not liable for delays in provider response, unavailability, or outcomes of urgent care arranged through the platform.

## 9. Contact

**Urgent animal risk:** contact a licensed veterinarian or local emergency services first.  
**Platform support:** support@pranidoctor.com

---

**Canonical:** `pranidoctor-web/docs/compliance/emergency/emergency-service-limitation-plan.md`  
**Enforcement:** Server guard on `EMERGENCY_DOCTOR` create; U1/U2 banners on instant care and booking
