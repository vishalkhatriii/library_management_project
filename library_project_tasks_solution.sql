SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM members;
SELECT * FROM issued_status;
SELECT * FROM return_status;

-- PROJECT TASK

-- Task 1: Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books (isbn, book_title, category, rental_price, status, author, publisher)
VALUES
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

-- Task 2: Update an Existing Member's Address

UPDATE members
SET member_address = '125 Main St'
WHERE member_id = 'C101';

-- Task 3: Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

DELETE FROM issued_status
WHERE issued_id = 'IS121';

-- Task 4: Retrieve All Books Issued by a Specific Employee 
-- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';

-- Task 5: List Members Who Have Issued More Than One Book 
-- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT 
issued_member_id
-- COUNT(issued_id) as total_book_issued
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(issued_id) > 1;

-- Task 6: Create Summary Tables: 
-- Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**

CREATE TABLE book_counts
AS
SELECT
	b.isbn,
	b.book_title,
	COUNT(ist.issued_id) as no_issued
FROM books as b
JOIN issued_status as ist
on b.isbn = ist.issued_book_isbn
GROUP BY 1,2;

SELECT *
FROM book_counts;

-- Task 7. Retrieve All Books in a Specific Category:

SELECT * 
FROM books
WHERE category = 'Classic';

-- Task 8: Find Total Rental Income by Category:
-- JOIN books with issued_status

SELECT
b.category,
SUM(rental_price) as rental_income,
COUNT(*) as no_issued
FROM books as b
JOIN issued_status as ist
on b.isbn = ist.issued_book_isbn
GROUP BY 1;

-- Task 9: List Members Who Registered in the Last 180 Days:
-- We will first insert two new records for the last 180 days

INSERT INTO members (member_id, member_name, member_address, reg_date)
VALUES
('C122', 'woakes', '199, main st', '2025-07-04'),
('C123', 'archer', '123, walnut st', '2025-06-14');

-- Fetching the above records
SELECT *
FROM members 
WHERE reg_date >= CURRENT_DATE - INTERVAL  '180 days';

-- Task :10 List Employees with Their Branch Manager's Name and their branch details:

SELECT 
	e1.*,
	b.manager_id,
	e2.emp_name as manager
FROM employees as e1
JOIN branch as b 
ON b.branch_id = e1.branch_id
JOIN employees as e2
ON e2.emp_id = b.manager_id;

-- Task :11 Create a Table of Books with Rental Price Above a Certain Threshold

CREATE TABLE expensive_books
AS
SELECT *
FROM books
WHERE rental_price > 7;

SELECT * 
FROM expensive_books;

-- Task 12: Retrieve the List of Books Not Yet Returned

SELECT 
	DISTINCT issued_book_name
FROM issued_status as ist
LEFT JOIN return_status as rs
ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL;



/*
ADVANCE TASK OPERATIONS
*/
SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM members;
SELECT * FROM issued_status;
SELECT * FROM return_status;

/*Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). 
Display the member's_id, member's name, book title, issue date, and days overdue.
*/
-- books== member == issued_status == return_status
-- filter books which are beingv returned
-- overdue > 30 days


SELECT 
	ist.issued_member_id,
	m.member_name,
	b.book_title,
	ist.issued_date,
	CURRENT_DATE - ist.issued_date as days_overdue
FROM members as m
JOIN issued_status as ist
ON m.member_id = ist.issued_member_id
JOIN books as b
ON b.isbn = ist.issued_book_isbn
LEFT JOIN return_status as rs
ON rs.issued_id = ist.issued_id
WHERE 
	rs.return_date IS NULL
	AND
	(CURRENT_DATE - ist.issued_date) > 30
ORDER BY 1;


/* 
Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
*/
-- first we will do all the process manually and then use Stored Procedure to automate it

SELECT *
FROM books
WHERE isbn = '978-0-451-52994-2';

UPDATE books
SET status = 'no'
WHERE isbn = '978-0-451-52994-2'; -- issued_id is IS130

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-451-52994-2';

SELECT * FROM return_status
WHERE issued_id = 'IS130';

-- instering into return_status manually and updating status in books manually

INSERT INTO return_status (return_id, issued_id, return_date)
VALUES
('RS120', 'IS130', CURRENT_DATE);
SELECT * FROM return_status
WHERE issued_id = 'IS130';

UPDATE books
SET status = 'yes'
WHERE isbn = '978-0-451-52994-2';

-- Stored Procedure

CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(15))
LANGUAGE plpgsql
AS $$

DECLARE -- all variables are being declared here
	v_isbn VARCHAR(50);
	v_book_name VARCHAR(80);

BEGIN 
	-- all the logic and codes being typed here
	-- inserting into returns based on users inputs

	INSERT INTO return_status(return_id, issued_id, return_date) 
	VALUES
	(p_return_id, p_issued_id, CURRENT_DATE) ;

	SELECT 
		issued_book_isbn,
		issued_book_name
		INTO
		v_isbn,
		v_book_name
	FROM issued_status
	WHERE issued_id = p_issued_id ;

	UPDATE books
	SET status = 'yes'
	WHERE isbn = v_isbn;

	RAISE NOTICE 'Thank you for returning the book: %',v_book_name;

END;
$$

-- Testing Function for add_return_record

issued_id = IS135
isbn = '978-0-307-58837-1'

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_id = 'IS135';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

-- Calling the procedure

CALL add_return_records ('RS138','IS135');

/* For another record
isbn - 978-0-7432-7357-1, issued_id = IS136 
*/

CALL add_return_records ('RS125', 'IS136');

/*
Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, 
showing the number of books issued, the number of books returned, 
and the total revenue generated from book rentals.
*/

WITH branch_performance
AS
(
	SELECT 
		b.branch_id,
		COUNT(ist.issued_id) as books_issued,
		COUNT(rs.return_id) as books_returned,
		SUM(bk.rental_price) as total_rentals
	FROM branch as b
	JOIN employees as e
	ON b.branch_id = e.branch_id
	JOIN issued_status as ist
	ON ist.issued_emp_id = e.emp_id
	LEFT JOIN return_status as rs
	ON rs.issued_id = ist.issued_id
	JOIN books as bk
	ON ist.issued_book_isbn = bk.isbn
	GROUP BY 1
)
SELECT *
FROM branch_performance;

/* Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members 
containing members who have issued at least one book in the last 12 months.
*/

CREATE TABLE active_members
AS
SELECT *
FROM members
WHERE member_id IN (SELECT 
						DISTINCT issued_member_id
					FROM issued_status
					WHERE
					issued_date >= CURRENT_DATE - INTERVAL '12 month'
					)
;

SELECT * 
FROM active_members;

/*
Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. 
Display the employee name, number of books processed, and their branch.
*/

SELECT 
	e.emp_id,
	e.emp_name,
	e.branch_id,
	COUNT(ist.issued_id) as books_issued
FROM employees as e
JOIN issued_status as ist
ON e.emp_id = ist.issued_emp_id 
GROUP BY 1,2
ORDER BY 4 DESC
LIMIT 3;

/* Task 19: Stored Procedure Objective: 
Create a stored procedure to manage the status of books in a library system. 
Description: Write a stored procedure that updates the status of a book in the library based on its issuance.
The procedure should function as follows: 
The stored procedure should take the book_id as an input parameter.
The procedure should first check if the book is available (status = 'yes').
If the book is available, it should be issued, and the status in the books table should be updated to 'no'.
If the book is not available (status = 'no'), 
the procedure should return an error message indicating that the book is currently not available.
*/

CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(15), p_issued_member_id VARCHAR(15), p_issued_book_isbn VARCHAR(50), p_issued_emp_id VARCHAR(15))
LANGUAGE plpgsql
AS $$

DECLARE -- all the variables are being declared here 

	v_status VARCHAR(10);


BEGIN -- all the logic and code

	SELECT status                       -- checking if book is available, status = 'yes'
	INTO
	v_status
	FROM books
	WHERE isbn = p_issued_book_isbn;


	IF v_status ='yes' THEN
		INSERT INTO issued_status (issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
		VALUES
		(p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);

		
		UPDATE books
		SET status = 'no'
		WHERE isbn = p_issued_book_isbn;

		RAISE NOTICE 'Book record added successfully for the book isbn : %', p_issued_book_isbn;
	

	ELSE
		RAISE NOTICE 'Sorry to inform you the book you have requested is unavaialable book_isbn : %',  p_issued_book_isbn;

	END IF
	;

END;
$$

-- Testing Functions
isbn = '978-0-451-52994-2' -- status 'no'
issued_id = 'IS130' -- manually type
issued_member_id 'C106' -- manually type
issued_emp_id = 'E101'

isbn = '978-0-330-25864-8' -- status 'yes'
issued_id = 'IS140' -- manually type
issued_member_id 'C110' -- manually type
issued_emp_id = 'E102'

SELECT * FROM books;

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-330-25864-8';



-- Calling the function, CALL issue_book(p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id)

CALL issue_book ('IS145', 'C110', '978-0-451-52994-2', 'E101'); -- status ='no'

CALL issue_book ('IS144', 'C108', '978-0-330-25864-8', 'E102'); -- status ='yes' and it will change to 'no' as book have been issued






/*Task 20: Create Table As Select (CTAS) Objective: 
Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.
Each day's fine calculated as at $0.50.
*/

CREATE TABLE overdue_books 
AS
SELECT
	ist.issued_id,
	ist.issued_book_isbn,
	b.book_title,
	ist.issued_date,
	CURRENT_DATE as check_date,
	(CURRENT_DATE - ist.issued_date) as days_out,
	GREATEST ((CURRENT_DATE - ist.issued_date) - 30, 0) as overdue_days,
	GREATEST ((CURRENT_DATE - ist.issued_date) - 30, 0) * 0.50 as overdue_amount
FROM issued_status as ist
JOIN books as b
ON b.isbn = ist.issued_book_isbn
WHERE (CURRENT_DATE - ist.issued_date) > 30;



