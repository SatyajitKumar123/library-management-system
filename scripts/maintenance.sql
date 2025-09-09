-- Library Management System Maintenance Script
-- Description: Routine maintenance operations for optimal database performance
-- Author: Library Management System Team

-- =============================================
-- DATABASE HEALTH CHECK
-- =============================================

-- Check database size and growth
SELECT 
    pg_database.datname as database,
    pg_size_pretty(pg_database_size(pg_database.datname)) as size,
    pg_stat_file('base/' || pg_database.oid || '/PG_VERSION').modification as last_modified
FROM pg_database
WHERE datname = 'library_db';

-- Check table sizes and row counts
SELECT 
    schemaname as schema,
    relname as table,
    n_live_tup as row_count,
    pg_size_pretty(pg_total_relation_size(relid)) as total_size,
    pg_size_pretty(pg_relation_size(relid)) as table_size,
    pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) as index_size
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

-- =============================================
-- INDEX MAINTENANCE
-- =============================================

-- Identify unused indexes (may take time to run on large databases)
SELECT 
    schemaname,
    relname as table_name,
    indexrelname as index_name,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size,
    idx_scan as index_scans
FROM pg_stat_user_indexes
WHERE idx_scan = 0
AND pg_relation_size(indexrelid) > 1024 * 1024  -- larger than 1MB
ORDER BY pg_relation_size(indexrelid) DESC;

-- Identify duplicate indexes
SELECT 
    indrelid::regclass as table_name,
    array_agg(indexrelid::regclass) as duplicate_indexes
FROM pg_index
GROUP BY indrelid, indkey
HAVING COUNT(*) > 1;

-- Rebuild indexes with high bloat (example for specific tables)
-- Note: REINDEX is available in PostgreSQL 12+
REINDEX TABLE books;
REINDEX TABLE loans;
REINDEX TABLE members;

-- Alternatively, use CONCURRENTLY to avoid locking (takes longer)
-- REINDEX INDEX CONCURRENTLY idx_books_title;
-- REINDEX INDEX CONCURRENTLY idx_loans_dates;

-- =============================================
-- VACUUM AND ANALYZE
-- =============================================

-- Check tables that need vacuuming
SELECT 
    schemaname,
    relname,
    n_live_tup,
    n_dead_tup,
    round(n_dead_tup::numeric / (n_live_tup + n_dead_tup) * 100, 2) as dead_tup_percentage,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;

-- Perform aggressive vacuum on tables with high dead tuple count
VACUUM FULL VERBOSE ANALYZE books;
VACUUM FULL VERBOSE ANALYZE loans;
VACUUM FULL VERBOSE ANALYZE members;

-- Update statistics for query planner
ANALYZE VERBOSE;

-- =============================================
-- PERFORMANCE OPTIMIZATION
-- =============================================

-- Check query performance statistics
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows,
    shared_blks_hit,
    shared_blks_read
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 20;

-- Identify slow queries
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 100  -- queries slower than 100ms
ORDER BY mean_exec_time DESC
LIMIT 15;

-- =============================================
-- DATA INTEGITY CHECKS
-- =============================================

-- Check for foreign key violations
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT conname, conrelid::regclass as table_name
        FROM pg_constraint 
        WHERE contype = 'f' 
        AND convalidated = false
    LOOP
        RAISE NOTICE 'Foreign key violation found: % in table %', r.conname, r.table_name;
    END LOOP;
END $$;

-- Check for orphaned records in book_authors
SELECT ba.* 
FROM book_authors ba
LEFT JOIN books b ON ba.book_id = b.book_id
LEFT JOIN authors a ON ba.author_id = a.author_id
WHERE b.book_id IS NULL OR a.author_id IS NULL;

-- Check for orphaned records in loans
SELECT l.* 
FROM loans l
LEFT JOIN books b ON l.book_id = b.book_id
LEFT JOIN members m ON l.member_id = m.member_id
WHERE b.book_id IS NULL OR m.member_id IS NULL;

-- =============================================
-- BUSINESS LOGIC VALIDATION
-- =============================================

-- Validate book status consistency
SELECT 
    b.book_id,
    b.title,
    b.status as book_status,
    CASE 
        WHEN l.loan_id IS NOT NULL AND l.return_date IS NULL THEN 'Borrowed'
        WHEN r.reservation_id IS NOT NULL AND r.status = 'Active' THEN 'Reserved'
        ELSE 'Available'
    END as calculated_status
FROM books b
LEFT JOIN loans l ON b.book_id = l.book_id AND l.return_date IS NULL
LEFT JOIN reservations r ON b.book_id = r.book_id AND r.status = 'Active'
WHERE b.status != CASE 
    WHEN l.loan_id IS NOT NULL AND l.return_date IS NULL THEN 'Borrowed'
    WHEN r.reservation_id IS NOT NULL AND r.status = 'Active' THEN 'Reserved'
    ELSE 'Available'
END;

-- Validate fine calculations
SELECT 
    l.loan_id,
    l.book_id,
    l.member_id,
    l.due_date,
    l.return_date,
    l.fine_amount as calculated_fine,
    CASE 
        WHEN l.return_date IS NULL AND l.due_date < CURRENT_DATE 
        THEN (CURRENT_DATE - l.due_date) * 0.50
        WHEN l.return_date > l.due_date
        THEN (l.return_date - l.due_date) * 0.50
        ELSE 0
    END as expected_fine,
    ABS(l.fine_amount - CASE 
        WHEN l.return_date IS NULL AND l.due_date < CURRENT_DATE 
        THEN (CURRENT_DATE - l.due_date) * 0.50
        WHEN l.return_date > l.due_date
        THEN (l.return_date - l.due_date) * 0.50
        ELSE 0
    END) as difference
FROM loans l
WHERE ABS(l.fine_amount - CASE 
    WHEN l.return_date IS NULL AND l.due_date < CURRENT_DATE 
    THEN (CURRENT_DATE - l.due_date) * 0.50
    WHEN l.return_date > l.due_date
    THEN (l.return_date - l.due_date) * 0.50
    ELSE 0
END) > 0.01;

-- =============================================
-- CLEANUP OPERATIONS
-- =============================================

-- Archive old loans (older than 2 years)
CREATE TABLE IF NOT EXISTS loans_archive AS 
SELECT * FROM loans 
WHERE return_date IS NOT NULL 
AND return_date < CURRENT_DATE - INTERVAL '2 years';

-- Delete archived records
DELETE FROM loans 
WHERE return_date IS NOT NULL 
AND return_date < CURRENT_DATE - INTERVAL '2 years';

-- Clean up old reservations (cancelled or fulfilled older than 1 year)
DELETE FROM reservations 
WHERE status IN ('Cancelled', 'Fulfilled')
AND reservation_date < CURRENT_DATE - INTERVAL '1 year';

-- =============================================
-- PERFORMANCE STATISTICS RESET
-- =============================================

-- Reset performance statistics (run during maintenance windows)
-- SELECT pg_stat_statements_reset();
-- SELECT pg_stat_reset();

-- =============================================
-- MAINTENANCE REPORT
-- =============================================

-- Generate maintenance report
SELECT 
    'Database Maintenance Report' as section,
    CURRENT_TIMESTAMP as report_time;

SELECT 
    'Table Statistics' as section,
    COUNT(*) as table_count,
    SUM(n_live_tup) as total_rows,
    SUM(n_dead_tup) as total_dead_rows,
    pg_size_pretty(SUM(pg_total_relation_size(relid))) as total_size
FROM pg_stat_user_tables;

SELECT 
    'Index Statistics' as section,
    COUNT(*) as index_count,
    pg_size_pretty(SUM(pg_relation_size(indexrelid))) as total_index_size,
    SUM(CASE WHEN idx_scan = 0 THEN 1 ELSE 0 END) as unused_indexes
FROM pg_stat_user_indexes;

SELECT 
    'Maintenance Recommendations' as section,
    CASE 
        WHEN SUM(n_dead_tup) > 10000 THEN 'Consider running VACUUM FULL on tables with high dead tuples'
        ELSE 'Vacuum status is normal'
    END as vacuum_recommendation,
    CASE 
        WHEN SUM(CASE WHEN idx_scan = 0 THEN pg_relation_size(indexrelid) ELSE 0 END) > 1024 * 1024 * 100 
        THEN 'Consider removing unused indexes (>100MB total)'
        ELSE 'Index usage is efficient'
    END as index_recommendation
FROM pg_stat_user_tables, pg_stat_user_indexes;

-- =============================================
-- END OF MAINTENANCE SCRIPT
-- =============================================

-- Note: Run this script during maintenance windows
-- Recommended frequency: Weekly for VACUUM ANALYZE, Monthly for full maintenance