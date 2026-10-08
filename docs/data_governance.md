# Retailrocket Data Governance

## Purpose
Provide consistent, traceable data for product analytics.

## Data layers
- RAW: Preserve original source records and ingestion metadata.
- STAGING: Standardize names, types, timestamps, and remove duplicates.
- INTERMEDIATE: Build sessions, orders, and product history.
- ANALYTICS: Publish tested dimensions, facts, and reporting marts.

## Metric definitions
| Metric | Definition |
|---|---|
| Total Events | Number of deduplicated event rows |
| Product Views | Events where event_type = 'view' |
| Product Add-to-Cart Events | Events where event_type = 'addtocart' |
| Product Purchase Events | Events where event_type = 'transaction' |
| Total Orders | Number of rows in the order fact table |
| Total Sessions | Number of rows in the session fact table |
| Purchasing Sessions | Sessions with has_purchase = true |
| Session Purchase Rate | Purchasing Sessions / Total Sessions |
| Active Visitors | Distinct visitor IDs in the selected event data |

## Interpretation rules
- Event counts include repeated actions by a visitor.
- Purchase events and orders are different measures.
- A session may contain interactions with multiple products.
- Product purchase-event counts do not represent confirmed unit quantities.
- Revenue and profit are not reported.
- Historical data is not presented as live activity.
- Category attribution uses the category known at the event time.

## Data quality
- dbt tests validate required fields, accepted values, and relationships.
- Custom tests validate business rules and duplicate handling.
- Raw records remain available for reconciliation.

## Traceability
- Source filenames, source row numbers, and ingestion timestamps
  support investigation of loaded records.
- dbt documentation records model dependencies and lineage.

## Access control
- RETAILROCKET_REPORTER has warehouse, database, and analytics
  schema usage privileges.
- SELECT access covers existing and future analytics tables and views.
- No write privileges were explicitly granted to this role.
- Read access was verified with secondary roles disabled:
  FCT_ORDERS returned 17,672 rows.
- Dedicated ingestion and transformation roles remain planned.


- RAW schema access was denied for RETAILROCKET_REPORTER
  with secondary roles disabled.
- Verification confirmed permitted analytics reads and
  restricted RAW schema access.
