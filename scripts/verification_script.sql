-- Function verification script
DO $$
BEGIN
    RAISE NOTICE 'Testing calculate_overdue_books...';
    PERFORM * FROM calculate_overdue_books();
    RAISE NOTICE '✓ calculate_overdue_books works';
    
    RAISE NOTICE 'Testing calculate_member_fines...';
    PERFORM * FROM calculate_member_fines(1);
    RAISE NOTICE '✓ calculate_member_fines works';
    
    RAISE NOTICE 'Testing popular_books_report...';
    PERFORM * FROM popular_books_report(3);
    RAISE NOTICE '✓ popular_books_report works';
    
    RAISE NOTICE 'All functions working correctly!';
END $$;
