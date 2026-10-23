# Nivo78 Family Product Strategy & Roadmap
## The Frictionless Modular Ecosystem
### Canonical Product Strategy, Architecture, Governance & Execution Direction

**Author:** Nivo78 Architecture & Strategy  
**Date:** September 7, 2026  
**Status:** Canonical Master Strategy & Architecture Document (Level 1 Authority)  
**Audience:** Nivo78 Engineering, Product Maintainers, and Business Operations  

---

## 1. Executive Summary

Nivo78 is a family of focused software utilities designed around a simple principle:

> **Each application should solve a clearly defined problem exceptionally well, work independently, and become more valuable—not more dependent—when combined with other Nivo78 applications.**

The Nivo78 philosophy emphasizes:
- Local-first operation
- User ownership of data
- Reliability
- Simplicity
- Practical workflows
- Modularity
- Long-term maintainability
- Minimal unnecessary dependencies

Nivo78 deliberately avoids the assumption that every business function belongs inside one large application.

Instead, the family consists of focused applications that can operate independently while providing well-defined interoperability where integration provides genuine user value.

The primary trade workflow is a **two-application ecosystem**:

1. **N78-Estimate** — estimating, takeoff, pricing, and customer quotes (desktop workstation).
2. **N78-Ops** — customers, jobs, scheduling, field operations, invoicing, payments, and **planned** receipt capture / job-cost logging (V2/V3).

Do not ship or market a third trade app.

The intended relationship is:

$$\text{\textbf{Standalone first. Integrated second.}}$$

A user may adopt one application, two applications, or the entire family. No core application should require another Nivo78 application merely to perform its fundamental purpose.

---

## 2. The Standalone-First Principle

This is a fundamental Nivo78 architectural and product principle.

### 2.1 Every Core Application Must Stand on Its Own
Each core Nivo78 application should provide meaningful value when used independently.

* **N78-Estimate**: Must be useful to a contractor who only wants estimating and quoting on the desktop.
* **N78-Ops**: Must be useful to a contractor who wants customer, job, scheduling, invoicing, and field-management capabilities without N78-Estimate.

Integration should enhance these applications rather than make them dependent upon one another.

### 2.2 Integration Is an Advantage, Not a Requirement
When multiple Nivo78 applications are used together, information should move between them in ways that reduce duplicate entry and administrative effort.

For example:
- **N78-Estimate $\rightarrow$ N78-Ops**: can eliminate re-entering customer, job, scope, and quote information when a bid is accepted.

But a user should always retain the ability to use the receiving application independently.

### 2.3 Nivo78 Must Not Create Artificial Lock-In
The Nivo78 ecosystem should never make applications artificially dependent upon one another simply to increase ecosystem lock-in.

The reason to use multiple Nivo78 products should be:
$$\textbf{They work better together.}$$
Not:
$$\textit{You cannot use one without buying the others.}$$

This distinction is central to the Nivo78 philosophy.

---

## 3. Nivo78 Core Philosophy

### 3.1 Local First
Core application functionality should operate locally wherever practical.

Internet connectivity may enable optional services and conveniences, but the fundamental usefulness of a Nivo78 application should not depend upon a permanent connection to a Nivo78 cloud service.

### 3.2 User-Controlled Data
Users should have practical control over their business information.

Nivo78 applications should provide appropriate mechanisms for:
- local storage
- backup
- export
- recovery
- transfer
- migration

The goal is durable ownership rather than proprietary data captivity.

### 3.3 Focused Applications
Each application should have a clearly defined mission.

A feature should belong in an application because it supports that application's purpose—not simply because the feature exists somewhere else in the software industry.

When a capability belongs naturally to another Nivo78 application, interoperability should generally be preferred over duplication.

### 3.4 Reliability Before Feature Quantity
Nivo78 should favor:
- predictable behavior
- safe failure
- durable data
- recoverability
- understandable errors
- manageable maintenance

Feature growth should not come at the expense of reliability.

---

## 4. Respect the Work Environment

Nivo78 should recognize that different types of work naturally belong on different devices.

### Desktop
Detailed estimating and quoting benefit from:
- large displays
- keyboard and mouse
- dense information
- rapid numeric entry
- extensive tables
- document generation
- printing

### Mobile
Field operations benefit from:
- quick access
- touch-friendly controls
- minimal data entry
- camera capabilities
- location awareness
- scheduling
- communication
- rapid status changes

Therefore:
$$\textbf{Nivo78 applications do not need identical interfaces or feature sets across platforms.}$$
They need to provide the right experience for the work being performed.

---

## 5. The Core Nivo78 Trade Suite

The three core trade applications are complementary but independently useful.

### 5.1 N78-Estimate

#### Mission
N78-Estimate is the **pre-job estimating and quoting application**. Its primary purpose is to help contractors determine what a job should cost and produce a professional customer quote.

#### Core Responsibilities
N78-Estimate is responsible for capabilities such as:
- material takeoffs
- material pricing
- labor calculations
- pricing formulas
- markup
- tax calculations
- quote numbering (starting at 200)
- quote revisions
- customer information
- scope information
- customer-facing notes
- private estimating information
- customer quote generation
- printable/exportable quote documents
- transfer of appropriate quote information to N78-Ops

#### Product Boundary
N78-Estimate should remain focused on:
$$\textbf{What is this job, what should it cost, and what should the customer be quoted?}$$
It should not become the primary field scheduling, payment, or expense-management application.

#### Standalone Requirement
N78-Estimate must remain fully useful to an operator who never installs or uses N78-Ops.

---

## 6. N78-Ops

### Mission
N78-Ops is the **field operations and customer/job management application**. Its purpose is to manage the operational lifecycle of work.

### Core Responsibilities
N78-Ops is responsible for capabilities such as:
- customer records
- job records
- scheduling
- appointments
- field status
- time tracking
- mileage
- job notes
- invoicing
- milestone billing
- payment records
- operational communication
- receiving appropriate information from N78-Estimate
- recording job costs and (roadmap) receipt capture in-app

### Product Boundary
N78-Ops should focus on:
$$\textbf{What work is happening, when is it happening, for whom, and what has been billed or paid?}$$
It should not reproduce the complete estimating engine.

### Standalone Requirement
N78-Ops must remain fully useful to an operator who creates jobs manually and never uses N78-Estimate.

---

## 7. Field Expenses & Receipts (N78-Ops Roadmap — Not a Standalone App)

### Decision (September 2026)
Receipt photo capture and field job-cost logging are planned for **N78-Ops V2/V3** so operators run the full job lifecycle and spending from the truck without a third install.

### Product Boundary
Ops should own:
$$\textbf{What was spent on this job, with proof, while the work is active?}$$
without requiring a sibling expense application or cross-app expense JSON handoffs.

### Standalone Requirement
N78-Ops must support job-cost visibility without N78-Estimate. N78-Estimate never tracks post-bid receipts.

---

## 8. The Combined Workflow

When used together, the two trade applications form a natural business workflow.

```
N78-Estimate (Desktop)
     │
     │ Accepted quote export
     ▼
  N78-Ops (Field)
```

The applications remain independently useful. The integration simply removes unnecessary duplication.

### Before the Job
**N78-Estimate** $\rightarrow$ Estimate $\rightarrow$ Price $\rightarrow$ Quote

### When the Work Is Accepted
**N78-Estimate $\rightarrow$ N78-Ops** $\rightarrow$ Transfer relevant customer, job, scope, pricing, and billing information.

### During the Work
**N78-Ops** $\rightarrow$ Schedule $\rightarrow$ Perform $\rightarrow$ Track costs $\rightarrow$ Bill $\rightarrow$ Collect

### When Money Is Spent
Record receipts and job costs **in N78-Ops** (V2/V3 roadmap expands capture; basic job expense entry where already shipped).

### Afterward
**N78-Ops / QuickBooks** $\rightarrow$ Use actual-cost information where appropriate for operational, accounting, and financial purposes.

---

## 9. Inter-Application Architecture

Nivo78 applications should communicate through **defined interfaces and transferable information**, not by depending upon each other's internal implementation.

The guiding principle is:
$$\textbf{Exchange information, not internal application state.}$$

For example:
- N78-Estimate should provide N78-Ops with the information required to establish or update an operational job when a quote is accepted.
- N78-Ops should not need to know how N78-Estimate internally calculated that quote.
- Job costs and receipt images should live in N78-Ops, not in a separate expense product.

---

## 10. Frictionless Transfer Direction & Multi-Tier Fallback Protocol

Nivo78 supports multiple practical, resilient mechanisms to transfer information between applications and devices according to a structured 4-tier hierarchy:

1. **Tier 1: Compact QR Profile (Primary Air-Gapped Handshake)**
   - Fast, offline, screen-to-camera transfer for operational metadata and milestones (< 800 bytes). Zero network setup, zero pairing, 100% offline.
2. **Tier 2: Native OS File Transfer (`.n78ops-*.json` — Comprehensive Payload)**
   - Direct file sharing (AirDrop, Android Quick Share, Nearby Share, USB-C, or direct file save) carrying complete line-by-line itemized material bills.
3. **Tier 3: Clipboard / Direct Text Paste (Instant Text Bridge)**
   - Direct clipboard copy/paste for sharing via messaging apps, email drafts, or mobile terminal import.
4. **Tier 4: User-Controlled Cloud Transfer (BYOC Synchronized Storage)**
   - Optional, user-managed sync across personal/business cloud folders (OneDrive, iCloud Drive, Google Drive, Dropbox, Synology) without proprietary Nivo78 cloud lock-in.

No single transfer mechanism should become an unnecessary dependency of the ecosystem. The transfer architecture should remain modular so that additional mechanisms can be introduced when they provide meaningful value.

---

## 11. Transfer Design Standards

Inter-application transfers should be designed to handle normal real-world conditions, including:
- repeated transfers
- duplicate information
- revised information
- interrupted transfers
- incompatible versions
- unsupported fields
- incomplete transfers

The receiving application should respond predictably.

The fundamental standard is:
$$\textbf{A transfer should never silently damage, duplicate, or misrepresent business information.}$$

---

## 12. Identity and Revision

Business records that cross application boundaries should have a stable identity.

The architecture should distinguish between:
- a new record
- the same record transferred again
- a revision of an existing record
- an intentional new record

This is particularly important for estimates and quotes. A revised quote should be capable of being recognized as a revision of the original rather than automatically becoming an unrelated duplicate job.

The exact implementation of record identity and revision tracking belongs in the applicable engineering specification.

---

## 13. Compatibility and Schema Standards

Inter-application data formats should be treated as formal contracts.

Those contracts should define:
- supported versions
- compatibility expectations
- required information
- optional information
- handling of unknown information
- revision behavior
- failure behavior

Applications should fail safely when they cannot reliably process incoming information. They should not silently discard or reinterpret information merely because the sending application is newer.

Detailed file schemas should be maintained as subordinate technical specifications.

---

## 14. Data Ownership and Source of Truth

Each important category of information should have a clear authoritative owner.

| Information Category | Authoritative Application |
| :--- | :--- |
| **Estimate calculations** | N78-Estimate |
| **Quote pricing** | N78-Estimate |
| **Quote revisions** | N78-Estimate |
| **Customer-facing quote** | N78-Estimate |
| **Operational customer/job record** | N78-Ops |
| **Schedule & dispatch** | N78-Ops |
| **Job field status** | N78-Ops |
| **Invoice and payment records** | N78-Ops |
| **Actual field expenses & receipt images** | N78-Ops (V2/V3 expands capture) |
| **Tax organization & accounting** | QuickBooks |

Transferred information does not transfer ownership of the source application's underlying records. This prevents unnecessary coupling between applications.

---

## 15. Information Security and Privacy

Nivo78 should distinguish ordinary business information from sensitive information.

Customer-facing information should not automatically become a container for:
- passwords
- access credentials
- security codes
- signing keys
- private operational secrets

Sensitive information should only be transferred where there is a legitimate requirement and an appropriate security design.

The general standard is:
$$\textbf{Only transfer information to another application when that application actually needs it.}$$

---

## 16. Media and Storage

Applications that capture receipts, photographs, documents, or other large media should manage storage responsibly.

The general direction is to:
- preserve useful information
- avoid unnecessary storage growth
- use appropriate media processing
- keep large media separate from compact structured records where practical
- maintain reliable relationships between records and associated media
- protect against data loss during processing

Exact media formats, resolution targets, compression methods, and storage techniques should be established by the relevant product specification and validated against actual use.

---

## 17. Portfolio Governance

The Nivo78 family contains both core commercial applications and specialized utilities. Because the portfolio is maintained by a small organization, development effort must be deliberately managed.

### Tier 1 — Core Trade Suite (Active Development)
- **N78-Estimate** (desktop)
- **N78-Ops** (field mobile; expenses/receipts roadmap in V2/V3)

These applications receive the highest priority for:
- reliability
- interoperability
- usability
- testing
- maintenance
- meaningful feature development

### Tier 2 — Platform and Business Infrastructure
- **N78-Kit**
- **N78-Theme**
- **N78-Standards**
- **N78-Successor**

These support the development, consistency, governance, financial organization, and continuity of the Nivo78 family. Changes should be purposeful and justified by their role.

### Tier 3 — Specialized Utilities (Maintenance Mode)
- **N78-Book**
- **N78-APA**
- **N78-Life**
- **N78-Dash**
- **N78-Frame**
- **N78-Probe**
- **N78-StlLite**
- **N78-Track**

These applications should generally remain in maintenance mode. Priority should be given to:
- critical defects
- security
- platform compatibility
- required compliance
- necessary maintenance

Feature expansion should require specific justification.

---

## 18. Feature Governance

A feature should not be added simply because it is technically possible.

Before adding a feature, consider:
1. Does it directly support the application's mission?
2. Does another Nivo78 application already own this responsibility?
3. Does it provide meaningful user value?
4. Does it introduce unnecessary complexity?
5. Does it increase maintenance burden?
6. Does it create unnecessary coupling?
7. Would an inter-application interface solve the problem more cleanly?

The preferred architecture is often:
$$\textbf{Keep applications focused and make the connections between them better.}$$

---

## 19. Common Nivo78 Design Language

Nivo78 applications should be recognizable as members of the same family while remaining appropriate to their individual purposes.

Shared standards may address:
- visual identity
- typography
- common controls
- terminology
- navigation
- dialogs
- status presentation
- accessibility
- error handling

The goal is:
$$\textbf{Look alike where appropriate. Operate alike where consistency benefits the user. Remain specialized where the application requires it.}$$

---

## 20. Maintainability Standard

Nivo78 development must account for the entire lifecycle of an application. Every dependency, integration, platform, and feature creates a future maintenance obligation.

Development decisions should therefore consider:
$$\textbf{Build} \longrightarrow \textbf{Release} \longrightarrow \textbf{Maintain} \longrightarrow \textbf{Upgrade} \longrightarrow \textbf{Recover}$$
not simply:
$$\text{Build} \longrightarrow \text{Release}$$

The simplest reliable solution should generally be preferred over a more sophisticated solution that creates disproportionate maintenance burden.

---

## 21. Execution Roadmap

The immediate roadmap follows the natural dependency of the integrated trade workflow while preserving standalone operation.

### Milestone 1 — Strengthen N78-Estimate Transfer
Establish a dependable mechanism for N78-Estimate to provide appropriate quote information to N78-Ops.
- Establish the supported transfer contract (`.n78ops-quote.json`)
- Establish compact transfer capabilities (air-gapped QR code)
- Establish quote identity and revision behavior (`quote_uuid`, `revision_index`)
- Provide a simple operator-initiated transfer workflow
- Validate reliability

The implementation should remain independent of the final technical mechanism selected.

### Milestone 2 — Establish N78-Ops Import
Enable N78-Ops to receive and appropriately use information from N78-Estimate.
- Receive supported quote information
- Recognize new and previously received information
- Handle revisions safely
- Create or update appropriate operational records
- Preserve existing operational information
- Provide clear conflict resolution

N78-Ops must remain fully functional without N78-Estimate.

### Milestone 3 — N78-Ops Field Expenses (V2/V3)
After the Estimate $\rightarrow$ Ops quote bridge is stable, expand **N78-Ops** (not a standalone app):
- Receipt photo capture and local archival
- Rapid field expense entry tied to jobs
- Estimated vs. actual margin on active jobs
- Export packages for accounting handoff where appropriate

N78-Ops must remain fully useful without N78-Estimate.

---

## 22. Success Criteria

The Nivo78 family should ultimately provide two levels of value.

### Standalone Value
A user should be able to choose:
- **N78-Estimate** and receive a complete desktop estimating solution.
- **N78-Ops** and receive a useful field operations solution (with job costs growing in V2/V3).

Each application must earn its place independently.

### Ecosystem Value
When multiple applications are used together, the user should experience:
- less duplicate data entry
- fewer administrative steps
- easier movement of information
- better job continuity
- better visibility into actual costs
- better overall workflow

The combined value should be greater than the sum of the individual applications without making any application dependent upon the others.

---

## 23. Architectural Decision Principles

When future decisions are required, use the following priorities:
1. **Protect user data.**
2. **Protect reliability.**
3. **Preserve standalone usefulness.**
4. **Preserve clear application boundaries.**
5. **Reduce unnecessary user effort.**
6. **Avoid mandatory cloud dependency.**
7. **Prefer simple interoperability over deep coupling.**
8. **Prefer maintainability over feature quantity.**
9. **Respect the environment in which the application is used.**
10. **Introduce complexity only when the user benefit justifies it.**

---

## 24. Canonical Commercial & Pricing Strategy (SaaS Resistance & Launch Incentives)

Nivo78 rejects the predatory SaaS practice of charging recurring monthly rent on every single tool a contractor uses. The commercial model is asymmetric, transparent, and built on true customer ownership.

### 24.1 Ecosystem Commercial Framework
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    NIVO78 COMMERCIAL ARCHITECTURE & PRICING                 │
├───────────────────┬─────────────────────────┬───────────────────────────────┤
│ Application       │ Commercial Model        │ Standard Price & Launch Promo │
├───────────────────┼─────────────────────────┼───────────────────────────────┤
│ 1. N78-Ops        │ Free Basic Forever      │ Basic: $0                     │
│                   │ Annual Sub (Pro/Premier)│ Pro/Premier: ~$99–$149/year   │
├───────────────────┼─────────────────────────┼───────────────────────────────┤
│ 2. N78-Estimate   │ ONE-TIME PURCHASE       │ Standard List: $24.99–$34.99  │
│                   │ (Perpetual License)     │ First 3 Months (40% Off):     │
│                   │                         │ ➔ $14.99 – $19.99 One-Time    │
└───────────────────┴─────────────────────────┴───────────────────────────────┘
```

### 24.2 The 3-Month 40% Introductory Launch Window
To eliminate initial friction, reward early adopting solo operators, and rapidly seed adoption across trade contractor communities:
* **First 90 Days Post-Launch:** **N78-Estimate** is offered at a **40% launch discount** when purchased as the desktop add-on to N78-Ops.
* **One-Time Buy, Lifetime Ownership:** The Estimate purchase grants a permanent perpetual license (Windows & Mac) with 100% offline longevity and zero recurring fees. Field expense capabilities ship inside N78-Ops tier updates, not a separate product purchase.

### 24.3 Why This Strategy Wins
1. **Zero Recurring Friction for Desktop Estimate:** Operators readily accept paying an annual sub for active high-volume daily scheduling/invoicing (N78-Ops), but prefer to buy the estimating workstation once.
2. **Two-App Clarity:** Estimate + Ops — no third expense SKU to explain or maintain.
3. **100% Local Sovereignty:** No server shutdown risk or license deactivation can lock an operator out of their files or bids.

---

## 25. Document Authority and Precedence

This document is the **canonical family-level authority (Level 1 Authority)** for Nivo78:
- Product strategy
- Product roles
- Product boundaries
- Standalone requirements
- Family architecture
- Interoperability principles
- Governance
- Development priorities
- Long-term direction

It intentionally does **not** attempt to define every implementation detail.

Separate subordinate specifications define:
- Individual application requirements
- Detailed user interfaces
- File formats & data schemas
- Transfer protocols
- Testing requirements
- Platform-specific implementation
- Release procedures
- Security implementation
- Performance targets

Those specifications may become more detailed as development progresses, but they must remain consistent with the principles established here.

$$\begin{gathered}
\textbf{Nivo78 Master Strategy \& Architecture (Level 1 — North Star)} \\
\Big\downarrow \\
\textbf{Nivo78 Family Standards (Level 2 — Mandatory Development Rules)} \\
\Big\downarrow \\
\textbf{Product Specifications} \\
\Big\downarrow \\
\textbf{Interface / Data Contracts} \\
\Big\downarrow \\
\textbf{Engineering Implementation} \\
\Big\downarrow \\
\textbf{Cursor / Automated Enforcement}
\end{gathered}$$

The master document establishes the direction. The subordinate specifications establish the details.

---

## 26. Final Direction

Nivo78 will be developed as a **modular family of independently useful applications**.

The two core trade applications are:
- **N78-Estimate** — Pre-job estimating and quoting (desktop)
- **N78-Ops** — Field operations, customer/job management, billing, and job-cost capture (V2/V3)

Each application must provide meaningful standalone value.

When combined, they should provide a more efficient workflow:
$$\textbf{Estimate (accepted bid)} \longrightarrow \textbf{Operations (run the job and costs)}$$

The integration exists to eliminate unnecessary work—not to create dependency.

Nivo78 therefore follows a fundamental rule:
$$\textbf{Standalone first. Integrated second.}$$

The family should remain:
- local-first
- user-controlled
- modular
- reliable
- maintainable
- practical
- privacy-conscious
- resistant to unnecessary complexity

The objective is not to reproduce every capability offered by large SaaS platforms. The objective is to build focused tools that a solo operator can understand, trust, maintain, and use to get real work done.

$$\textbf{Nivo78 should be a family of tools that work well individually and work exceptionally well together.}$$

---

## 27. Mandatory family product philosophy (Level 1 principles)

The following principles apply to **every** Nivo78 product. Level 2 mandatory rules, claim registry, and verifiers implement them; product specifications define formats and release models.

### 27.1 Professional software without unnecessary friction
- One utility. One job. Done right.
- Useful functionality over feature bloat.
- No unnecessary complexity, advertising, intrusive sales prompts, or artificial limitations designed solely to frustrate users.
- Clear, accessible, responsive interfaces appropriate to the task.
- Customers can evaluate a product without being pressured into an upgrade.

### 27.2 Customer freedom and no lock-in
- Do not deliberately create artificial vendor lock-in.
- Do not require a particular accounting app, cloud provider, or vendor ecosystem when a practical portable interchange path exists.
- Provide appropriate import and export for the product's industry; document formats, limitations, and migration paths.
- Never misrepresent compatibility or claim complete portability when information is lost.

### 27.3 Local-first operation and optional cloud
- Core functionality operates locally and offline wherever technically feasible.
- Cloud is optional, not mandatory, when the product can reasonably provide the capability without it.
- Features that genuinely require an external service disclose that dependency clearly.
- Optional online features must not silently become mandatory for unrelated core workflows.
- Document data transmission, storage, and deletion accurately.

### 27.4 Privacy and freedom from advertising
- No account required for ordinary core use unless a documented unavoidable technical or legal requirement exists.
- No advertising, intrusive upgrade nags, behavioral tracking, or advertising surveillance.
- No unnecessary collection or transmission of personal or customer data; no undisclosed telemetry.
- Security diagnostics and crash reporting are separately evaluated, minimized, documented, and consent-governed — not reclassified as permissible "analytics."

### 27.4a Website trust and truthfulness
- The public website (nivo78.com) must accurately represent products, pricing, trials, privacy, and capabilities.
- Material marketing claims must trace to shipped implementation and recorded verification (`reference/NIVO78_WEBSITE_TRUST_TRUTHFULNESS_STANDARD.txt`, `reference/NIVO78_WEBSITE_CLAIM_VERIFICATION_REGISTER.json`).
- Ambiguous or potentially misleading copy requires owner direction before substantive publication change (**WEB-TRUST-STOP-AND-ASK**).

### 27.5 Honest economics
- No tricks, hidden costs, undisclosed automatic renewals, or ambiguous trial-to-paid transitions.
- Time-limited trials must be **full-function** evaluations of the paid experience (see `reference/NIVO78_FULL_FUNCTION_TRIAL_STANDARD.txt`) — not crippled demos with hidden caps.
- Trials should help customers make informed purchase decisions through meaningful evaluation of the paid product, without artificial restrictions designed mainly to pressure conversion.
- **Approved family trial messaging** (use only when product behavior and disclosures support the claims — `reference/NIVO78_TRIAL_MESSAGING.txt`):
  - Primary tagline: **Try Everything. Decide for Yourself.**
  - Supporting statement: **Full access to paid features during your trial. No artificial usage limits. No obligation to buy.**
  - Supplementary taglines (when space and product fit allow): *Full Functionality. No Trial Restrictions.*; *Test It on Real Work. Then Decide.*; *Take Your Time. Make an Informed Decision.*
- No misleading claims about permanent ownership, lifetime updates, or included support.
- Prices, billing intervals, license duration, update policies, cancellation, and post-cancellation access must be clear.
- Free-forever claims mean the stated functionality remains available indefinitely without mandatory payment.
- Affordability is a family objective; unsubstantiated superlative pricing claims are prohibited.

### 27.6 Security and product quality
- Security is a product requirement, not a marketing add-on.
- Minimize permissions, data exposure, dependencies, and attack surface; protect local data appropriately.
- Validate imported data; provide backup, restore, and recovery appropriate to the product.
- Never claim security certification or guarantees without evidence.

### 27.7 Responsive customer feedback
- Discoverable bug and feature intake with classification, prioritization, and status workflow.
- Honest communication about acceptance, limitations, and decisions — no promise to implement every request or unsustainable response SLAs.
- Family acknowledgement target: see `reference/NIVO78_FEEDBACK_RESPONSE_STANDARD.txt`.

### 27.8 Interoperability as a first-class requirement
- Industry-appropriate import/export strategy per product; open standards and leading formats prioritized by evidence.
- Document conversion limitations; automated compatibility tests and sample files where formats are supported.
- The North Star establishes the principle; product interoperability matrices establish actual formats (see `reference/NIVO78_INTEROPERABILITY_STANDARD.txt`).

### 27.9 Customer data remains usable
- Appropriate export without unnecessary subscription or cloud account dependency.
- Subscription cancellation or license expiry must not hold customer data hostage or silently erase customer-created data.
- Proprietary formats require documented schema or practical portable export; state what cannot be exported and why.

### 27.10 Standardized release taxonomy (family)
- Primary release models **R1–R4** are defined in `reference/NIVO78_RELEASE_TAXONOMY.txt`.
- Public marketing claims must match `reference/NIVO78_PRICING_CLAIM_REGISTRY.json` definitions and evidence rules.
- Product-specific release model selection is a product decision; this document does not assign R1–R4 to individual products.
