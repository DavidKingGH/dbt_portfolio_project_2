# VIX Volatility Regime Classification Pipeline

A production-grade dbt project that classifies stock market volatility regimes using the CBOE Volatility Index (VIX) and analyzes stock performance across different market conditions.

[![dbt](https://img.shields.io/badge/dbt-1.10.13-orange.svg)](https://www.getdbt.com/)
[![DuckDB](https://img.shields.io/badge/DuckDB-MotherDuck-blue.svg)](https://motherduck.com/)
[![Tests](https://img.shields.io/badge/tests-111%20passing-brightgreen.svg)](tests/TESTING_RESULTS.md)
![CI](https://github.com/DavidKingGH/dbt_portfolio_project_2/actions/workflows/ci.yml/badge.svg)
![CD](https://github.com/DavidKingGH/dbt_portfolio_project_2/actions/workflows/cd.yml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

---

## 📊 Project Overview

This project implements a multi-layered data pipeline that:

1. **Classifies market volatility** into four distinct regimes based on VIX levels
2. **Tracks regime periods** over time using temporal joins and window functions
3. **Enriches stock price data** with volatility classifications
4. **Calculates RSI technical indicators** using both SMA and Wilder smoothing methods
5. **Maintains historical versions** of data using SCD-2 snapshots

### Business Value

- **Risk Assessment**: Identify market stress periods for portfolio adjustments
- **Performance Analysis**: Understand how stocks behave during different volatility regimes
- **Technical Analysis**: Generate trading signals using RSI indicators calibrated to market conditions
- **Historical Tracking**: Maintain complete audit trail of regime classifications and price changes

---

## 🏗️ Architecture

### Data Flow
```
Raw Sources (Yahoo Finance, FRED)
         ↓
    Bronze Layer (src_*)
         ↓
    Silver Layer (stg_*, int_*)
         ↓
     Gold Layer (fct_*, mrt_*)
         ↓
    Snapshots (SCD-2)
```

### Pipeline Components

**VIX Regime Classification:**
```
src_vix → stg__vix_with_versions → int__regime_classification → int__regime_changes → mrt__stocks_with_regimes
```

**RSI Calculation:**
```
src_stocks → stg__stocks → int__price_changes → int__rsi_sma → fct__rsi
                                              → int__rsi_wilder ↗
```

---

## 🎯 Key Features

### ✅ Advanced SQL Patterns

- **Temporal Joins**: Version-aware threshold selection using effective dates
- **Window Functions**: Running sum grouping for regime period detection
- **Recursive CTEs**: Wilder smoothing implementation for RSI calculation
- **Incremental Models**: Efficient daily updates with merge strategy

### ✅ Data Quality

- **111 Automated Tests**: Comprehensive validation across all layers
- **Contract Enforcement**: Type-safe schemas with explicit constraints
- **Business Logic Validation**: OHLC consistency, RSI bounds, threshold ordering
- **Referential Integrity**: Cross-model relationship testing

### ✅ Production Features

- **SCD-2 Snapshots**: Historical tracking of regime classifications and stock prices
- **Versioned Configuration**: Reproducible regime definitions via seed files
- **Incremental Processing**: 15% performance improvement over full refresh
- **Comprehensive Documentation**: Model descriptions, column definitions, grain specifications

---

## 📁 Project Structure
```
portfolio_project_2/
├── assets/                  
│   └── data_ingestion.ipynb # Python scripts for fetching Yahoo/FRED data
├── models/
│   ├── bronze/              # Source models (raw data views)
│   │   ├── src_stocks.sql
│   │   └── src_vix.sql
│   ├── silver/
│   │   ├── stg/             # Staging models (cleaned, typed)
│   │   │   ├── stg__stocks.sql
│   │   │   └── stg__vix_with_versions.sql
│   │   └── int/             # Intermediate models (business logic)
│   │       ├── int__regime_classification.sql
│   │       ├── int__regime_changes.sql
│   │       ├── int__price_changes.sql
│   │       ├── int__rsi_sma.sql
│   │       └── int__rsi_wilder.sql
│   └── gold/                # Mart models (analytics-ready)
│       ├── fct__rsi.sql
│       └── mrt__stocks_with_regimes.sql
├── seeds/
│   └── regime_thresholds.csv    # Versioned VIX thresholds
├── snapshots/
│   └── snapshots.yml            # SCD-2 configurations
├── tests/
│   ├── assert_regime_threshold_ordering.sql
│   ├── wilder_seed_equals_sma.sql
│   └── TESTING_RESULTS.md       # Detailed test documentation
├── macros/
│   └── ingest_raw.sql           # Data loading utilities
└── README.md
```

---

## 📈 Data Models

### Regime Classification Models

#### `int__regime_classification`
Assigns volatility regime to each VIX trading day using versioned thresholds.

**Grain:** One row per trading date

**Regime Definitions:**
| Regime     | VIX Range | Market Condition      |
|------------|-----------|-----------------------|
| Complacent | < 12      | Very low volatility   |
| Normal     | 12-20     | Typical conditions    |
| Elevated   | 20-30     | Increased uncertainty |
| Crisis     | 30+       | Extreme volatility    |

#### `int__regime_changes`
Tracks consecutive trading day periods where VIX maintained the same regime.

**Grain:** One row per regime period

**Key Columns:**
- `regime_period_id`: Sequential period identifier
- `start_date` / `end_date`: Period boundaries
- `days_in_regime`: Duration of regime period

### Stock Analysis Models

#### `mrt__stocks_with_regimes`
Fact table enriching daily stock prices with VIX regime classifications.

**Grain:** One row per ticker per trading date

**Materialization:** Incremental (merge strategy)

**Key Features:**
- OHLC price data
- Volume metrics
- VIX regime classification
- Regime period identifier

#### `fct__rsi`
Relative Strength Index calculations using both SMA and Wilder smoothing methods.

**Grain:** One row per ticker per trading date

**Indicators:**
- `sma_rsi`: 14-day RSI using Simple Moving Average
- `wilder_rsi`: 14-day RSI using Wilder's exponential smoothing
- `sma_rs` / `wilder_rs`: Relative strength ratios

---

## 🧪 Testing

### Test Coverage Summary

| Category            | Count   | Purpose                                              |
|---------------------|---------|------------------------------------------------------|
| **Data Quality**    | 60      | not_null, unique, relationships                      |
| **Business Logic**  | 51      | OHLC consistency, RSI validation, threshold ordering |
| **Constraints**     | 9       | Contract enforcement on mart models                  |
| **Snapshots**       | 2       | SCD-2 temporal tracking                              |
| **Total**           | **122** | Comprehensive validation across all layers           |

### Key Validation Areas

- **Financial Data Integrity**: OHLC consistency, positive prices, volume validation
- **RSI Calculation Accuracy**: Gain/loss logic, precision checks (1e-9 tolerance), Wilder initialization
- **Regime Classification**: Threshold ordering, accepted values, temporal versioning
- **Referential Integrity**: Cross-model relationships, date consistency
- **Temporal Accuracy**: Date bounds, timestamp validation, period tracking

**See [Testing Documentation](tests/TESTING_RESULTS.md) for detailed test scenarios and results.**

---

## 🚀 Getting Started

### Prerequisites

- **dbt Core** 1.10.13 or higher
- **DuckDB** with MotherDuck connection
- **Python** 3.8+ (for data ingestion scripts)
    - Required libraries: `yfinance`, `pandas` (see `assets/data_ingestion.ipynb`)


### Installation
```bash
# Clone the repository
git clone <repository-url>
cd portfolio_project_2

# Install dbt dependencies
dbt deps

# Configure profiles.yml with your MotherDuck credentials
# See: https://docs.getdbt.com/docs/core/connect-data-platform/motherduck-setup
```

### 🐍 Data Ingestion

While dbt handles the transformation layer, the data extraction is performed using Python. I have included a Jupyter Notebook that demonstrates how raw financial data is fetched, cleaned, and prepared for the `bronze` layer.

**File Location:** [`assets/data_ingestion.ipynb`](assets/data_ingestion.ipynb)

**Workflow:**
1.  **Extract:** Fetches daily OHLC data using the `yfinance` library and VIX data from CSV/FRED.
2.  **Format:** Stacks and renames columns to match the target schema for DuckDB/MotherDuck.
3.  **Load:** Exports standardized CSVs to the raw data directory for `dbt seed` or direct ingestion.

### Running the Project
```bash
# Load seed data
dbt seed

# Run all models
dbt run

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

### Incremental Refresh
```bash
# Daily incremental update
dbt run --select mrt__stocks_with_regimes fct__rsi

# Run snapshots to capture SCD-2 history
dbt snapshot
```
## 🔄 CI/CD Automation
This project uses **GitHub Actions** for continuous integration and deployment of dbt models.

### 🧪 CI Workflow — `ci.yml`
Triggered on pushes to `dev` or any `feature/**` branch.  
Validates code changes by:
- Spinning up a temporary **DuckDB/MotherDuck dev environment**  
- Running `dbt build --defer --state prod_state --select "state:modified+"`  
  (only builds modified models vs production state)
- Downloads production `manifest.json` from latest successful CD run for state comparison
- Cost Optimization: Utilizing state:modified+ and --defer ensures only changed models and their downstream dependencies are processed, significantly reducing compute costs and build time compared to full refreshes.
- Ensures no regressions or test failures before merge.
### 🚀 CD Workflow — `cd.yml`
Triggered on merge/push to `main`.  
Performs a full **production build and artifact upload**:
- Installs dependencies and configures MotherDuck prod profile  
- Runs `dbt build --target prod` to rebuild analytics marts  
- Uploads `manifest.json` and `run_results.json` as build artifacts (`prod-state`) for CI reuse

Together, these workflows enforce **deployment hygiene**, **schema consistency**, and **safe promotion** from `dev` → `prod`.

---

## 📊 Sample Queries

### Analyze Stock Performance by Regime
```sql
SELECT 
    regime,
    ticker,
    AVG(close) as avg_price,
    STDDEV(close) as price_volatility,
    COUNT(*) as trading_days
FROM analytics_dev.mrt__stocks_with_regimes
GROUP BY regime, ticker
ORDER BY ticker, regime;
```

### Identify Regime Transitions
```sql
SELECT 
    regime_period_id,
    regime,
    start_date,
    end_date,
    days_in_regime
FROM analytics_dev.int__regime_changes
WHERE regime IN ('elevated', 'crisis')
ORDER BY start_date DESC
LIMIT 10;
```

### RSI Signals During High Volatility
```sql
SELECT 
    s.trade_date,
    s.ticker,
    s.close,
    s.regime,
    r.sma_rsi,
    r.wilder_rsi,
    CASE 
        WHEN r.sma_rsi > 70 THEN 'Overbought'
        WHEN r.sma_rsi < 30 THEN 'Oversold'
        ELSE 'Neutral'
    END as signal
FROM analytics_dev.mrt__stocks_with_regimes s
JOIN analytics_dev.fct__rsi r 
    ON s.trade_date = r.trade_date 
    AND s.ticker = r.ticker
WHERE s.regime IN ('elevated', 'crisis')
ORDER BY s.trade_date DESC;
```

---

## 🔧 Configuration

### Versioned Thresholds

Regime thresholds are managed via seed file for reproducibility:
```csv
version_id,version_name,complacent_max,normal_max,elevated_max,effective_date,notes
1,initial,12,20,30,2024-11-01,Initial thresholds based on historical VIX averages
```

To update thresholds:
1. Add new row to `seeds/regime_thresholds.csv`
2. Run `dbt seed --full-refresh`
3. Run `dbt run --select stg__vix_with_versions+`

Historical data will automatically reclassify using appropriate version based on `effective_date`.

---

## 📝 Data Sources

- **Stock Prices**: Yahoo Finance via yFinance Python package
- **VIX Data**: Federal Reserve Economic Data (FRED) API
- **Time Period**: January 2024 - November 2025
- **Tickers**: AAPL, GOOGL, MSFT, JNJ, NVDA, SPY, TSLA, XLP

---

## 🎓 Learning Outcomes

This project demonstrates proficiency in:

- **dbt Core**: Incremental models, snapshots, seeds, tests, contracts
- **Advanced SQL**: Window functions, CTEs, recursive queries, temporal joins
- **Data Modeling**: Dimensional modeling, SCD-2, fact/dimension tables
- **Data Quality**: Comprehensive testing strategy, business logic validation
- **Production Patterns**: Versioning, incremental processing, performance optimization
- **Technical Writing**: Documentation, testing methodology, runbooks

---

## 📚 Additional Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [Testing Methodology](tests/TESTING_RESULTS.md)
- [VIX Overview](https://www.cboe.com/tradable_products/vix/)
- [RSI Technical Indicator](https://www.investopedia.com/terms/r/rsi.asp)

---

## 📧 Contact

**David** - Analytics Engineer  
[LinkedIn](https://www.linkedin.com/in/david-a-king-/) | [GitHub](https://github.com/DavidKingGH/dbt_portfolio_project_2) | [Email](David-King@live.com)

---

## 📄 License

This project is part of a personal portfolio and is available for review and educational purposes under the MIT License. 

[MIT](LICENSE)

**Note:**
The underlying dataset used in this project is derived from publicly available sources including the Yahoo Finance API and FRED CBOE Volatility (VIXCLS) data.
This repository is for educational and demonstration purposes only and does not distribute or claim ownership over any Yahoo or FRED data.

---

## 🙏 Acknowledgments

- dbt Labs for the incredible dbt framework
- MotherDuck for cloud DuckDB capabilities
- Yahoo Finance and FRED for financial data

---

**Built with ❤️ using dbt, DuckDB, and MotherDuck**