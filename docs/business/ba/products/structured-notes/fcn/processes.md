---
title: FCN Core Processes
version: 0.1.0-draft
status: draft
owner: BA
updated: 2025-10-10
tags: [fcn, processes]
---

# Core Business Processes

## 1. Process Inventory
| ID | Process Name | Trigger | Primary Actor | Outcome | Notes |
|----|--------------|--------|---------------|---------|-------|
| PR-01 | Create FCN | Product idea / mandate | Structurer | Draft FCNContract | Validates parameters |
| PR-02 | Validate Parameters | Submission | Validation Engine | Validated parameter set | Errors surfaced |
| PR-03 | Activate Contract | Approval received | Structurer | Active FCNContract | State change |
| PR-04 | Observe Coupon Condition | Scheduled date | Lifecycle Monitor | Observation result | Drives coupon |
| PR-05 | Pay Coupon | Observation result success | Ops | Coupon payment record | |
| PR-06 | Maturity Processing | Maturity date | Lifecycle Monitor | Final settlement | |

## 2. Detailed Steps (Example PR-01 Create FCN)
| Step | Description | Actor | Business Rule Ref | Output |
|------|-------------|-------|-------------------|--------|
| 1 | Enter parameters | Structurer | BR-* | ParameterSet draft |
| 2 | Submit for validation | Structurer | — | Validation request |
| 3 | Receive validation result | Validation Engine | BR-* | Pass / Error list |

## 3. Exception Paths
(Define key exception flows later.)

## 4. Open Process Questions
| ID | Question | Owner | Due | Status |
|----|----------|-------|-----|--------|
| PRQ-01 | Early redemption supported v1? | Product | 2025-10-18 | Open |