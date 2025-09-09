-- Stored Procedures & Functions
-- 1. Borrow Book Function

CREATE OR REPLACE FUNCTION borrow_book(
    p_book_id INTEGER,
    p_member_id INTEGER,
    p_loan_duration INTEGER DEFAULT 14
) RETURNS INTEGER AS $$
DECLARE
    v_book_status VARCHAR;
    v_loan_id INTEGER;
BEGIN
    -- Check book availability
    SELECT status INTO v_book_status 
    FROM books 
    WHERE book_id = p_book_id;
    
    IF v_book_status != 'Available' THEN
        RAISE EXCEPTION 'Book is not available for borrowing. Current status: %', v_book_status;
    END IF;
    
    -- Create loan record
    INSERT INTO loans (book_id, member_id, due_date)
    VALUES (p_book_id, p_member_id, CURRENT_DATE + p_loan_duration)
    RETURNING loan_id INTO v_loan_id;
    
    -- Update book status
    UPDATE books SET status = 'Borrowed' WHERE book_id = p_book_id;
    
    RETURN v_loan_id;
END;
$$ LANGUAGE plpgsql;

-- Return Book Function

CREATE OR REPLACE FUNCTION return_book(
    p_loan_id INTEGER
) RETURNS DECIMAL AS $$
DECLARE
    v_due_date DATE;
    v_fine_amount DECIMAL(10,2);
    v_book_id INTEGER;
BEGIN
    -- Get loan details
    SELECT due_date, book_id INTO v_due_date, v_book_id
    FROM loans 
    WHERE loan_id = p_loan_id AND return_date IS NULL;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Loan not found or book already returned';
    END IF;
    
    -- Calculate fine if applicable
    v_fine_amount := 0;
    IF CURRENT_DATE > v_due_date THEN
        v_fine_amount := (CURRENT_DATE - v_due_date) * 0.50; -- $0.50 per day
    END IF;
    
    -- Update loan record
    UPDATE loans 
    SET return_date = CURRENT_DATE, fine_amount = v_fine_amount
    WHERE loan_id = p_loan_id;
    
    -- Update book status
    UPDATE books SET status = 'Available' WHERE book_id = v_book_id;
    
    -- Create fine record if applicable
    IF v_fine_amount > 0 THEN
        INSERT INTO fines (loan_id, member_id, amount)
        SELECT p_loan_id, member_id, v_fine_amount
        FROM loans WHERE loan_id = p_loan_id;
    END IF;
    
    RETURN v_fine_amount;
END;
$$ LANGUAGE plpgsql;


-- Search Books Function

CREATE OR REPLACE FUNCTION search_books(
    search_term VARCHAR
) RETURNS TABLE (
    book_id INTEGER,
    title VARCHAR,
    authors TEXT,
    isbn VARCHAR,
    publication_year INTEGER,
    publisher VARCHAR,
    category VARCHAR,
    status VARCHAR,
    shelf_location VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.book_id,
        b.title,
        string_agg(a.first_name || ' ' || a.last_name, ', ') AS authors,
        b.isbn,
        b.publication_year,
        p.name AS publisher,
        b.category,
        b.status,
        b.shelf_location
    FROM books b
    LEFT JOIN book_authors ba ON b.book_id = ba.book_id
    LEFT JOIN authors a ON ba.author_id = a.author_id
    LEFT JOIN publishers p ON b.publisher_id = p.publisher_id
    WHERE 
        b.title ILIKE '%' || search_term || '%' OR
        a.first_name ILIKE '%' || search_term || '%' OR
        a.last_name ILIKE '%' || search_term || '%' OR
        b.isbn ILIKE '%' || search_term || '%' OR
        p.name ILIKE '%' || search_term || '%' OR
        b.category ILIKE '%' || search_term || '%'
    GROUP BY b.book_id, p.name
    ORDER BY b.title;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- NEW MEMBER MANAGEMENT FUNCTIONS
-- =============================================

-- 1. register_member(): Register new library member
CREATE OR REPLACE FUNCTION register_member(
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_email VARCHAR,
    p_phone VARCHAR DEFAULT NULL,
    p_address TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_member_id INTEGER;
BEGIN
    -- Validate email format
    IF p_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RAISE EXCEPTION 'Invalid email format';
    END IF;

    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM members WHERE email = p_email) THEN
        RAISE EXCEPTION 'Email already registered: %', p_email;
    END IF;

    -- Insert new member
    INSERT INTO members (first_name, last_name, email, phone, address)
    VALUES (p_first_name, p_last_name, p_email, p_phone, p_address)
    RETURNING member_id INTO v_member_id;

    RETURN v_member_id;
END;
$$ LANGUAGE plpgsql;

-- 2. update_member_status(): Update member status
CREATE OR REPLACE FUNCTION update_member_status(
    p_member_id INTEGER,
    p_status VARCHAR
) RETURNS BOOLEAN AS $$
BEGIN
    -- Validate status
    IF p_status NOT IN ('Active', 'Inactive', 'Suspended') THEN
        RAISE EXCEPTION 'Invalid status. Must be Active, Inactive, or Suspended';
    END IF;

    -- Update member status
    UPDATE members 
    SET status = p_status 
    WHERE member_id = p_member_id;

    -- Check if update was successful
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Member with ID % not found', p_member_id;
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- NEW REPORTING FUNCTIONS
-- =============================================

-- 3. generate_circulation_report(): Circulation statistics
CREATE OR REPLACE FUNCTION generate_circulation_report(
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    p_end_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE (
    period VARCHAR,
    books_borrowed BIGINT,
    books_returned BIGINT,
    total_fines DECIMAL,
    avg_loan_duration DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'Custom Period'::VARCHAR as period,
        COUNT(*) FILTER (WHERE l.loan_date BETWEEN p_start_date AND p_end_date)::BIGINT as books_borrowed,
        COUNT(*) FILTER (WHERE l.return_date BETWEEN p_start_date AND p_end_date)::BIGINT as books_returned,
        COALESCE(SUM(f.amount) FILTER (WHERE f.fine_date BETWEEN p_start_date AND p_end_date), 0)::DECIMAL as total_fines,
        ROUND(AVG(
            CASE 
                WHEN l.return_date IS NOT NULL THEN (l.return_date - l.loan_date)::DECIMAL
                ELSE NULL 
            END
        ), 2)::DECIMAL as avg_loan_duration
    FROM loans l
    LEFT JOIN fines f ON l.loan_id = f.loan_id;
END;
$$ LANGUAGE plpgsql;

-- 4. popular_books_report(): Most popular books
CREATE OR REPLACE FUNCTION popular_books_report(
    p_limit INTEGER DEFAULT 10,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    book_id INTEGER,
    title VARCHAR,
    authors TEXT,
    times_borrowed BIGINT,
    avg_loan_duration DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.book_id::INTEGER,
        b.title::VARCHAR,
        STRING_AGG(a.first_name || ' ' || a.last_name, ', ')::TEXT as authors,
        COUNT(l.loan_id)::BIGINT as times_borrowed,
        ROUND(AVG(
            CASE 
                WHEN l.return_date IS NOT NULL AND l.loan_date IS NOT NULL 
                THEN (l.return_date - l.loan_date)::DECIMAL
                ELSE NULL 
            END
        ), 2)::DECIMAL as avg_loan_duration
    FROM books b
    LEFT JOIN loans l ON b.book_id = l.book_id
    LEFT JOIN book_authors ba ON b.book_id = ba.book_id
    LEFT JOIN authors a ON ba.author_id = a.author_id
    WHERE (p_start_date IS NULL OR l.loan_date >= p_start_date)
      AND (p_end_date IS NULL OR l.loan_date <= p_end_date)
    GROUP BY b.book_id, b.title
    ORDER BY times_borrowed DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- NEW ADMINISTRATIVE FUNCTIONS
-- =============================================

-- 5. update_book_inventory(): Add/update books
CREATE OR REPLACE FUNCTION update_book_inventory(
    p_title VARCHAR,
    p_isbn VARCHAR,
    p_publication_year INTEGER,
    p_publisher_id INTEGER,
    p_category VARCHAR,
    p_shelf_location VARCHAR,
    p_author_ids INTEGER[] DEFAULT NULL,
    p_book_id INTEGER DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_book_id INTEGER;
    v_author_id INTEGER;
BEGIN
    -- Validate publisher exists
    IF NOT EXISTS (SELECT 1 FROM publishers WHERE publisher_id = p_publisher_id) THEN
        RAISE EXCEPTION 'Publisher with ID % not found', p_publisher_id;
    END IF;

    -- Update existing book or insert new one
    IF p_book_id IS NOT NULL THEN
        UPDATE books 
        SET title = p_title,
            isbn = p_isbn,
            publication_year = p_publication_year,
            publisher_id = p_publisher_id,
            category = p_category,
            shelf_location = p_shelf_location
        WHERE book_id = p_book_id
        RETURNING book_id INTO v_book_id;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Book with ID % not found', p_book_id;
        END IF;
        
        -- Remove existing author relationships
        DELETE FROM book_authors WHERE book_id = v_book_id;
    ELSE
        -- Check if ISBN already exists
        IF EXISTS (SELECT 1 FROM books WHERE isbn = p_isbn) THEN
            RAISE EXCEPTION 'ISBN already exists: %', p_isbn;
        END IF;

        INSERT INTO books (title, isbn, publication_year, publisher_id, category, shelf_location)
        VALUES (p_title, p_isbn, p_publication_year, p_publisher_id, p_category, p_shelf_location)
        RETURNING book_id INTO v_book_id;
    END IF;

    -- Add author relationships if provided
    IF p_author_ids IS NOT NULL THEN
        FOREACH v_author_id IN ARRAY p_author_ids LOOP
            -- Validate author exists
            IF NOT EXISTS (SELECT 1 FROM authors WHERE author_id = v_author_id) THEN
                RAISE EXCEPTION 'Author with ID % not found', v_author_id;
            END IF;
            
            INSERT INTO book_authors (book_id, author_id) 
            VALUES (v_book_id, v_author_id);
        END LOOP;
    END IF;

    RETURN v_book_id;
END;
$$ LANGUAGE plpgsql;

-- 6. calculate_overdue_books(): Identify overdue books (FIXED)
CREATE OR REPLACE FUNCTION calculate_overdue_books() 
RETURNS TABLE (
    loan_id INTEGER,
    book_title VARCHAR,
    member_name VARCHAR,
    due_date DATE,
    days_overdue INTEGER,
    fine_amount DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.loan_id::INTEGER,
        b.title::VARCHAR as book_title,
        (m.first_name || ' ' || m.last_name)::VARCHAR as member_name,
        l.due_date::DATE,
        (CURRENT_DATE - l.due_date)::INTEGER as days_overdue,
        ((CURRENT_DATE - l.due_date) * 0.50)::DECIMAL as fine_amount
    FROM loans l
    JOIN books b ON l.book_id = b.book_id
    JOIN members m ON l.member_id = m.member_id
    WHERE l.return_date IS NULL 
    AND l.due_date < CURRENT_DATE
    ORDER BY days_overdue DESC;
END;
$$ LANGUAGE plpgsql;

-- 7. calculate_member_fines(): Calculate member fines (FIXED)
CREATE OR REPLACE FUNCTION calculate_member_fines(p_member_id INTEGER) 
RETURNS TABLE (
    total_fines DECIMAL,
    unpaid_fines DECIMAL,
    overdue_books INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(f.amount), 0)::DECIMAL as total_fines,
        COALESCE(SUM(CASE WHEN f.status = 'Unpaid' THEN f.amount ELSE 0 END), 0)::DECIMAL as unpaid_fines,
        COUNT(*) FILTER (WHERE l.return_date IS NULL AND l.due_date < CURRENT_DATE)::INTEGER as overdue_books
    FROM members m
    LEFT JOIN fines f ON m.member_id = f.member_id
    LEFT JOIN loans l ON m.member_id = l.member_id
    WHERE m.member_id = p_member_id
    GROUP BY m.member_id;
END;
$$ LANGUAGE plpgsql;

-- 8. reserve_book(): Reserve a book
CREATE OR REPLACE FUNCTION reserve_book(
    p_book_id INTEGER,
    p_member_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_reservation_id INTEGER;
    v_book_status VARCHAR;
BEGIN
    -- Check if book exists and get current status
    SELECT status INTO v_book_status FROM books WHERE book_id = p_book_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Book with ID % not found', p_book_id;
    END IF;

    -- Check if member exists
    IF NOT EXISTS (SELECT 1 FROM members WHERE member_id = p_member_id AND status = 'Active') THEN
        RAISE EXCEPTION 'Member with ID % not found or not active', p_member_id;
    END IF;

    -- Check if book is available for reservation
    IF v_book_status NOT IN ('Borrowed', 'Reserved') THEN
        RAISE EXCEPTION 'Book is available for borrowing, not reservation';
    END IF;

    -- Check if member already has an active reservation for this book
    IF EXISTS (
        SELECT 1 FROM reservations 
        WHERE book_id = p_book_id AND member_id = p_member_id AND status = 'Active'
    ) THEN
        RAISE EXCEPTION 'Member already has an active reservation for this book';
    END IF;

    -- Create reservation
    INSERT INTO reservations (book_id, member_id, status)
    VALUES (p_book_id, p_member_id, 'Active')
    RETURNING reservation_id INTO v_reservation_id;

    -- Update book status to reserved
    UPDATE books SET status = 'Reserved' WHERE book_id = p_book_id;

    RETURN v_reservation_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- ADDITIONAL UTILITY FUNCTIONS
-- =============================================

-- 9. get_member_details(): Get complete member information
CREATE OR REPLACE FUNCTION get_member_details(p_member_id INTEGER)
RETURNS TABLE (
    member_id INTEGER,
    first_name VARCHAR,
    last_name VARCHAR,
    email VARCHAR,
    phone VARCHAR,
    address TEXT,
    membership_date DATE,
    status VARCHAR,
    current_loans INTEGER,
    total_fines DECIMAL,
    active_reservations INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.member_id::INTEGER,
        m.first_name::VARCHAR,
        m.last_name::VARCHAR,
        m.email::VARCHAR,
        m.phone::VARCHAR,
        m.address::TEXT,
        m.membership_date::DATE,
        m.status::VARCHAR,
        COUNT(l.loan_id) FILTER (WHERE l.return_date IS NULL)::INTEGER as current_loans,
        COALESCE(SUM(f.amount) FILTER (WHERE f.status = 'Unpaid'), 0)::DECIMAL as total_fines,
        COUNT(r.reservation_id) FILTER (WHERE r.status = 'Active')::INTEGER as active_reservations
    FROM members m
    LEFT JOIN loans l ON m.member_id = l.member_id
    LEFT JOIN fines f ON m.member_id = f.member_id
    LEFT JOIN reservations r ON m.member_id = r.member_id
    WHERE m.member_id = p_member_id
    GROUP BY m.member_id;
END;
$$ LANGUAGE plpgsql;

-- 10. get_book_details(): Get complete book information
CREATE OR REPLACE FUNCTION get_book_details(p_book_id INTEGER)
RETURNS TABLE (
    book_id INTEGER,
    title VARCHAR,
    isbn VARCHAR,
    publication_year INTEGER,
    publisher_name VARCHAR,
    category VARCHAR,
    shelf_location VARCHAR,
    status VARCHAR,
    authors TEXT,
    times_borrowed BIGINT,
    current_borrower VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.book_id::INTEGER,
        b.title::VARCHAR,
        b.isbn::VARCHAR,
        b.publication_year::INTEGER,
        p.name::VARCHAR as publisher_name,
        b.category::VARCHAR,
        b.shelf_location::VARCHAR,
        b.status::VARCHAR,
        STRING_AGG(a.first_name || ' ' || a.last_name, ', ')::TEXT as authors,
        COUNT(l.loan_id)::BIGINT as times_borrowed,
        (CASE 
            WHEN b.status = 'Borrowed' THEN 
                (SELECT (m.first_name || ' ' || m.last_name)::VARCHAR
                 FROM loans l 
                 JOIN members m ON l.member_id = m.member_id 
                 WHERE l.book_id = b.book_id AND l.return_date IS NULL
                 LIMIT 1)
            ELSE NULL 
        END)::VARCHAR as current_borrower
    FROM books b
    LEFT JOIN publishers p ON b.publisher_id = p.publisher_id
    LEFT JOIN book_authors ba ON b.book_id = ba.book_id
    LEFT JOIN authors a ON ba.author_id = a.author_id
    LEFT JOIN loans l ON b.book_id = l.book_id
    WHERE b.book_id = p_book_id
    GROUP BY b.book_id, p.name;
END;
$$ LANGUAGE plpgsql;

-- 11. calculate_daily_statistics(): Daily library statistics
CREATE OR REPLACE FUNCTION calculate_daily_statistics()
RETURNS TABLE (
    total_books INTEGER,
    available_books INTEGER,
    borrowed_books INTEGER,
    reserved_books INTEGER,
    active_members INTEGER,
    total_members INTEGER,
    today_loans INTEGER,
    today_returns INTEGER,
    total_overdue_books INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        -- Book statistics
        (SELECT COUNT(*) FROM books)::INTEGER as total_books,
        (SELECT COUNT(*) FROM books WHERE status = 'Available')::INTEGER as available_books,
        (SELECT COUNT(*) FROM books WHERE status = 'Borrowed')::INTEGER as borrowed_books,
        (SELECT COUNT(*) FROM books WHERE status = 'Reserved')::INTEGER as reserved_books,
        
        -- Member statistics
        (SELECT COUNT(*) FROM members WHERE status = 'Active')::INTEGER as active_members,
        (SELECT COUNT(*) FROM members)::INTEGER as total_members,
        
        -- Loan statistics
        (SELECT COUNT(*) FROM loans WHERE loan_date = CURRENT_DATE)::INTEGER as today_loans,
        (SELECT COUNT(*) FROM loans WHERE return_date = CURRENT_DATE)::INTEGER as today_returns,
        (SELECT COUNT(*) FROM loans WHERE return_date IS NULL AND due_date < CURRENT_DATE)::INTEGER as total_overdue_books;
END;
$$ LANGUAGE plpgsql;