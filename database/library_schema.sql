-- Tables
-- 1. members
-- Stores library member information

CREATE TABLE members (
	member_id SERIAL PRIMARY KEY,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	email VARCHAR(100) UNIQUE NOT NULL,
	phone VARCHAR(20),
	address TEXT,
	membership_date DATE DEFAULT CURRENT_DATE,
	status VARCHAR(10) DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive', 'Suspended'))
);

-- 2. authors
-- Stores author information

CREATE TABLE authors (
	author_id SERIAL PRIMARY KEY,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	biography TEXT,
	birth_date DATE,
	death_date DATE
);

-- 3. publishers
-- Stores publisher information

CREATE TABLE publishers (
	publisher_id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	address TEXT,
	phone VARCHAR(20),
	email VARCHAR(100)
);

-- 4. books
-- Stores book information

CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    isbn VARCHAR(20) UNIQUE NOT NULL,
    publication_year INTEGER,
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    category VARCHAR(50),
    shelf_location VARCHAR(20),
    status VARCHAR(15) DEFAULT 'Available' CHECK (status IN ('Available', 'Borrowed', 'Reserved', 'Maintenance'))
);

-- 5. book_authors
-- Junction table for books and authors (many-to-many relationship)

CREATE TABLE book_authors (
	book_id INTEGER REFERENCES books(book_id) ON DELETE CASCADE,
	author_id INTEGER REFERENCES authors(author_id) ON DELETE CASCADE,
	PRIMARY KEY (book_id, author_id)
);

-- 6. loans
-- Tracks book borrowing transactions

CREATE TABLE loans (
	loan_id SERIAL PRIMARY KEY,
	book_id INTEGER REFERENCES books(book_id),
	member_id INTEGER REFERENCES members(member_id),
	loan_date DATE NOT NULL,
	due_date DATE NOT NULL,
	return_date DATE,
	fine_amount DECIMAL(10,2) DEFAULT 0.00
);

-- 7. reservations
-- Tracks book reservations

CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    book_id INTEGER REFERENCES books(book_id),
    member_id INTEGER REFERENCES members(member_id),
    reservation_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(15) DEFAULT 'Active' CHECK (status IN ('Active', 'Fulfilled', 'Cancelled')),
    notification_date DATE
);

-- 8. fines
-- Tracks fine payments

CREATE TABLE fines (
	fine_id SERIAL PRIMARY KEY,
	loan_id INTEGER REFERENCES loans(loan_id),
	member_id INTEGER REFERENCES members(member_id),
	fine_date DATE DEFAULT CURRENT_DATE,
	amount DECIMAL(10,2) NOT NULL,
	paid_date DATE,
	status VARCHAR(10) DEFAULT 'Unpaid' CHECK (status IN ('Unpaid', 'Paid'))
);
























