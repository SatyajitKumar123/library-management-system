-- Test overdue books calculation
SELECT * FROM calculate_overdue_books();

-- Test member fines calculation
SELECT * FROM calculate_member_fines(1);

-- Test popular books report
SELECT * FROM popular_books_report(5);

-- Test member details
SELECT * FROM get_member_details(1);

-- Test book details
SELECT * FROM get_book_details(1);

-- Test daily statistics
SELECT * FROM calculate_daily_statistics();

-- Test member registration
SELECT register_member('Test', 'User', 'test@example.com', '555-1234', '123 Test St');

-- Test book reservation (first create a borrowed book)
UPDATE books SET status = 'Borrowed' WHERE book_id = 5;
SELECT reserve_book(5, 2);
