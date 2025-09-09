-- Library Management System Performance Test Script
-- Description: Comprehensive performance testing and benchmarking
-- Author: Library Management System Team
-- Version: 1.0.0

-- =============================================
-- PERFORMANCE TEST SETUP
-- =============================================

-- Enable timing for performance measurement
\timing on

-- Create temporary table for test results
CREATE TEMPORARY TABLE IF NOT EXISTS performance_results (
    test_name VARCHAR(100),
    execution_time INTERVAL,
    rows_returned INTEGER,
    test_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TEST 1: SEARCH PERFORMANCE
-- =============================================

-- Test book search by title
INSERT INTO performance_results (test_name, execution_time, rows_returned)
SELECT 
    'Search by Title', 
    clock_timestamp() - start_time,
    (SELECT COUNT(*) FROM search_books('Harry'))
FROM (SELECT clock_timestamp() as start_time) s;

-- Test book search by author
INSERT INTO performance_results (test_name, execution_time, rows_returned)
SELECT 
    'Search by Author', 
    clock_timestamp() - start_time,
    (SELECT COUNT(*) FROM search_books('Tolkien'))
FROM (SELECT clock_timestamp() as start_time) s;

-- Test book search by category
INSERT INTO performance_results (test_name, execution_time, rows_returned)
SELECT 
    'Search by Category', 
    clock_timestamp() - start_time,
    (SELECT COUNT(*) FROM search_books('Fantasy'))
FROM (SELECT clock_timestamp() as start_time) s;

-- =============================================
-- TEST 2: TRANSACTION PERFORMANCE
-- =============================================

-- Test book borrowing transaction
DO $$
DECLARE
    start_time TIMESTAMP;
    loan_id INTEGER;
BEGIN
    start_time := clock_timestamp();
    loan_id := borrow_book(5, 3, 14);
    INSERT INTO performance_results (test_name, execution_time, rows_returned)
    VALUES ('Borrow Book', clock_timestamp() - start_time, 1);
END $$;

-- Test book return transaction
DO $$
DECLARE
    start_time TIMESTAMP;
    fine_amount DECIMAL;
BEGIN
    start_time := clock_timestamp();
    fine_amount := return_book((SELECT loan_id FROM loans WHERE return_date IS NULL LIMIT 1));
    INSERT INTO performance_results (test_name, execution_time, rows_returned)
    VALUES ('Return Book', clock_timestamp() - start_time, 1);
END $$;

-- Test book reservation
DO $$
DECLARE
    start_time TIMESTAMP;
    reservation_id INTEGER;
BEGIN
    start_time := clock_timestamp();
    reservation_id := reserve_book(8, 2);
    INSERT INTO performance_results (test_name, execution_time, rows_returned)
    VALUES ('Reserve Book', clock_timestamp() - start_time, 1);
END $$;

-- =============================================
-- TEST 3: REPORTING PERFORMANCE
-- =============================================

-- Test current loans report
INSERT INTO performance_results (test_name, execution_time, rows_returned)
SELECT 
    'Current Loans Report', 
    clock_timestamp() - start_time,
    (SELECT COUNT(*) FROM current_loans)
FROM (SELECT clock_timestamp() as start_time) s;

-- Test overdue books report
INSERT INTO performance_results (test_name, execution_time, rows_returned)
SELECT 
    'Overdue Books Report', 
    clock_timestamp() - start_time,
    (SELECT COUNT(*) FROM calculate_overdue_books())
FROM (SELECT clock_timestamp() as start_time) s;

-- Test member fines report
INSERT INTO performance_results (test_name, execution_time, rows_returned)
SELECT 
    'Member Fines Report', 
    clock_timestamp() - start_time,
    (SELECT COUNT(*) FROM calculate_member_fines(1))
FROM (SELECT clock_timestamp() as start_time) s;

-- Test circulation report
INSERT INTO performance_results (test_name, execution_time, rows_returned)
SELECT 
    'Circulation Report', 
    clock_timestamp() - start_time,
    (SELECT COUNT(*) FROM generate_circulation_report(CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE))
FROM (SELECT clock_timestamp() as start_time) s;

-- =============================================
-- TEST 4: CONCURRENT ACCESS SIMULATION
-- =============================================

-- Simulate concurrent book searches (5 concurrent sessions)
INSERT INTO performance_results (test_name, execution_time, rows_returned)
SELECT 
    'Concurrent Search (' || i || ')', 
    clock_timestamp() - start_time,
    (SELECT COUNT(*) FROM search_books('Book'))
FROM (SELECT clock_timestamp() as start_time, generate_series(1,5) as i) s;

-- Simulate concurrent borrow operations (3 concurrent sessions)
DO $$
DECLARE
    start_time TIMESTAMP;
    i INTEGER;
BEGIN
    start_time := clock_timestamp();
    FOR i IN 1..3 LOOP
        PERFORM borrow_book(10 + i, 1 + i, 14);
    END LOOP;
    INSERT INTO performance_results (test_name, execution_time, rows_returned)
    VALUES ('Concurrent Borrow', clock_timestamp() - start_time, 3);
END $$;

-- =============================================
-- TEST 5: STRESS TEST WITH LARGE DATASET
-- =============================================

-- Create large dataset for stress testing (if needed)
/*
INSERT INTO books (title, isbn, publication_year, publisher_id, category, shelf_location)
SELECT 
    'Test Book ' || i,
    '978' || (1000000000 + i)::TEXT,
    2000 + (i % 20),
    1 + (i % 4),
    CASE (i % 5) 
        WHEN 0 THEN 'Fiction' 
        WHEN 1 THEN 'Non-Fiction' 
        WHEN 2 THEN 'Science' 
        WHEN 3 THEN 'History' 
        ELSE 'Biography' 
    END,
    'S' || (i % 100)
FROM generate_series(1, 10000) i;
*/

-- Test search performance with large dataset
INSERT INTO performance_results (test_name, execution_time, rows_returned)
SELECT 
    'Large Dataset Search', 
    clock_timestamp() - start_time,
    (SELECT COUNT(*) FROM search_books('Test'))
FROM (SELECT clock_timestamp() as start_time) s;

-- =============================================
-- TEST 6: INDEX EFFECTIVENESS
-- =============================================

-- Test query performance without index (temporarily disable)
/*
DROP INDEX IF EXISTS idx_books_title;
INSERT INTO performance_results (test_name, execution_time, rows_returned)
SELECT 
    'Search Without Index', 
    clock_timestamp() - start_time,
    (SELECT COUNT(*) FROM books WHERE title LIKE '%Test%')
FROM (SELECT clock_timestamp() as start_time) s;
CREATE INDEX idx_books_title ON books(title);
*/

-- Test query performance with index
INSERT INTO performance_results (test_name, execution_time, rows_returned)
SELECT 
    'Search With Index', 
    clock_timestamp() - start_time,
    (SELECT COUNT(*) FROM books WHERE title LIKE '%Harry%')
FROM (SELECT clock_timestamp() as start_time) s;

-- =============================================
-- TEST 7: FUNCTION PERFORMANCE
-- =============================================

-- Test stored function performance
INSERT INTO performance_results (test_name, execution_time, rows_returned)
SELECT 
    'Stored Function Call', 
    clock_timestamp() - start_time,
    (SELECT COUNT(*) FROM search_books('Potter'))
FROM (SELECT clock_timestamp() as start_time) s;

-- Test raw SQL equivalent performance
INSERT INTO performance_results (test_name, execution_time, rows_returned)
SELECT 
    'Raw SQL Equivalent', 
    clock_timestamp() - start_time,
    (SELECT COUNT(*) FROM books WHERE title ILIKE '%Potter%')
FROM (SELECT clock_timestamp() as start_time) s;

-- =============================================
-- PERFORMANCE RESULTS ANALYSIS
-- =============================================

-- Display performance test results
SELECT 
    test_name,
    EXTRACT(MILLISECONDS FROM execution_time) as execution_time_ms,
    rows_returned,
    CASE 
        WHEN rows_returned > 0 
        THEN EXTRACT(MILLISECONDS FROM execution_time) / rows_returned 
        ELSE 0 
    END as ms_per_row,
    test_timestamp
FROM performance_results
ORDER BY execution_time DESC;

-- Performance summary statistics
SELECT 
    'PERFORMANCE SUMMARY' as metric,
    COUNT(*) as total_tests,
    ROUND(AVG(EXTRACT(MILLISECONDS FROM execution_time))::numeric, 2) as avg_time_ms,
    ROUND(MAX(EXTRACT(MILLISECONDS FROM execution_time))::numeric, 2) as max_time_ms,
    ROUND(MIN(EXTRACT(MILLISECONDS FROM execution_time))::numeric, 2) as min_time_ms
FROM performance_results;

-- Identify slow-performing operations
SELECT 
    test_name,
    EXTRACT(MILLISECONDS FROM execution_time) as execution_time_ms,
    CASE 
        WHEN EXTRACT(MILLISECONDS FROM execution_time) > 100 THEN 'CRITICAL'
        WHEN EXTRACT(MILLISECONDS FROM execution_time) > 50 THEN 'WARNING'
        WHEN EXTRACT(MILLISECONDS FROM execution_time) > 20 THEN 'ACCEPTABLE'
        ELSE 'GOOD'
    END as performance_status
FROM performance_results
ORDER BY execution_time DESC;

-- =============================================
-- RECOMMENDATIONS BASED ON TEST RESULTS
-- =============================================

-- Generate performance recommendations
SELECT 
    'PERFORMANCE RECOMMENDATIONS' as recommendation_type,
    UNNEST(ARRAY[
        CASE 
            WHEN (SELECT AVG(EXTRACT(MILLISECONDS FROM execution_time)) FROM performance_results WHERE test_name LIKE '%Search%') > 50 
            THEN 'Consider adding full-text search indexes or using PostgreSQL full-text search'
            ELSE 'Search performance is acceptable'
        END,
        CASE 
            WHEN (SELECT AVG(EXTRACT(MILLISECONDS FROM execution_time)) FROM performance_results WHERE test_name LIKE '%Report%') > 100 
            THEN 'Consider creating materialized views for complex reports'
            ELSE 'Reporting performance is acceptable'
        END,
        CASE 
            WHEN (SELECT AVG(EXTRACT(MILLISECONDS FROM execution_time)) FROM performance_results WHERE test_name LIKE '%Concurrent%') > 200 
            THEN 'Review transaction isolation levels and consider connection pooling'
            ELSE 'Concurrent performance is acceptable'
        END
    ]) as recommendation;

-- =============================================
-- SYSTEM PERFORMANCE METRICS
-- =============================================

-- Additional system performance metrics
SELECT 
    'SYSTEM METRICS' as metric_category,
    pg_size_pretty(pg_database_size('library_db')) as database_size,
    (SELECT COUNT(*) FROM pg_stat_activity WHERE datname = 'library_db') as active_connections,
    (SELECT setting FROM pg_settings WHERE name = 'shared_buffers') as shared_buffers,
    (SELECT setting FROM pg_settings WHERE name = 'work_mem') as work_mem;

-- Cache hit ratio (indicator of index effectiveness)
SELECT 
    'CACHE PERFORMANCE' as metric,
    ROUND(SUM(heap_blks_hit) * 100.0 / NULLIF(SUM(heap_blks_hit) + SUM(heap_blks_read), 0), 2) as heap_hit_ratio,
    ROUND(SUM(idx_blks_hit) * 100.0 / NULLIF(SUM(idx_blks_hit) + SUM(idx_blks_read), 0), 2) as index_hit_ratio
FROM pg_statio_user_tables;

-- =============================================
-- INDEX USAGE STATISTICS
-- =============================================

-- Index usage analysis
SELECT 
    schemaname,
    relname as table_name,
    indexrelname as index_name,
    idx_scan as index_scans,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size,
    CASE 
        WHEN idx_scan = 0 THEN 'UNUSED'
        WHEN idx_scan < 100 THEN 'UNDERUTILIZED'
        ELSE 'ACTIVE'
    END as usage_status
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC;

-- =============================================
-- END OF PERFORMANCE TEST
-- =============================================

-- Disable timing
\timing off

-- Note: Run this script during off-peak hours
-- Recommended: Run before and after performance optimizations
-- Save results for historical comparison