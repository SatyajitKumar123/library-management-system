-- Test member registration
SELECT register_member('Alice', 'Johnson', 'alice@email.com', '555-1111', '123 Test St');

-- Test book reservation
SELECT reserve_book(5, 3);  -- Book ID 5, Member ID 3

-- Test circulation report
SELECT * FROM generate_circulation_report('2024-01-01', '2024-03-31');

-- Test popular books report
SELECT * FROM popular_books_report(5);

-- Test overdue books calculation
SELECT * FROM calculate_overdue_books();

-- Test member fines calculation
SELECT * FROM calculate_member_fines(1);