-- Triggers
-- 1. Update Book Status on Reservation

CREATE OR REPLACE FUNCTION update_book_status_on_reservation()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'Active' THEN
        UPDATE books SET status = 'Reserved' WHERE book_id = NEW.book_id;
    ELSIF OLD.status = 'Active' AND NEW.status != 'Active' THEN
        UPDATE books SET status = 'Available' WHERE book_id = NEW.book_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_reservation_status
AFTER INSERT OR UPDATE ON reservations
FOR EACH ROW
EXECUTE FUNCTION update_book_status_on_reservation();

-- 2. Prevent Overdue Members from Borrowing

CREATE OR REPLACE FUNCTION check_member_eligibility()
RETURNS TRIGGER AS $$
DECLARE
    v_overdue_count INTEGER;
    v_max_books INTEGER := 5; -- Maximum books a member can borrow
    v_current_loans INTEGER;
BEGIN
    -- Check for overdue books
    SELECT COUNT(*) INTO v_overdue_count
    FROM loans 
    WHERE member_id = NEW.member_id 
    AND return_date IS NULL 
    AND due_date < CURRENT_DATE;
    
    IF v_overdue_count > 0 THEN
        RAISE EXCEPTION 'Member has overdue books and cannot borrow more';
    END IF;
    
    -- Check maximum books limit
    SELECT COUNT(*) INTO v_current_loans
    FROM loans 
    WHERE member_id = NEW.member_id AND return_date IS NULL;
    
    IF v_current_loans >= v_max_books THEN
        RAISE EXCEPTION 'Member has reached the maximum borrowing limit of % books', v_max_books;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_borrow_eligibility
BEFORE INSERT ON loans
FOR EACH ROW
EXECUTE FUNCTION check_member_eligibility();