-- Create Indexes for Performance

CREATE INDEX idx_books_title ON books(title);

CREATE INDEX idx_books_isbn ON books(isbn);

CREATE INDEX idx_members_email ON members(email);

CREATE INDEX idx_loans_dates ON loans(loan_date, due_date, return_date);

CREATE INDEX idx_loans_member ON loans(member_id);

CREATE INDEX idx_loans_book ON loans(book_id);