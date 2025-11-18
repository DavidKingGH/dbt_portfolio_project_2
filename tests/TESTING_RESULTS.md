# Testing Documentation

## Overview
This document details the testing performed to validate incremental models, snapshots, and data quality for the VIX Regime Classification pipeline.

**Test Date:** November 13, 2025  
**Environment:** MotherDuck (finance database)  
**dbt Version:** 1.10.13

---

## Test 1: Incremental Model Validation

### Objective
Validate that `mrt__stocks_with_regimes` correctly handles incremental loads without duplicating data.

### Baseline Metrics

**Initial State (After Full Refresh):**
```sql
SELECT 
    COUNT(*) as total_rows,
    MIN(trade_date) as earliest_date,
    MAX(trade_date) as latest_date,
    COUNT(DISTINCT ticker) as unique_tickers
FROM analytics_dev.mrt__stocks_with_regimes;
```

**Results:**
| Metric         | Value      |
|----------------|------------|
| Total Rows     | 12,450     |
| Earliest Date  | 2024-11-04 |
| Latest Date    | 2025-11-04 |
| Unique Tickers | 5          |

### Test Execution

**Step 1: Insert New Data**

Loaded VIX and stock data for dates 2025-11-05 through 2025-11-12 (6 trading days).
```python
# Data loaded via Python script to MotherDuck
# See: scripts/load_to_motherduck.py
```

**Step 2: Run Incremental Update**
```bash
dbt run --select mrt__stocks_with_regimes
```

**Step 3: Validate Results**
```sql
-- Check new data was added
SELECT 
    COUNT(*) as total_rows,
    MAX(trade_date) as latest_date
FROM analytics_dev.mrt__stocks_with_regimes;
```

**Results:**
| Metric      | Before     | After      | Change  |
|-------------|------------|------------|---------|
| Total Rows  | 12,450     | 12,480     | +30     |
| Latest Date | 2025-11-04 | 2025-11-12 | +8 days |

**Validation:**
- ✅ New rows added: 30 (6 trading days × 5 tickers)
- ✅ No duplicates created
- ✅ Incremental strategy working correctly

**Duplicate Check:**
```sql
SELECT trade_date, ticker, COUNT(*) as dupes
FROM analytics_dev.mrt__stocks_with_regimes
GROUP BY trade_date, ticker
HAVING COUNT(*) > 1;
```

**Result:** 0 rows returned ✅

### Key Finding

**Incremental logic performed correctly:**
- Historical duplicates were noted from initial data load (before testing)
- New data (30 rows) loaded without duplication
- Date-based filter (`where trade_date > max(trade_date)`) functioned as expected
- Merge strategy with `unique_key` prevented duplicates for new data

### Conclusion

✅ **PASS** - Incremental model correctly processes new data without duplicates when source data is clean.

**Lesson Learned:** Data quality issues in raw tables propagate through pipeline. Clean source data is essential for reliable incremental models.

---

## Test 2: Snapshot SCD-2 Validation

### Objective
Validate that `regime_classification_snapshot` correctly captures historical changes using SCD-2 pattern.

### Snapshot Configuration
```yaml
strategy: timestamp
updated_at: loaded_at
unique_key: trade_date
```

### Test Execution

**Baseline Snapshot:**
- Initial snapshot run: 2025-11-06 14:07:41
- Total rows captured: 450

**Data Reload:**
- Reloaded VIX data for 2025-11-05 through 2025-11-12
- Snapshot run: 2025-11-13 16:01:07

### Results

**Rows with Multiple Versions:**
```sql
SELECT 
    trade_date,
    COUNT(*) as version_count
FROM analytics_dev_snapshots.regime_classification_snapshot
GROUP BY trade_date
HAVING COUNT(*) > 1;
```

**10 historical dates received updates:**
- 2024-11-15, 2024-12-11, 2024-12-13, 2024-12-20, 2024-12-26
- 2025-01-08, 2025-01-14, 2025-01-27, 2025-01-31, 2025-04-17

**Example SCD-2 History (trade_date = 2024-11-15):**

| close  | regime | loaded_at           | dbt_valid_from      | dbt_valid_to        |
|--------|--------|---------------------|---------------------|---------------------|
| 16.140 | normal | 2025-11-06 14:07:41 | 2025-11-06 14:07:41 | 2025-11-13 16:01:07 |
| 16.140 | normal | 2025-11-13 16:01:07 | 2025-11-13 16:01:07 | NULL                |

**Analysis:**
- ✅ Old version correctly closed (dbt_valid_to set)
- ✅ New version created with current timestamp
- ✅ Business values (close, regime) unchanged
- ⚠️ Only `loaded_at` timestamp changed (metadata update)

**New Data Captured:**
```sql
SELECT COUNT(*) 
FROM analytics_dev_snapshots.regime_classification_snapshot
WHERE trade_date BETWEEN '2025-11-05' AND '2025-11-12'
  AND dbt_valid_to IS NULL;
```

**Result:** 6 rows (6 new trading days) ✅

### Observations

**Timestamp Strategy Behavior:**

The snapshot detected 10 "updates" where only the `loaded_at` timestamp changed, not the actual business data. This demonstrates:

1. ✅ Timestamp strategy is working as configured
2. ✅ Captures ALL changes to the `updated_at` field
3. ⚠️ Creates versions for metadata-only changes

**Production Recommendation:**

Consider using `check` strategy to only track business-critical columns:
```yaml
strategy: check
check_cols: ['close', 'regime']
```

This would reduce spurious versions while maintaining data lineage for actual business changes.

### Conclusion
✅ **PASS** - Snapshot correctly implements SCD-2 temporal tracking. The behavior of capturing metadata changes demonstrates proper configuration of timestamp strategy.

---

## Test 3: Data Quality Validation

### Objective
Validate comprehensive test suite passes after incremental updates.

### Test Execution
```bash
dbt test
```

### Results

**Test Summary:**
- Total Tests: 11
- Passed: 111
- Failed: 0
- Warnings: 0

**Key Test Categories:**

| Category                          | Tests | Status |
|-----------------------------------|-------|----------|
| Not Null Constraints              | 9     | ✅ PASS |
| Generic Tests                     | 60    | ✅ PASS |
| - not_null                        | 51    |          |
| - unique                          | 4     |          |
| - relationships                   | 2     |          |
| - accepted_value                  | 3     |          |
| Generic Tests - dbt_utils         | 47    | ✅ PASS |
| - expression_is_true              | 41    |          | 
| - unique_combination_of_columns   | 6     |          |
| Generic Tests - dbt_expectations  | 2     | ✅ PASS |
| - expect_columns_values_between   | 2     |         |
| Singular Tests                    | 2     | ✅ PASS |

**Critical Business Logic Tests:**
```yaml
# Regime threshold ordering
- dbt_utils.expression_is_true:
    expression: "complacent_max < normal_max AND normal_max < elevated_max"
    
# Price consistency (OHLC)
- dbt_utils.expression_is_true:
    expression: "close BETWEEN low AND high"
    
# RSI bounds
- dbt_expectations.expect_column_values_to_be_between:
    min_value: 0
    max_value: 100
```

All business logic validations passed ✅

### Conclusion
✅ **PASS** - All data quality tests pass after incremental update. Data integrity maintained.

---

## Test 4: Incremental Strategy Performance

### Objective
Compare full refresh vs incremental runtime performance.

### Methodology

**Full Refresh:**
```bash
time dbt run --select mrt__stocks_with_regimes --full-refresh
```

**Incremental:**
```bash
time dbt run --select mrt__stocks_with_regimes
```

### Results

| Strategy     | Runtime | Rows Processed |
|--------------|---------|----------------|
| Full Refresh | 3.87s   | 1,255          |
| Incremental  | 3.26s   | 30             |

**Performance Improvement:** 15% faster ✅

### Conclusion
✅ **PASS** - Incremental strategy provided a performance benefit for daily updates.

---

## Overall Test Summary

| Test              | Status  | Notes                                                 |
|-------------------|---------|-------------------------------------------------------|
| Incremental Model | ✅ PASS | Correctly handles new data, no duplicates             |
| Snapshot SCD-2    | ✅ PASS | Temporal tracking working, metadata sensitivity noted |
| Data Quality      | ✅ PASS | 111/111 tests passing                                 |
| Performance       | ✅ PASS | 15% improvement with incremental                      |

---

## Recommendations

### For Production Deployment

1. **Snapshot Strategy**: Consider switching to `check` strategy to reduce metadata-only versions
2. **Monitoring**: Implement row count monitoring to detect data quality issues
3. **Alerting**: Set up alerts for test failures in production
4. **Documentation**: Maintain this testing documentation as part of deployment runbook

### Future Enhancements

1. Add data freshness checks using dbt source freshness
2. Implement Great Expectations for advanced data quality
3. Add performance monitoring for long-running models
4. Create integration tests for end-to-end pipeline validation

---

## Appendix: SQL Queries Used

### Check for Duplicates
```sql
SELECT trade_date, ticker, COUNT(*) as count
FROM analytics_dev.mrt__stocks_with_regimes
GROUP BY trade_date, ticker
HAVING COUNT(*) > 1;
```

### Verify Incremental Date Range
```sql
SELECT 
    MIN(trade_date) as min_date,
    MAX(trade_date) as max_date,
    COUNT(DISTINCT trade_date) as trading_days
FROM analytics_dev.mrt__stocks_with_regimes
WHERE trade_date > '2025-11-04';
```

### Snapshot Version History
```sql
SELECT 
    trade_date,
    "close",
    regime,
    dbt_valid_from,
    dbt_valid_to,
    CASE 
        WHEN dbt_valid_to IS NULL THEN 'Current'
        ELSE 'Historical'
    END as version_status
FROM analytics_dev_snapshots.regime_classification_snapshot
WHERE trade_date = '2024-11-15'
ORDER BY dbt_valid_from;
```
```
