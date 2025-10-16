---
title: FCN Issuer Whitelist Governance
doc_type: governance
status: Draft
version: 1.0.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-16
last_reviewed: 2025-10-16
next_review: 2026-04-16
classification: Internal
tags: [fcn, issuer, whitelist, governance, counterparty-risk, structured-notes]
related:
  - business-rules.md
  - schemas/fcn-v1.1.0-parameters.schema.json
  - ../../sa/design-decisions/adr-003-fcn-version-activation.md
---

# FCN Issuer Whitelist Governance

## 1. Purpose
Defines the governance process for managing the approved issuer whitelist for Fixed Coupon Note (FCN) structured products. Ensures counterparty risk management, regulatory compliance, and operational control by restricting note issuance to pre-approved financial institutions.

## 2. Scope
- **Product Coverage**: All FCN specification versions v1.1.0+ (issuer parameter introduced in v1.1)
- **Governance Domain**: Issuer approval, review, suspension, and removal processes
- **Risk Framework**: Credit assessment, regulatory standing, operational capability evaluation
- **Compliance**: Regulatory reporting requirements, audit trail maintenance

## 3. Whitelist Management Process

### 3.1 Issuer Approval Workflow
1. **Nomination**: Risk Manager or Product Owner nominates candidate issuer with business justification
2. **Credit Assessment**: Risk team evaluates:
   - Credit rating (minimum investment grade or equivalent)
   - Financial stability indicators
   - Counterparty exposure limits
3. **Regulatory Review**: Compliance Officer verifies:
   - Regulatory licenses and standing
   - Sanctions screening (OFAC, EU, local)
   - KYC/AML documentation completeness
4. **Operational Assessment**: Operations team confirms:
   - Settlement infrastructure compatibility
   - Documentation standards
   - Historical performance and reliability
5. **Approval**: Multi-stakeholder approval (Risk Manager, Compliance Officer, Product Owner) required
6. **Whitelist Addition**: Issuer identifier added to operational whitelist database; effective date recorded

### 3.2 Ongoing Monitoring
- **Quarterly Review**: Risk team reviews credit ratings, exposure concentrations, and regulatory status
- **Event-Driven Review**: Triggered by credit downgrade, regulatory action, or operational incidents
- **Annual Recertification**: Full reassessment of all whitelisted issuers

### 3.3 Suspension & Removal
- **Temporary Suspension**: Immediate suspension if:
  - Credit rating drops below threshold
  - Regulatory sanctions or investigations
  - Operational failures or settlement issues
  - New trade bookings blocked; existing positions grandfathered
- **Permanent Removal**: Following investigation and stakeholder approval
  - Historical data retained for audit purposes
  - Migration plan for existing exposure (if applicable)

## 4. Whitelist Structure

### 4.1 Issuer Identifier Format
- **Standard**: Legal Entity Identifier (LEI) preferred; internal issuer code as fallback
- **Validation**: BR-022 enforces issuer existence check at trade booking
- **Data Source**: Maintained in `issuer_master` table (database) or equivalent reference data system

### 4.2 Issuer Attributes
Each approved issuer record includes:
- Issuer identifier (LEI or internal code)
- Legal entity name
- Jurisdiction of incorporation
- Credit rating (S&P / Moody's / Fitch equivalent)
- Approval date
- Status (Active / Suspended / Removed)
- Exposure limit (notional cap)
- Review frequency (quarterly / semi-annual / annual)
- Responsible Risk Manager contact

### 4.3 Example Whitelist Entry
```yaml
issuer_id: LEI-549300ABCDEF1234567890
legal_name: XYZ Investment Bank AG
jurisdiction: Switzerland
credit_rating: A+ (S&P)
status: Active
approval_date: 2025-09-15
exposure_limit_usd: 50000000
review_frequency: quarterly
risk_manager: risk-manager@yuanta.co.th
```

## 5. Integration with Business Rules

### 5.1 BR-022 Enforcement
**Rule**: `issuer` parameter must exist in approved issuer whitelist  
**Validation Point**: Trade booking / parameter validation (Phase 2 validator)  
**Error Handling**: Reject trade with error code `ERR_FCN_BR_022_ISSUER_NOT_WHITELISTED`  
**Audit Trail**: Log issuer validation attempts for compliance reporting

### 5.2 Schema Linkage
- **Field**: `issuer` (type: string, minLength: 1, maxLength: 64)
- **Schema Reference**: `fcn-v1.1.0-parameters.schema.json`
- **Description**: "Issuer identifier; must exist in approved issuer whitelist for counterparty risk and governance (BR-022)"

## 6. Audit & Reporting

### 6.1 Audit Requirements
- **Approval Decisions**: Document rationale, assessments, and stakeholder approvals
- **Review Outcomes**: Record quarterly/annual review results and any action items
- **Access Log**: Track whitelist modifications (additions, suspensions, removals) with timestamp and user
- **Trade Validation**: Retain logs of issuer validation checks for regulatory review

### 6.2 Management Reporting
- **Monthly**: Issuer exposure report by issuer and product (FCN concentration)
- **Quarterly**: Whitelist status summary (additions, suspensions, rating changes)
- **Annual**: Comprehensive issuer risk assessment with forward-looking adjustments

## 7. Operational Controls

### 7.1 Access & Permissions
- **Whitelist Modification**: Restricted to Risk Manager and Compliance Officer (with dual approval)
- **Read Access**: Available to Product, Operations, and Trading teams
- **Audit Access**: Full history accessible to Internal Audit and Compliance

### 7.2 System Integration
- **Reference Data**: Issuer whitelist synchronized with trade booking system, risk platform, and reporting tools
- **Real-Time Validation**: BR-022 validation enforced at trade capture (pre-settlement)
- **Change Propagation**: Whitelist updates effective immediately; notification sent to stakeholders

### 7.3 Business Continuity
- **Backup**: Whitelist data replicated across production and disaster recovery environments
- **Fallback**: Manual override process (with exception approval) for critical business continuity scenarios

## 8. Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-16 | copilot | Initial issuer whitelist governance framework: approval workflow, monitoring process, BR-022 integration, audit requirements; placeholder for operational implementation (target: v1.1.0 activation) |

## 9. Open Questions
| ID | Question | Owner | Target Resolution |
|----|----------|-------|-------------------|
| OQ-ISSUER-001 | Should exposure limits be enforced at booking time or post-trade monitoring only? | Risk Manager | Q4 2025 |
| OQ-ISSUER-002 | Define minimum credit rating threshold for issuer approval (A- or BBB+ floor?) | Risk Manager + Compliance | Q4 2025 |
| OQ-ISSUER-003 | Should whitelist be product-specific (FCN-only) or centralized across all structured notes? | Product Owner | Q1 2026 |
