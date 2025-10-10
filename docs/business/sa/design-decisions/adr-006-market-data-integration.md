---
title: Market Data Integration Architecture
doc_type: decision-record
adr: 006
status: Proposed
version: 0.1.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2026-04-10
classification: Internal
tags: [architecture, decision, integration, market-data, fcn]
related:
  - ../../../../_policies/document-control-policy.md
  - ../handoff/domain-handoff-fcn-v1.0.md
  - ../../ba/products/structured-notes/fcn/integrations.md
---

# Market Data Integration Architecture

## Status
**Proposed** - Pending architectural decision (OQ-API-005)

## Context
The FCN v1.0 system requires market data (underlying asset prices) to:
1. Record observations on scheduled observation dates
2. Evaluate coupon conditions (BR-002, BR-003)
3. Monitor knock-in barrier breaches (BR-004)
4. Calculate redemption eligibility at maturity (BR-010)

**Open Question (OQ-API-005):**
> "Should market data resource be internal service or external integration?"

This decision affects:
- System architecture and component boundaries
- Data sovereignty and governance
- Latency and reliability characteristics
- Infrastructure costs
- Maintenance responsibilities
- Vendor dependencies

## Decision
**[DECISION PENDING - Analysis in progress]**

Two primary architectural options are being analyzed:
1. **Internal Market Data Service** (cache/proxy layer)
2. **External Integration** (direct consumption)

## Options Analysis

### Option A: Internal Market Data Service

**Approach:**
Build an internal market data service that acts as a cache/proxy layer between FCN system and external market data providers.

**Architecture:**
```
External Market Data Provider(s)
    ↓ (REST API / FIX / WebSocket)
Internal Market Data Service
    - Ingestion layer
    - Cache layer (Redis/PostgreSQL)
    - Transformation layer
    - API Gateway (REST)
    ↓
FCN System
```

**Pros:**
- ✅ **Data sovereignty** - Full control over market data in internal systems
- ✅ **Latency control** - Cache reduces external API calls, faster reads
- ✅ **Transformation flexibility** - Can normalize data from multiple providers
- ✅ **Resilience** - Cache provides fallback if external provider unavailable
- ✅ **Audit trail** - All market data consumption logged internally
- ✅ **Cost optimization** - Reduce external API calls through caching
- ✅ **Quality control** - Validate and filter data before consumption
- ✅ **Multi-provider** - Abstract multiple market data sources behind single API
- ✅ **Historical data** - Can store historical prices for replay/backtesting

**Cons:**
- ⚠️ **Infrastructure cost** - Additional service, cache, and storage required
- ⚠️ **Maintenance overhead** - Must maintain ingestion, transformation, API layers
- ⚠️ **Data freshness responsibility** - Must ensure data is up-to-date
- ⚠️ **Complexity** - More moving parts to monitor and debug
- ⚠️ **Development effort** - Must build and test new service
- ⚠️ **Operational burden** - Monitoring, alerting, scaling, backup
- ⚠️ **Single point of failure** - If service fails, FCN system blocked

**Components Required:**
- **Ingestion Service** - Polls/subscribes to external providers
- **Cache Layer** - Redis or PostgreSQL for recent data
- **Storage Layer** - PostgreSQL for historical data
- **API Service** - REST API for FCN system consumption
- **Monitoring** - Data freshness checks, provider health
- **Alerting** - Stale data alerts, ingestion failures

---

### Option B: External Integration (Direct)

**Approach:**
FCN system directly integrates with external market data provider API when data is needed.

**Architecture:**
```
External Market Data Provider
    ↓ (REST API / FIX / WebSocket)
FCN System (with provider client library)
```

**Pros:**
- ✅ **Simplicity** - Minimal additional components
- ✅ **Lower infrastructure cost** - No cache or proxy service
- ✅ **Data freshness** - Always real-time from provider
- ✅ **Vendor responsibility** - Provider maintains reliability, uptime
- ✅ **Faster to market** - Quicker to implement
- ✅ **Lower maintenance** - No internal service to maintain
- ✅ **Automatic updates** - Provider API improvements benefit system automatically

**Cons:**
- ⚠️ **Latency** - Network round-trip to external provider on every request
- ⚠️ **Reliability dependency** - FCN system blocked if provider unavailable
- ⚠️ **Vendor lock-in** - Tightly coupled to provider API structure
- ⚠️ **Cost unpredictability** - API call costs scale with usage
- ⚠️ **Limited control** - Cannot transform or validate data before use
- ⚠️ **Rate limiting** - Subject to provider rate limits
- ⚠️ **No historical data** - May not support historical queries
- ⚠️ **Multi-provider complexity** - Multiple integrations if using multiple providers

**Mitigations:**
- Implement retry logic with exponential backoff
- Circuit breaker pattern to prevent cascade failures
- Client-side caching for repeated queries (short TTL)
- Fallback to manual data entry if provider unavailable
- Abstract provider API behind interface (easier to switch providers)

---

## Comparison Matrix

| Criterion | Option A (Internal Service) | Option B (External Direct) |
|-----------|----------------------------|----------------------------|
| **Simplicity** | ⭐⭐ Complex | ⭐⭐⭐⭐⭐ Very Simple |
| **Data Sovereignty** | ⭐⭐⭐⭐⭐ Full Control | ⭐⭐ External Dependency |
| **Latency** | ⭐⭐⭐⭐⭐ Fast (cached) | ⭐⭐⭐ Network round-trip |
| **Reliability** | ⭐⭐⭐⭐ Internal SLA | ⭐⭐⭐ Vendor SLA |
| **Infrastructure Cost** | ⭐⭐ High (service + cache) | ⭐⭐⭐⭐⭐ Low (client library only) |
| **Maintenance** | ⭐⭐ High (service, monitoring) | ⭐⭐⭐⭐ Low (just client) |
| **Flexibility** | ⭐⭐⭐⭐⭐ High (transform, validate) | ⭐⭐ Limited (use as-is) |
| **Time to Market** | ⭐⭐ Slow (build service) | ⭐⭐⭐⭐⭐ Fast (integrate) |
| **Historical Data** | ⭐⭐⭐⭐⭐ Can store | ⭐⭐ Provider-dependent |
| **Multi-Provider** | ⭐⭐⭐⭐⭐ Easy to abstract | ⭐⭐ Multiple integrations |
| **Cost Predictability** | ⭐⭐⭐⭐ Fixed infra cost | ⭐⭐⭐ Variable API costs |

---

## Rationale
**[ANALYSIS IN PROGRESS - Decision pending]**

### Key Considerations:

#### 1. Data Freshness Requirements
- **Observation recording:** Daily/weekly discrete observations - NOT real-time required
- **Knock-in monitoring:** Evaluated on observation dates only (discrete)
- **Conclusion:** Real-time data NOT critical; daily EOD (end-of-day) prices sufficient

#### 2. Volume and Scale
- **Initial volume:** Moderate (10-100 contracts initially)
- **Observation frequency:** Daily to monthly per contract
- **API call estimate:** 100-1,000 calls/day
- **Conclusion:** Volume manageable for direct integration

#### 3. Regulatory and Compliance
- **Data residency:** No strict requirements identified (classification: Internal)
- **Audit trail:** Required for observations (BR-007), but can log external API calls
- **Conclusion:** No regulatory blocker for external integration

#### 4. Cost Analysis
- **Provider API cost:** Typical pricing $0.001-$0.01 per call
- **Estimated cost:** $1-$10/day = $30-$300/month
- **Internal service cost:** Developer effort + infrastructure = $500+/month
- **Conclusion:** External integration more cost-effective at current scale

#### 5. Time to Market
- **Internal service:** 4-6 weeks development + 2 weeks testing
- **External integration:** 1-2 weeks integration + 1 week testing
- **Conclusion:** External integration 4-6 weeks faster

#### 6. Organizational Capabilities
- **Team experience:** More experience with API integration than building internal services
- **Operations maturity:** Limited ops team; prefer fewer services to maintain
- **Conclusion:** External integration aligns with current capabilities

---

### Preliminary Recommendation:
**Option B (External Integration)** is recommended for FCN v1.0 based on:
- Sufficient for business requirements (discrete observations, not real-time)
- Significantly faster time to market
- Lower total cost at current scale
- Simpler to implement and maintain
- Team capabilities and experience

**Option A** should be reconsidered in future if:
- Volume increases significantly (10,000+ calls/day)
- Real-time pricing becomes required
- Multi-provider support needed
- Historical backtesting becomes critical
- Regulatory requirements demand data sovereignty

---

## Alternatives Considered

### Option C: Hybrid - Client Cache with External Provider
Use direct external integration with aggressive client-side caching.

**Assessment:**
- Middle ground between A and B
- Addresses latency for repeated queries
- Adds complexity to client (cache invalidation)
- Still dependent on external provider availability
- **Deferred** - Can add caching layer incrementally if needed

### Option D: Third-Party Data Aggregation Service
Use service like Bloomberg, Reuters, or cloud-based aggregator.

**Assessment:**
- Provides normalized data from multiple sources
- Higher cost than direct provider
- Still external dependency
- **Not evaluated** - Depends on vendor selection (outside scope of this ADR)

---

## Consequences

### Positive (Option B - if chosen)
- Fast time to market (1-2 weeks)
- Low infrastructure cost
- Simple architecture
- Easy to understand and maintain
- Vendor maintains reliability

### Negative (Option B - if chosen)
- External dependency for critical data
- Network latency on every observation
- Vendor lock-in (mitigated by interface abstraction)
- Rate limiting concerns (mitigated by current low volume)

### Positive (Option A - if chosen)
- Full data control
- Fast reads (cached)
- Multi-provider support
- Historical data storage

### Negative (Option A - if chosen)
- Longer development time
- Higher infrastructure and maintenance cost
- More operational complexity

---

## Implementation Notes

### For Option B (if chosen):

**API Client Design:**
```python
# Abstract interface for market data provider
class MarketDataProvider(ABC):
    @abstractmethod
    def get_price(self, symbol: str, date: datetime) -> Decimal:
        pass

# Concrete implementation for specific provider
class AlphaVantageProvider(MarketDataProvider):
    def get_price(self, symbol: str, date: datetime) -> Decimal:
        # Call Alpha Vantage API
        pass

# Usage in FCN system
provider = get_configured_provider()  # Factory pattern
price = provider.get_price("AAPL", observation_date)
```

**Error Handling:**
- Implement retry with exponential backoff (3 retries, 1s/2s/4s)
- Circuit breaker after 5 consecutive failures (30 min cooldown)
- Log all API calls for audit trail
- Alert on provider unavailability

**Configuration:**
- Provider selection (Alpha Vantage, Yahoo Finance, etc.) - config file
- API credentials - environment variables or secrets manager
- Timeout settings (default: 10 seconds)
- Retry policy configuration

### For Option A (if chosen):
- Design internal API specification (OpenAPI)
- Define ingestion schedule (e.g., hourly, EOD)
- Choose cache technology (Redis recommended)
- Define cache TTL (e.g., 1 hour for intraday, infinite for EOD)
- Implement monitoring and alerting

---

## Testing Strategy

### Test Cases (for Option B):
1. **Normal operation** - Fetch price successfully
2. **Provider timeout** - Retry and eventual success
3. **Provider error** - Circuit breaker triggers after threshold
4. **Rate limiting** - Respect rate limits, backoff appropriately
5. **Invalid symbol** - Handle 404 errors gracefully
6. **Network failure** - Retry and fallback behavior

### Performance Testing:
- Measure latency (target: <1s per observation)
- Load test with concurrent requests (target: 10 concurrent)
- Simulate provider outage (ensure graceful degradation)

---

## Migration Strategy

### v1.0 → Future (if switching from B to A):
If volume grows and internal service becomes justified:
1. Build internal service alongside existing integration
2. Gradually migrate contracts to use internal service
3. Maintain external integration as fallback
4. Decommission external integration after full migration

---

## Follow-up Tasks
- [ ] Complete analysis and make architectural decision
- [ ] Select market data provider (vendor evaluation if Option B)
- [ ] Design client abstraction layer (interface pattern)
- [ ] Define retry and circuit breaker policies
- [ ] Update integration architecture document
- [ ] Create implementation guide for developers
- [ ] Define monitoring and alerting requirements

---

## Decision Log

| Date | Author | Action |
|------|--------|--------|
| 2025-10-10 | copilot | Created ADR with options analysis (status: Proposed) |
| TBD | SA | Complete cost-benefit analysis |
| TBD | SA | Make architectural decision |
| TBD | SA | Update status to Active after approval |

---

## References
- [Domain Handoff Package](../handoff/domain-handoff-fcn-v1.0.md) - Open Question OQ-API-005
- [API Integration Resources](../../ba/products/structured-notes/fcn/integrations.md)
- [SA Work Tracker](../sa-work-tracker-fcn-v1.0.md) - Phase 2 decision tracking

---

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | 2025-10-10 | copilot | Initial ADR created with options analysis |
