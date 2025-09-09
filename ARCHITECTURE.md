# Posey ETL Pipeline Architecture

## Data Flow Summary

```
CSV Files → Bash Script → PostgreSQL → SQL Analysis → Business Results
```

### 1. Data Sources (Extract)
```
csv_files/
├── sales_reps.csv
├── web_events.csv  
├── orders.csv
├── accounts.csv
└── region.csv
```

### 2. ETL Process (Transform & Load)
```
import_csv.sh
│
├── Extract Phase
│   ├── Read CSV headers
│   ├── Validate file existence
│   └── Check database connection
│
├── Transform Phase  
│   ├── Sanitize table names (filename → table_name)
│   ├── Parse CSV headers → column names
│   └── Generate CREATE TABLE statements (all TEXT)
│
└── Load Phase
    ├── CREATE TABLE IF NOT EXISTS
    ├── \COPY data from CSV files
    └── Verify row counts
```

### 3. Database Layer
```
PostgreSQL Database: posey
│
├── Tables Created:
│   ├── orders (order transactions)
│   ├── accounts (company info)  
│   ├── sales_reps (sales staff)
│   ├── region (geographic data)
│   └── web_events (web interactions)
│
└── Data Types: All columns created as TEXT
```

### 4. Analysis Layer
```
SQL Queries (analysis_queries.sql)
│
├── Query 1: High-volume orders (gloss_qty OR poster_qty > 4000)
├── Query 2: Specialized orders (standard_qty = 0, premium > 1000)
├── Query 3: Contact analysis (company names + contact patterns)
└── Query 4: Territory mapping (region → sales_rep → accounts)
```

### 5. Output Layer
```
Business Intelligence Results
│
├── Order Analysis
│   ├── High-volume order IDs
│   └── Premium-only orders
│
├── Customer Analysis  
│   └── Targeted contact lists
│
└── Sales Analysis
    └── Territory-account mapping
```
