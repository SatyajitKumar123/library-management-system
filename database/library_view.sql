-- Available Books View

CREATE VIEW available_books AS
SELECT 
    b.book_id,
    b.title,
    b.isbn,
    string_agg(a.first_name || ' ' || a.last_name, ', ') AS authors,
    b.publication_year,
    p.name AS publisher,
    b.category,
    b.shelf_location
FROM books b
LEFT JOIN book_authors ba ON b.book_id = ba.book_id
LEFT JOIN authors a ON ba.author_id = a.author_id
LEFT JOIN publishers p ON b.publisher_id = p.publisher_id
WHERE b.status = 'Available'
GROUP BY b.book_id, p.name;

-- Current Loans View

CREATE VIEW current_loans AS
SELECT 
    l.loan_id,
    b.title,
    m.first_name || ' ' || m.last_name AS member_name,
    l.loan_date,
    l.due_date,
    l.return_date,
    CASE 
        WHEN l.return_date IS NULL AND l.due_date < CURRENT_DATE 
        THEN (CURRENT_DATE - l.due_date) * 0.50 -- $0.50 per day fine
        ELSE 0 
    END AS current_fine
FROM loans l
JOIN books b ON l.book_id = b.book_id
JOIN members m ON l.member_id = m.member_id
WHERE l.return_date IS NULL;