# Gap Analysis: ERP

> Weighted checklist for enterprise resource planning systems.

## Layer Weights
Functional ██████████ 50% · Security ████████ 35% · Technical ██████ 25%
UX █████ 20% · Ops ██████ 25% · Business ███████ 30%

## Functional
- [ ] Core modules: accounting, inventory, sales, purchasing, HR, payroll?
- [ ] Regulatory compliance: tax codes, fiscal reports, local regulations?
- [ ] Multi-currency? Multi-company? Multi-warehouse?
- [ ] Approval workflows: configurable? audit trail?
- [ ] Reporting: balance sheet, P&L, cash flow, custom reports?
- [ ] Reconciliation: bank? inter-company? period closing?
- [ ] Batch operations: mass updates, scheduled jobs, nightly processing?

## Technical
- [ ] Transactional consistency across modules?
- [ ] Batch processing: scheduled, retry, error handling?
- [ ] Data migration: import from legacy? mapping? validation?
- [ ] Integration: REST APIs? webhooks? ETL? file exchange (EDI, XML)?
- [ ] Extensibility: custom fields? modules? scripts?
- [ ] Reporting engine: configurable dashboards? export (PDF, Excel, CSV)?
- [ ] Audit trail: who changed what when? immutable log?

## Security
- [ ] Segregation of duties: incompatible roles blocked?
- [ ] Access control: by module, company, warehouse, document type?
- [ ] Sensitive data: salaries, pricing, bank accounts encrypted?
- [ ] Audit log: tamper-proof? retention policy?
- [ ] Session: timeout? concurrent session control?
- [ ] Fiscal compliance: data retention by law?

## UX
- [ ] Data entry efficiency: tab order? auto-complete? barcode scan?
- [ ] Bulk operations: select multiple → apply action?
- [ ] Keyboard shortcuts for power users?
- [ ] Reports: filters saved? drill-down? export?
- [ ] Multi-monitor support? (common in ERP desks)

## Ops
- [ ] Maintenance windows: zero-downtime vs scheduled?
- [ ] Backup: full + incremental? point-in-time recovery?
- [ ] Migration: version upgrades? rollback plan?
- [ ] Monitoring: job health? integration failures? data sync errors?
- [ ] On-premise deployment optional? Hybrid?

## Business
- [ ] Implementation methodology? Partner ecosystem?
- [ ] Training materials? Certification program?
- [ ] Support SLAs? Response times?
- [ ] TCO: license + implementation + maintenance + customization?
