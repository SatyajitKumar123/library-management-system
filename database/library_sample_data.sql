-- Sample Data

-- Insert additional publishers
INSERT INTO publishers (name, address, phone, email) VALUES 
('Simon & Schuster', '1230 Avenue of the Americas, New York, NY', '212-698-7000', 'info@simonandschuster.com'),
('Macmillan Publishers', '120 Broadway, New York, NY', '646-307-5151', 'contact@macmillan.com'),
('Hachette Book Group', '1290 Avenue of the Americas, New York, NY', '212-364-1100', 'info@hachettebookgroup.com'),
('Scholastic Corporation', '557 Broadway, New York, NY', '212-343-6100', 'contact@scholastic.com');

-- Insert additional authors
INSERT INTO authors (first_name, last_name, biography, birth_date, death_date) VALUES 
('Stephen', 'King', 'American author of horror, supernatural fiction, suspense, and fantasy novels.', '1947-09-21', NULL),
('J.R.R.', 'Tolkien', 'English writer, poet, philologist, and academic, best known for The Hobbit and The Lord of the Rings.', '1892-01-03', '1973-09-02'),
('Agatha', 'Christie', 'English writer known for her detective novels.', '1890-09-15', '1976-01-12'),
('Ernest', 'Hemingway', 'American novelist, short-story writer, and journalist.', '1899-07-21', '1961-07-02'),
('F. Scott', 'Fitzgerald', 'American novelist and short story writer.', '1896-09-24', '1940-12-21'),
('Jane', 'Austen', 'English novelist known primarily for her six major novels.', '1775-12-16', '1817-07-18'),
('Charles', 'Dickens', 'English writer and social critic.', '1812-02-07', '1870-06-09'),
('Mark', 'Twain', 'American writer, humorist, entrepreneur, publisher, and lecturer.', '1835-11-30', '1910-04-21'),
('Leo', 'Tolstoy', 'Russian writer who is regarded as one of the greatest authors of all time.', '1828-09-09', '1910-11-20'),
('Virginia', 'Woolf', 'English writer, considered one of the most important modernist 20th-century authors.', '1882-01-25', '1941-03-28'),
('William', 'Shakespeare', 'English playwright, poet, and actor, widely regarded as the greatest writer in the English language.', '1564-04-26', '1616-04-23'),
('Harper', 'Lee', 'American novelist best known for To Kill a Mockingbird.', '1926-04-28', '2016-02-19'),
('George R.R.', 'Martin', 'American novelist and short story writer.', '1948-09-20', NULL),
('Dan', 'Brown', 'American author best known for his thriller novels.', '1964-06-22', NULL),
('John', 'Grisham', 'American novelist, attorney, and politician known for his legal thrillers.', '1955-02-08', NULL);

-- Insert 50 additional books
INSERT INTO books (title, isbn, publication_year, publisher_id, category, shelf_location) VALUES 
('To Kill a Mockingbird', '9780061120084', 1960, 3, 'Fiction', 'C15'),
('The Great Gatsby', '9780743273565', 1925, 2, 'Fiction', 'D22'),
('The Lord of the Rings', '9780544003415', 1954, 4, 'Fantasy', 'E18'),
('Pride and Prejudice', '9780141439518', 1813, 1, 'Romance', 'F07'),
('The Hobbit', '9780547928227', 1937, 4, 'Fantasy', 'E19'),
('The Shining', '9780307743657', 1977, 3, 'Horror', 'G12'),
('Murder on the Orient Express', '9780062693662', 1934, 2, 'Mystery', 'H09'),
('The Old Man and the Sea', '9780684801223', 1952, 1, 'Fiction', 'C16'),
('It', '9781501142970', 1986, 3, 'Horror', 'G13'),
('A Game of Thrones', '9780553593716', 1996, 4, 'Fantasy', 'E20'),
('The Da Vinci Code', '9780307474278', 2003, 2, 'Thriller', 'I11'),
('The Firm', '9780385339609', 1991, 1, 'Thriller', 'I12'),
('Sense and Sensibility', '9780141439662', 1811, 1, 'Romance', 'F08'),
('Oliver Twist', '9780141439747', 1838, 2, 'Classic', 'J14'),
('Adventures of Huckleberry Finn', '9780142437179', 1884, 3, 'Classic', 'J15'),
('Anna Karenina', '9780143035008', 1877, 4, 'Classic', 'J16'),
('Mrs. Dalloway', '9780156628709', 1925, 1, 'Classic', 'J17'),
('Romeo and Juliet', '9780743477116', 1597, 2, 'Drama', 'K05'),
('The Stand', '9780307947306', 1978, 3, 'Horror', 'G14'),
('A Clash of Kings', '9780553381696', 1998, 4, 'Fantasy', 'E21'),
('Angels & Demons', '9781416524793', 2000, 2, 'Thriller', 'I13'),
('The Pelican Brief', '9780385339708', 1992, 1, 'Thriller', 'I14'),
('Emma', '9780141439587', 1815, 1, 'Romance', 'F09'),
('Great Expectations', '9780141439563', 1861, 2, 'Classic', 'J18'),
('The Adventures of Tom Sawyer', '9780143039563', 1876, 3, 'Classic', 'J19'),
('War and Peace', '9780143039990', 1869, 4, 'Classic', 'J20'),
('To the Lighthouse', '9780156907392', 1927, 1, 'Classic', 'J21'),
('Hamlet', '9780743477123', 1603, 2, 'Drama', 'K06'),
('Carrie', '9780307743664', 1974, 3, 'Horror', 'G15'),
('A Storm of Swords', '9780553381702', 2000, 4, 'Fantasy', 'E22'),
('Deception Point', '9781416524809', 2001, 2, 'Thriller', 'I15'),
('The Client', '9780385339081', 1993, 1, 'Thriller', 'I16'),
('Mansfield Park', '9780141439808', 1814, 1, 'Romance', 'F10'),
('A Tale of Two Cities', '9780141439600', 1859, 2, 'Classic', 'J22'),
('Life on the Mississippi', '9780142437322', 1883, 3, 'Classic', 'J23'),
('The Death of Ivan Ilyich', '9780140447920', 1886, 4, 'Classic', 'J24'),
('Orlando', '9780156701600', 1928, 1, 'Classic', 'J25'),
('Macbeth', '9780743477109', 1623, 2, 'Drama', 'K07'),
('Misery', '9780451169525', 1987, 3, 'Horror', 'G16'),
('A Feast for Crows', '9780553582024', 2005, 4, 'Fantasy', 'E23'),
('Digital Fortress', '9780312943316', 1998, 2, 'Thriller', 'I17'),
('The Chamber', '9780385339692', 1994, 1, 'Thriller', 'I18'),
('Northanger Abbey', '9780141439792', 1817, 1, 'Romance', 'F11'),
('David Copperfield', '9780140439441', 1850, 2, 'Classic', 'J26'),
('The Prince and the Pauper', '9780140436693', 1881, 3, 'Classic', 'J27'),
('Resurrection', '9780140448788', 1899, 4, 'Classic', 'J28'),
('The Waves', '9780156949606', 1931, 1, 'Classic', 'J29'),
('Othello', '9780743477550', 1604, 2, 'Drama', 'K08'),
('Pet Sematary', '9780671039736', 1983, 3, 'Horror', 'G17'),
('A Dance with Dragons', '9780553582017', 2011, 4, 'Fantasy', 'E24');

-- Link books to authors
INSERT INTO book_authors (book_id, author_id) VALUES 
(3, 6),   -- To Kill a Mockingbird by Harper Lee
(4, 8),   -- The Great Gatsby by F. Scott Fitzgerald
(5, 4),   -- The Lord of the Rings by J.R.R. Tolkien
(6, 9),   -- Pride and Prejudice by Jane Austen
(7, 4),   -- The Hobbit by J.R.R. Tolkien
(8, 3),   -- The Shining by Stephen King
(9, 5),   -- Murder on the Orient Express by Agatha Christie
(10, 7),  -- The Old Man and the Sea by Ernest Hemingway
(11, 3),  -- It by Stephen King
(12, 15), -- A Game of Thrones by George R.R. Martin
(13, 16), -- The Da Vinci Code by Dan Brown
(14, 17), -- The Firm by John Grisham
(15, 9),  -- Sense and Sensibility by Jane Austen
(16, 10), -- Oliver Twist by Charles Dickens
(17, 11), -- Adventures of Huckleberry Finn by Mark Twain
(18, 12), -- Anna Karenina by Leo Tolstoy
(19, 13), -- Mrs. Dalloway by Virginia Woolf
(20, 14), -- Romeo and Juliet by William Shakespeare
(21, 3),  -- The Stand by Stephen King
(22, 15), -- A Clash of Kings by George R.R. Martin
(23, 16), -- Angels & Demons by Dan Brown
(24, 17), -- The Pelican Brief by John Grisham
(25, 9),  -- Emma by Jane Austen
(26, 10), -- Great Expectations by Charles Dickens
(27, 11), -- The Adventures of Tom Sawyer by Mark Twain
(28, 12), -- War and Peace by Leo Tolstoy
(29, 13), -- To the Lighthouse by Virginia Woolf
(30, 14), -- Hamlet by William Shakespeare
(31, 3),  -- Carrie by Stephen King
(32, 15), -- A Storm of Swords by George R.R. Martin
(33, 16), -- Deception Point by Dan Brown
(34, 17), -- The Client by John Grisham
(35, 9),  -- Mansfield Park by Jane Austen
(36, 10), -- A Tale of Two Cities by Charles Dickens
(37, 11), -- Life on the Mississippi by Mark Twain
(38, 12), -- The Death of Ivan Ilyich by Leo Tolstoy
(39, 13), -- Orlando by Virginia Woolf
(40, 14), -- Macbeth by William Shakespeare
(41, 3),  -- Misery by Stephen King
(42, 15), -- A Feast for Crows by George R.R. Martin
(43, 16), -- Digital Fortress by Dan Brown
(44, 17), -- The Chamber by John Grisham
(45, 9),  -- Northanger Abbey by Jane Austen
(46, 10), -- David Copperfield by Charles Dickens
(47, 11), -- The Prince and the Pauper by Mark Twain
(48, 12), -- Resurrection by Leo Tolstoy
(49, 13), -- The Waves by Virginia Woolf
(50, 14), -- Othello by William Shakespeare
(51, 3),  -- Pet Sematary by Stephen King
(52, 15); -- A Dance with Dragons by George R.R. Martin

-- Insert additional sample members
INSERT INTO members (first_name, last_name, email, phone, address) VALUES 
('Robert', 'Johnson', 'robert.johnson@email.com', '555-9012', '789 Pine St, Anytown'),
('Sarah', 'Williams', 'sarah.williams@email.com', '555-3456', '321 Elm St, Somewhere'),
('Michael', 'Brown', 'michael.brown@email.com', '555-7890', '654 Maple St, Yourtown'),
('Emily', 'Davis', 'emily.davis@email.com', '555-2345', '987 Cedar St, Theircity'),
('David', 'Miller', 'david.miller@email.com', '555-6789', '159 Birch St, Ourville'),
('Jennifer', 'Wilson', 'jennifer.wilson@email.com', '555-0123', '753 Oak St, Yourcity'),
('Christopher', 'Taylor', 'christopher.taylor@email.com', '555-4567', '357 Pine St, Theirtown'),
('Jessica', 'Anderson', 'jessica.anderson@email.com', '555-8901', '951 Elm St, Myville'),
('Matthew', 'Thomas', 'matthew.thomas@email.com', '555-2345', '258 Maple St, Yourville'),
('Amanda', 'Jackson', 'amanda.jackson@email.com', '555-6789', '654 Cedar St, Thistown');

-- Insert additional sample loans
INSERT INTO loans (book_id, member_id, loan_date, due_date, return_date) VALUES 
(3, 3, CURRENT_DATE - INTERVAL '5 days', CURRENT_DATE + INTERVAL '9 days', NULL),
(4, 4, CURRENT_DATE - INTERVAL '10 days', CURRENT_DATE + INTERVAL '4 days', NULL),
(5, 5, CURRENT_DATE - INTERVAL '15 days', CURRENT_DATE - INTERVAL '1 day', NULL),
(6, 6, CURRENT_DATE - INTERVAL '20 days', CURRENT_DATE - INTERVAL '6 days', CURRENT_DATE - INTERVAL '5 days'),
(7, 7, CURRENT_DATE - INTERVAL '3 days', CURRENT_DATE + INTERVAL '11 days', NULL),
(8, 8, CURRENT_DATE - INTERVAL '7 days', CURRENT_DATE + INTERVAL '7 days', NULL),
(9, 9, CURRENT_DATE - INTERVAL '12 days', CURRENT_DATE + INTERVAL '2 days', NULL),
(10, 10, CURRENT_DATE - INTERVAL '18 days', CURRENT_DATE - INTERVAL '4 days', CURRENT_DATE - INTERVAL '2 days'),
(11, 3, CURRENT_DATE - INTERVAL '2 days', CURRENT_DATE + INTERVAL '12 days', NULL),
(12, 4, CURRENT_DATE - INTERVAL '8 days', CURRENT_DATE + INTERVAL '6 days', NULL);