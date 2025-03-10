/*
 * Mock Library Database Schema Documentation
 * ========================================
 *
 * This schema represents a comprehensive library management system with the following core entities
 * and functionality:
 *
 * Core Entities:
 * -------------
 * 1. Librarians - Staff members who manage the library system
 * 2. Members - Library patrons/users who can borrow books
 * 3. Books - The main resources available for borrowing
 * 4. Authors - Book writers with many-to-many relationship with books
 * 5. Categories - Book classifications/genres
 *
 * Key Features:
 * ------------
 * - Member Management: Track member details, membership dates, and contact information
 * - Book Inventory: Manage books with title, ISBN, publication year, and available copies
 * - Author Management: Handle multiple authors per book with a junction table
 * - Category System: Organize books by multiple categories
 * - Shopping Cart: Allow members to save books for later in a cart system
 * - Borrowing System: Track book loans with due dates and return status
 * - Audit Trail: Monitor record changes with created_at and updated_at timestamps
 *
 * Database Optimizations:
 * ---------------------
 * - Computed Columns: Full names for librarians, members, and authors
 * - Strategic Indexing: Optimized queries for common operations
 * - Referential Integrity: Proper foreign key constraints with CASCADE deletions
 * - Status Tracking: Enumerated status for borrowings (borrowed, returned, overdue)
 * - Unique Constraints: Prevent duplicate active borrowings
 */
-- Librarians table - Manages library staff information
CREATE TABLE librarians (
    librarian_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(256) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Members table - Stores library patron details
CREATE TABLE members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(20),
    address TEXT,
    password VARCHAR(256) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_members_email ON members(email);

-- Books table - Contains book inventory information
CREATE TABLE books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    publication_year YEAR,
    isbn VARCHAR(20) UNIQUE,
    copies_available INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_books_title ON books(title);

-- Authors table - Stores book author information
CREATE TABLE authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_authors_name ON authors(first_name, last_name);

-- Book Authors junction table - Links books with their authors
CREATE TABLE book_authors (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE CASCADE
);
CREATE INDEX idx_book_authors_book_id ON book_authors(book_id);
CREATE INDEX idx_book_authors_author_id ON book_authors(author_id);

-- Categories table - Defines book genres/classifications
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) UNIQUE NOT NULL
);
CREATE INDEX idx_categories_name ON categories(category_name);

-- Book Categories junction table - Links books with categories
CREATE TABLE book_category (
    book_id INT NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (book_id, category_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
);
CREATE INDEX idx_book_category_book_id ON book_category(book_id);
CREATE INDEX idx_book_category_category_id ON book_category(category_id);

-- Book Cart table - Manages member's saved books
CREATE TABLE book_cart (
    cart_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE
);
CREATE INDEX idx_book_cart_member_id ON book_cart(member_id);
CREATE INDEX idx_book_cart_book_id ON book_cart(book_id);

-- Borrowings table - Tracks book loans and returns
CREATE TABLE borrowings (
    borrowing_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    borrowed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    due_date DATE NOT NULL,
    returned_at TIMESTAMP NULL,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE
);
CREATE INDEX idx_borrowings_member_id ON borrowings(member_id);
CREATE INDEX idx_borrowings_book_id ON borrowings(book_id);
CREATE INDEX idx_borrowings_due_date ON borrowings(due_date);

-- Add full_name computed column to librarians
ALTER TABLE librarians 
ADD COLUMN full_name VARCHAR(201) GENERATED ALWAYS AS 
    (CONCAT(first_name, ' ', last_name)) STORED;

-- Add full_name computed column to members
ALTER TABLE members 
ADD COLUMN full_name VARCHAR(201) GENERATED ALWAYS AS 
    (CONCAT(first_name, ' ', last_name)) STORED;

-- Add full_name computed column to authors
ALTER TABLE authors 
ADD COLUMN full_name VARCHAR(201) GENERATED ALWAYS AS 
    (CONCAT(first_name, ' ', last_name)) STORED;

-- Add status enum to borrowings
ALTER TABLE borrowings 
ADD COLUMN status ENUM('borrowed', 'returned', 'overdue') 
    DEFAULT 'borrowed' NOT NULL;

-- Add librarian tracking to borrowings
ALTER TABLE borrowings 
ADD COLUMN librarian_id INT,
ADD FOREIGN KEY (librarian_id) REFERENCES librarians(librarian_id);

-- Add unique constraint to prevent duplicate borrowings
ALTER TABLE borrowings 
ADD CONSTRAINT unique_active_borrowing 
    UNIQUE(member_id, book_id, returned_at);

-- Add indexes for common queries
CREATE INDEX idx_librarians_full_name ON librarians(full_name);
CREATE INDEX idx_members_full_name ON members(full_name);
CREATE INDEX idx_authors_full_name ON authors(full_name);
CREATE INDEX idx_borrowings_status ON borrowings(status);
CREATE INDEX idx_books_isbn ON books(isbn);

-- Add audit timestamps
ALTER TABLE books ADD COLUMN updated_at TIMESTAMP 
    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE members ADD COLUMN updated_at TIMESTAMP 
    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE borrowings ADD COLUMN updated_at TIMESTAMP 
    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;



-- Initial Queries and Stored Procedures

-- Create audit log table
CREATE TABLE audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    action_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    record_id INT NOT NULL,
    changed_by INT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details JSON,
    FOREIGN KEY (changed_by) REFERENCES librarians(librarian_id)
);


-- PROCEDURES and Triggers
-- Trigger for Books Audit
DELIMITER //
CREATE TRIGGER books_after_insert
AFTER INSERT ON books
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, action_type, record_id, details)
    VALUES ('books', 'INSERT', NEW.book_id, 
        JSON_OBJECT(
            'title', NEW.title,
            'isbn', NEW.isbn,
            'copies', NEW.copies_available
        )
    );
END //


-- Trigger for Authors to automatically set full_name
CREATE TRIGGER authors_before_insert
BEFORE INSERT ON authors
FOR EACH ROW
BEGIN
    SET NEW.full_name = CONCAT(NEW.first_name, ' ', NEW.last_name);
END //


-- ------------------------------------------------------------------------- SIGNUP MEMBER

/*
 * Stored Procedure: signup_member
 * Description: Creates a new library member record with basic information
 * Parameters:
 *   - p_first_name: Member's first name (VARCHAR(100))
 *   - p_last_name: Member's last name (VARCHAR(100)) 
 *   - p_email: Member's email address (VARCHAR(255))
 *   - p_phone_number: Member's contact number (VARCHAR(20))
 *   - p_address: Member's physical address (TEXT)
 * Returns: None
 * Notes: 
 *   - Does not perform email validation or duplicate checking
 */

CREATE PROCEDURE signup_member(
    IN p_first_name VARCHAR(100),
    IN p_last_name VARCHAR(100),
    IN p_email VARCHAR(255),
    IN p_pass VARCHAR(200),
    IN p_phone_number VARCHAR(20),
    IN p_address TEXT
)
BEGIN
    INSERT INTO members (first_name, last_name, email, password, phone_number, address)
    VALUES (p_first_name, p_last_name, p_email, SHA2(p_pass, 256), p_phone_number, p_address);
END //


-- -------------------------------------------------------------------------- CATEGORIES
-- ----------------------------------- ADD SINGLE CATEGORY

/*
 * Stored Procedure: add_category
 * Description: Inserts a single category into the categories table
 * Parameters:
 *   - p_category_name: Name of the category to add (VARCHAR(100))
 * Returns: 
 *   - Newly created category ID and name
 * Example Usage: CALL add_category('Mystery')
 * Notes:
 *   - Simple single category insertion
 *   - Returns the newly created category information
 */


CREATE PROCEDURE add_category(
    IN p_category_name VARCHAR(100)
)
BEGIN
    INSERT INTO categories (category_name)
    VALUES (p_category_name);
    
    -- Return the newly created category
    SELECT category_id, category_name 
    FROM categories 
    WHERE category_id = LAST_INSERT_ID();
END //



-- ----------------------------------- ADD CATEGORIES

/*
 * Stored Procedure: add_categories
 * Description: Bulk inserts multiple categories into the categories table
 * Parameters:
 *   - category_list: JSON array of category names (e.g. ["Fiction", "Science"])
 * Returns: None
 * Example Usage: CALL add_categories('["Fiction", "Non-Fiction", "Science"]')
 * Notes:
 *   - Expects a valid JSON array format
 *   - Does not check for duplicate categories
 *   - Processes categories sequentially using a loop
 */


CREATE PROCEDURE add_categories(
    IN category_list JSON
)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE n INT DEFAULT JSON_LENGTH(category_list);
    DECLARE new_category_id INT;
    DECLARE new_category_name VARCHAR(100);
    
    WHILE i < n DO
        -- Extract the category name from JSON array
        SET new_category_name = JSON_UNQUOTE(JSON_EXTRACT(category_list, CONCAT('$[', i, ']')));
        
        -- Call the add_category procedure for each category
        INSERT INTO categories (category_name) VALUES (new_category_name);
        
        SET i = i + 1;
    END WHILE;
    SET i = 0;
    -- Return all categories after insertion
    SELECT * FROM categories ORDER BY category_id;
END //


-- ----------------------------------- EDIT CATEGORIES
/*
 * Stored Procedure: edit_category
 * Description: Updates an existing category name in the categories table
 * Parameters:
 *   - p_category_id: ID of the category to update (INT)
 *   - p_category_name: New name for the category (VARCHAR(100))
 * Returns: 
 *   - Updated category record if successful
 *   - Error if category does not exist
 * Example Usage: CALL edit_category(1, 'Science Fiction')
 * Notes:
 *   - Validates that category exists before updating
 *   - Returns full category record after update
 *   - Throws error with custom message if category not found
 */


CREATE PROCEDURE edit_category(
    IN p_category_id INT,
    IN p_category_name VARCHAR(100)
)
BEGIN
    -- Check if category exists
    DECLARE category_exists INT;
    SELECT COUNT(*) INTO category_exists 
    FROM categories 
    WHERE category_id = p_category_id;

    IF category_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Category does not exist';
    ELSE
        -- Update category
        UPDATE categories 
        SET category_name = p_category_name
        WHERE category_id = p_category_id;
        
        -- Return updated category
        SELECT * FROM categories WHERE category_id = p_category_id;
    END IF;
END //

-- ----------------------------------- DELETE CATEGORY
/*
 * Stored Procedure: delete_category
 * Description: Deletes a category and removes all its associations in the book_category table
 * Parameters:
 *   - p_category_id: ID of the category to delete (INT)
 * Returns: 
 *   - Success message if category is deleted
 *   - Error if category does not exist
 * Example Usage: CALL delete_category(1)
 * Notes:
 *   - First removes all associations in book_category table
 *   - Then deletes the category from categories table
 *   - Validates that category exists before attempting deletion
 *   - Uses transaction to ensure data integrity
 */


CREATE PROCEDURE delete_category(
    IN p_category_id INT
)
BEGIN
    -- Check if category exists
    DECLARE category_exists INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'An error occurred while deleting the category';
    END;
    
    SELECT COUNT(*) INTO category_exists 
    FROM categories 
    WHERE category_id = p_category_id;

    IF category_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Category does not exist';
    ELSE
        -- Start transaction to ensure data integrity
        START TRANSACTION;
        
        -- First, delete all associations in book_category table
        DELETE FROM book_category 
        WHERE category_id = p_category_id;
        
        -- Then delete the category
        DELETE FROM categories 
        WHERE category_id = p_category_id;
        
        COMMIT;
        
        SELECT CONCAT('Category ID ', p_category_id, ' has been successfully deleted') AS message;
    END IF;
END //


-- ---------------------------------------------------------------------- AUTHORS

/*
 * Stored Procedure: add_author
 * Description: Adds a single author to the authors table
 * Parameters:
 *   - p_first_name: Author's first name (VARCHAR(100))
 *   - p_last_name: Author's last name (VARCHAR(100))
 * Returns: 
 *   - Newly created author_id and success message
 * Example Usage: 
 *   CALL add_author('George', 'Orwell')
 * Notes:
 *   - Does not check for duplicate authors
 *   - Returns the ID of the newly created author
 */

-- Single Author Insertion Procedure
CREATE PROCEDURE add_author(
    IN p_first_name VARCHAR(100),
    IN p_last_name VARCHAR(100)
)
BEGIN
    INSERT INTO authors (first_name, last_name)
    VALUES (p_first_name, p_last_name);
    
    -- Capture the inserted ID properly
    SET @author_id = LAST_INSERT_ID();

    -- Return a success message
    SELECT @author_id AS author_id, 
           CONCAT('Author ', p_first_name, ' ', p_last_name, ' added successfully') AS message;
END //

/*
 * Stored Procedure: edit_author
 * Description: Updates an existing author's information
 * Parameters:
 *   - p_author_id: ID of the author to update (INT)
 *   - p_first_name: New first name (VARCHAR(100))
 *   - p_last_name: New last name (VARCHAR(100))
 * Returns: Success message
 * Example Usage: CALL edit_author(1, 'George R.R.', 'Martin')
 */

CREATE PROCEDURE edit_author(
    IN p_author_id INT,
    IN p_first_name VARCHAR(100),
    IN p_last_name VARCHAR(100)
)
BEGIN
    DECLARE author_exists INT;
    
    -- Check if author exists
    SELECT COUNT(*) INTO author_exists 
    FROM authors 
    WHERE author_id = p_author_id;
    
    IF author_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Author does not exist';
    ELSE
        UPDATE authors
        SET first_name = p_first_name,
            last_name = p_last_name
        WHERE author_id = p_author_id;
        
        SELECT CONCAT('Author ID ', p_author_id, ' has been successfully updated') AS message;
    END IF;
END //

/*
 * Stored Procedure: delete_author
 * Description: Deletes an author and removes all book associations
 * Parameters:
 *   - p_author_id: ID of the author to delete (INT)
 * Returns: Success message
 * Example Usage: CALL delete_author(1)
 * Notes:
 *   - First removes all associations in book_author table
 *   - Then deletes the author from authors table
 *   - Uses transaction to ensure data integrity
 */

CREATE PROCEDURE delete_author(
    IN p_author_id INT
)
BEGIN
    DECLARE author_exists INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'An error occurred while deleting the author';
    END;
    
    -- Check if author exists
    SELECT COUNT(*) INTO author_exists 
    FROM authors 
    WHERE author_id = p_author_id;

    IF author_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Author does not exist';
    ELSE
        -- Start transaction
        START TRANSACTION;
        
        -- First, delete all associations in book_author table
        DELETE FROM book_authors
        WHERE author_id = p_author_id;
        
        -- Then delete the author
        DELETE FROM authors 
        WHERE author_id = p_author_id;
        
        COMMIT;
        
        SELECT CONCAT('Author ID ', p_author_id, ' has been successfully deleted') AS message;
    END IF;
END //


/*
 * Stored Procedure: add_authors
 * Description: Bulk inserts multiple authors into the authors table
 * Parameters:
 *   - author_list: JSON array of author objects containing first_name and last_name
 * Returns: None
 * Example Usage: 
 *   CALL add_authors('[{"first_name": "George", "last_name": "Orwell"}]')
 * Notes:
 *   - Expects a valid JSON array of objects
 *   - Each object must have first_name and last_name properties
 *   - Does not check for duplicate authors
 */


CREATE PROCEDURE add_authors(
    IN author_list JSON
)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE n INT DEFAULT IFNULL(JSON_LENGTH(author_list), 0);
    DECLARE v_first_name VARCHAR(100);
    DECLARE v_last_name VARCHAR(100);
    
    -- Validate JSON length to avoid infinite loops
    IF n = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid or empty JSON input';
    END IF;

    WHILE i < n DO
        -- Extract author data safely
        SET v_first_name = JSON_UNQUOTE(JSON_EXTRACT(author_list, CONCAT('$[', i, '].first_name')));
        SET v_last_name = JSON_UNQUOTE(JSON_EXTRACT(author_list, CONCAT('$[', i, '].last_name')));

        -- Ensure extracted values are not NULL or empty
        IF v_first_name IS NULL OR v_first_name = '' OR v_last_name IS NULL OR v_last_name = '' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid JSON structure: Missing first_name or last_name';
        END IF;

        -- Insert author
        INSERT INTO authors (first_name, last_name)
        VALUES (v_first_name, v_last_name);
        
        SET i = i + 1;
    END WHILE;
    SET i = 0;
    
    SELECT CONCAT(n, ' authors added successfully') AS message;
END //


-- ------------------------------------------------------------------------- BOOK
-- ------------------------------------- ADD BOOK

/*
 * Stored Procedure: add_book
 * Description: Adds a new book with its associated authors and categories
 * Parameters:
 *   - p_title: Book title (VARCHAR(255))
 *   - p_publication_year: Year of publication (INT)
 *   - p_isbn: International Standard Book Number (VARCHAR(13))
 *   - p_copies_available: Number of copies available (INT)
 *   - author_ids: JSON array of author IDs
 *   - category_ids: JSON array of category IDs
 * Returns: None
 * Example Usage:
 *   CALL add_book('1984', 1949, '978-0451524', 5, '[1]', '[1, 5]')
 * Notes:
 *   - Uses transaction to ensure data consistency
 *   - All author_ids and category_ids must exist in their respective tables
 *   - Handles multiple authors and categories for a single book
 */

CREATE PROCEDURE add_book(
    IN p_title VARCHAR(255),
    IN p_publication_year INT,
    IN p_isbn VARCHAR(13),
    IN p_copies_available INT,
    IN author_ids JSON,
    IN category_ids JSON
)
BEGIN
    DECLARE new_book_id INT;
    DECLARE i INT DEFAULT 0;
    DECLARE n_authors INT DEFAULT JSON_LENGTH(author_ids);
    DECLARE n_categories INT DEFAULT JSON_LENGTH(category_ids);
    
    -- Start transaction for atomicity
    START TRANSACTION;
    
    -- Insert book
    INSERT INTO books (title, publication_year, isbn, copies_available)
    VALUES (p_title, p_publication_year, p_isbn, p_copies_available);
    
    SET new_book_id = LAST_INSERT_ID();
    
    -- Add authors
    WHILE i < n_authors DO
        INSERT INTO book_authors (book_id, author_id)
        VALUES (
            new_book_id,
            JSON_EXTRACT(author_ids, CONCAT('$[', i, ']'))
        );
        SET i = i + 1;
    END WHILE;
    SET i = 0;
    -- Reset counter for categories
    SET i = 0;
    
    -- Add categories
    WHILE i < n_categories DO
        INSERT INTO book_category (book_id, category_id)
        VALUES (
            new_book_id,
            JSON_EXTRACT(category_ids, CONCAT('$[', i, ']'))
        );
        SET i = i + 1;
    END WHILE;
    SET i = 0;

    COMMIT;
END //

/*
 * Stored Procedure: edit_book
 * Description: Updates an existing book and its associated authors and categories
 * Parameters:
 *   - p_book_id: ID of the book to edit (INT)
 *   - p_title: Updated book title (VARCHAR(255))
 *   - p_publication_year: Updated year of publication (INT)
 *   - p_isbn: Updated ISBN (VARCHAR(13))
 *   - p_copies_available: Updated number of copies (INT)
 *   - author_ids: JSON array of new author IDs
 *   - category_ids: JSON array of new category IDs
 * Returns: None
 * Example Usage:
 *   CALL edit_book(1, '1984 (Revised)', 1949, '978-0451524', 10, '[1,2]', '[1,3]')
 * Notes:
 *   - Uses transaction to ensure data consistency
 *   - Deletes existing author and category associations before adding new ones
 *   - All author_ids and category_ids must exist in their respective tables
 */

CREATE PROCEDURE edit_book(
    IN p_book_id INT,
    IN p_title VARCHAR(255),
    IN p_publication_year INT,
    IN p_isbn VARCHAR(13),
    IN p_copies_available INT,
    IN author_ids JSON,
    IN category_ids JSON
)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE n_authors INT DEFAULT JSON_LENGTH(author_ids);
    DECLARE n_categories INT DEFAULT JSON_LENGTH(category_ids);
    
    -- Start transaction for atomicity
    START TRANSACTION;
    
    -- Update book details
    UPDATE books 
    SET title = p_title,
        publication_year = p_publication_year,
        isbn = p_isbn,
        copies_available = p_copies_available
    WHERE book_id = p_book_id;
    
    -- Delete existing author associations
    DELETE FROM book_authors 
    WHERE book_id = p_book_id;
    
    -- Delete existing category associations
    DELETE FROM book_category 
    WHERE book_id = p_book_id;
    
    -- Add new authors
    WHILE i < n_authors DO
        INSERT INTO book_authors (book_id, author_id)
        VALUES (
            p_book_id,
            JSON_EXTRACT(author_ids, CONCAT('$[', i, ']'))
        );
        SET i = i + 1;
    END WHILE;
    SET i = 0;
    
    -- Add new categories
    WHILE i < n_categories DO
        INSERT INTO book_category (book_id, category_id)
        VALUES (
            p_book_id,
            JSON_EXTRACT(category_ids, CONCAT('$[', i, ']'))
        );
        SET i = i + 1;
    END WHILE;

    COMMIT;
END //

/*
 * Stored Procedure: delete_book
 * Description: Deletes a book and removes all its associations from related tables
 * Parameters:
 *   - p_book_id: ID of the book to delete (INT)
 * Returns: 
 *   - Success message if book is deleted
 *   - Error if book does not exist or cannot be deleted
 * Example Usage: CALL delete_book(1)
 * Notes:
 *   - Checks if book exists before deletion
 *   - Removes associations from book_authors, book_category, borrowings, and book_cart
 *   - Uses transaction to ensure data integrity
 */

CREATE PROCEDURE delete_book(
    IN p_book_id INT
)
BEGIN
    DECLARE book_exists INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'An error occurred while deleting the book';
    END;
    
    -- Check if book exists
    SELECT COUNT(*) INTO book_exists 
    FROM books 
    WHERE book_id = p_book_id;

    IF book_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Book does not exist';
    ELSE
        -- Start transaction to ensure data integrity
        START TRANSACTION;
        
        -- Delete from book_cart
        DELETE FROM book_cart 
        WHERE book_id = p_book_id;
        
        -- Delete from borrowings
        DELETE FROM borrowings 
        WHERE book_id = p_book_id;
        
        -- Delete from book_category
        DELETE FROM book_category 
        WHERE book_id = p_book_id;
        
        -- Delete from book_authors
        DELETE FROM book_authors 
        WHERE book_id = p_book_id;
        
        -- Finally delete the book
        DELETE FROM books 
        WHERE book_id = p_book_id;
        
        COMMIT;
        
        SELECT CONCAT('Book ID ', p_book_id, ' has been successfully deleted') AS message;
    END IF;
END //

-- ---------------------------------------------------------- LOGIN PROCEDURES
/*
 * AUTHENTICATION AND PROFILE MANAGEMENT PROCEDURES
 * =============================================
 * 
 * This section contains procedures for user authentication and profile management
 * for both members and librarians. These procedures handle login, profile viewing,
 * profile editing, and password changes.
 */

/*
 * Stored Procedure: member_login
 * Description: Authenticates a library member using email and password
 * Parameters:
 *   - p_email: Member's registered email address (VARCHAR(255))
 *   - p_password: Member's password, will be hashed with SHA2 (VARCHAR(255))
 * Returns: Member details (ID, name, email) if credentials match
 * Example Usage: CALL member_login('john@email.com', 'password123')
 * Notes:
 *   - Password is hashed using SHA2 with 256-bit output
 *   - Returns empty result if credentials don't match
 */
CREATE PROCEDURE member_login(
    IN p_email VARCHAR(255),
    IN p_password VARCHAR(255)
)
BEGIN
    DECLARE member_exists INT;
    
    -- Check if credentials match
    SELECT 
        member_id,
        first_name,
        last_name,
        email
    FROM members 
    WHERE email = p_email 
    AND password = SHA2(p_password, 256);
    
END //

/*
 * Stored Procedure: librarian_login
 * Description: Authenticates a library staff member using email and password
 * Parameters:
 *   - p_email: Librarian's registered email address (VARCHAR(255))
 *   - p_password: Librarian's password, will be hashed with SHA2 (VARCHAR(255))
 * Returns: Librarian details (ID, name, email) if credentials match
 * Example Usage: CALL librarian_login('staff@library.com', 'staffpass')
 * Notes:
 *   - Password is hashed using SHA2 with 256-bit output
 *   - Returns empty result if credentials don't match
 */
CREATE PROCEDURE librarian_login(
    IN p_email VARCHAR(255),
    IN p_password VARCHAR(255)
)
BEGIN
    DECLARE librarian_exists INT;
    
    -- Check if credentials match
    SELECT 
        librarian_id,
        first_name, 
        last_name,
        email
    FROM librarians
    WHERE email = p_email
    AND password = SHA2(p_password, 256);
    
END //

/*
 * Stored Procedure: view_member_profile
 * Description: Retrieves profile information for a specific member
 * Parameters:
 *   - p_member_id: ID of the member to view (INT)
 * Returns: Member's full profile including contact details
 * Example Usage: CALL view_member_profile(1)
 * Notes:
 *   - Returns all non-sensitive member information
 *   - Password is excluded from results
 */
CREATE PROCEDURE view_member_profile(
    IN p_member_id INT
)
BEGIN
    SELECT 
        member_id,
        first_name,
        last_name,
        email,
        phone_number,
        address
    FROM members
    WHERE member_id = p_member_id;
END //

/*
 * Stored Procedure: view_librarian_profile
 * Description: Retrieves profile information for a specific librarian
 * Parameters:
 *   - p_librarian_id: ID of the librarian to view (INT)
 * Returns: Librarian's basic profile information
 * Example Usage: CALL view_librarian_profile(1)
 * Notes:
 *   - Returns only basic librarian information
 *   - Password is excluded from results
 */
CREATE PROCEDURE view_librarian_profile(
    IN p_librarian_id INT
)
BEGIN
    SELECT 
        librarian_id,
        first_name,
        last_name,
        email
    FROM librarians
    WHERE librarian_id = p_librarian_id;
END //

/*
 * Stored Procedure: edit_member_profile
 * Description: Updates profile information for a specific member
 * Parameters:
 *   - p_member_id: ID of the member to update (INT)
 *   - p_first_name: New first name (VARCHAR(100))
 *   - p_last_name: New last name (VARCHAR(100))
 *   - p_phone_number: New phone number (VARCHAR(20))
 *   - p_address: New address (TEXT)
 * Returns: Updated member profile
 * Example Usage: CALL edit_member_profile(1, 'John', 'Smith', '+1234567890', '123 Main St')
 * Notes:
 *   - Uses COALESCE to only update provided fields
 *   - Automatically updates timestamp
 */
CREATE PROCEDURE edit_member_profile(
    IN p_member_id INT,
    IN p_first_name VARCHAR(100),
    IN p_last_name VARCHAR(100),
    IN p_phone_number VARCHAR(20),
    IN p_address TEXT
)
BEGIN
    UPDATE members
    SET 
        first_name = COALESCE(p_first_name, first_name),
        last_name = COALESCE(p_last_name, last_name),
        phone_number = COALESCE(p_phone_number, phone_number),
        address = COALESCE(p_address, address),
        updated_at = CURRENT_TIMESTAMP
    WHERE member_id = p_member_id;
    
    -- Return updated profile
    SELECT * FROM members WHERE member_id = p_member_id;
END //

/*
 * Stored Procedure: edit_librarian_profile
 * Description: Updates profile information for a specific librarian
 * Parameters:
 *   - p_librarian_id: ID of the librarian to update (INT)
 *   - p_first_name: New first name (VARCHAR(100))
 *   - p_last_name: New last name (VARCHAR(100))
 * Returns: Updated librarian profile
 * Example Usage: CALL edit_librarian_profile(1, 'Jane', 'Doe')
 * Notes:
 *   - Uses COALESCE to only update provided fields
 *   - Limited to name changes only for security
 */
CREATE PROCEDURE edit_librarian_profile(
    IN p_librarian_id INT,
    IN p_first_name VARCHAR(100),
    IN p_last_name VARCHAR(100)
)
BEGIN
    UPDATE librarians
    SET 
        first_name = COALESCE(p_first_name, first_name),
        last_name = COALESCE(p_last_name, last_name)
    WHERE librarian_id = p_librarian_id;
    
    -- Return updated profile
    SELECT * FROM librarians WHERE librarian_id = p_librarian_id;
END //

/*
 * Stored Procedure: change_member_password
 * Description: Updates password for a specific member after verification
 * Parameters:
 *   - p_member_id: ID of the member (INT)
 *   - p_old_password: Current password for verification (VARCHAR(256))
 *   - p_new_password: New password to set (VARCHAR(256))
 * Returns: Success/failure message
 * Example Usage: CALL change_member_password(1, 'oldpass123', 'newpass123')
 * Notes:
 *   - Verifies old password before allowing change
 *   - Passwords are hashed using SHA2
 *   - Updates timestamp on successful change
 */
CREATE PROCEDURE change_member_password(
    IN p_member_id INT,
    IN p_old_password VARCHAR(256),
    IN p_new_password VARCHAR(256)
)
BEGIN
    DECLARE password_matches INT;
    
    -- Check if old password matches
    SELECT COUNT(*) INTO password_matches
    FROM members
    WHERE member_id = p_member_id 
    AND password = SHA2(p_old_password, 256);
    
    IF password_matches = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Current password is incorrect';
    ELSE
        UPDATE members
        SET 
            password = SHA2(p_new_password, 256),
            updated_at = CURRENT_TIMESTAMP
        WHERE member_id = p_member_id;
        
        SELECT 'Password updated successfully' as message;
    END IF;
END //

/*
 * Stored Procedure: change_librarian_password
 * Description: Updates password for a specific librarian after verification
 * Parameters:
 *   - p_librarian_id: ID of the librarian (INT)
 *   - p_old_password: Current password for verification (VARCHAR(256))
 *   - p_new_password: New password to set (VARCHAR(256))
 * Returns: Success/failure message
 * Example Usage: CALL change_librarian_password(1, 'oldpass123', 'newpass123')
 * Notes:
 *   - Verifies old password before allowing change
 *   - Passwords are hashed using SHA2
 */
CREATE PROCEDURE change_librarian_password(
    IN p_librarian_id INT,
    IN p_old_password VARCHAR(256),
    IN p_new_password VARCHAR(256)
)
BEGIN
    DECLARE password_matches INT;
    
    -- Check if old password matches
    SELECT COUNT(*) INTO password_matches
    FROM librarians
    WHERE librarian_id = p_librarian_id 
    AND password = SHA2(p_old_password, 256);
    
    IF password_matches = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Current password is incorrect';
    ELSE
        UPDATE librarians
        SET password = SHA2(p_new_password, 256)
        WHERE librarian_id = p_librarian_id;
        
        SELECT 'Password updated successfully' as message;
    END IF;
END //



/* DISPLAY OUTPUTS */


-- ---------------------------------------------------- /* LIBRARIAN DISPLAY */
/*
 * LIBRARIAN DISPLAY PROCEDURES
 * ===========================
 * 
 * This section contains procedures that are ONLY accessible to librarians.
 * These procedures provide administrative functionality for managing and viewing
 * library data. Regular members do not have access to these procedures.
 */

/*
 * Display Books Table
 * ------------------
 * Allows librarians to view and filter the book inventory
 *
 * Parameters:
 * - p_search_title: Optional search term to filter books by title
 * - p_filter_available: When true, shows only books with copies available
 *                      When false, shows only books with no copies
 *                      When null, shows all books
 * - p_sort_by_title: When true, sorts results alphabetically by title
 *                    When false/null, sorts by book ID
 *
 * Returns: Book ID, title, creation date, and available copies
 */
CREATE PROCEDURE display_books(
    IN p_search_title VARCHAR(255),
    IN p_filter_available BOOLEAN,
    IN p_sort_by_title BOOLEAN
)
BEGIN
    SELECT 
        b.book_id,
        b.title,
        b.created_at,
        b.copies_available
    FROM books b
    WHERE 
        (p_search_title IS NULL OR b.title LIKE CONCAT('%', p_search_title, '%'))
        AND (p_filter_available IS NULL OR 
            CASE 
                WHEN p_filter_available = 1 THEN b.copies_available > 0
                ELSE b.copies_available = 0
            END)
    ORDER BY
        CASE WHEN p_sort_by_title = 1 THEN b.title END ASC,
        CASE WHEN p_sort_by_title = 0 OR p_sort_by_title IS NULL THEN b.book_id END ASC;
END //

/*
 * View Specific Book Details
 * -------------------------
 * Retrieves detailed information about a specific book including authors and categories
 *
 * Parameters:
 * - p_book_id: The ID of the book to view
 *
 * Returns: Complete book details including:
 * - Book ID, title, publication year, ISBN
 * - Number of available copies
 * - Comma-separated list of authors
 * - Comma-separated list of categories
 */
CREATE PROCEDURE view_book_details(
    IN p_book_id INT
)
BEGIN
    SELECT 
        b.book_id,
        b.title,
        b.publication_year,
        b.isbn,
        b.copies_available,
        GROUP_CONCAT(DISTINCT a.full_name) as authors,
        GROUP_CONCAT(DISTINCT c.category_name) as categories
    FROM books b
    LEFT JOIN book_authors ba ON b.book_id = ba.book_id
    LEFT JOIN authors a ON ba.author_id = a.author_id
    LEFT JOIN book_category bc ON b.book_id = bc.book_id
    LEFT JOIN categories c ON bc.category_id = c.category_id
    WHERE b.book_id = p_book_id
    GROUP BY b.book_id;
END //

/*
 * Display Authors
 * --------------
 * Lists all authors with their book counts and optional filtering/sorting
 *
 * Parameters:
 * - p_search_name: Optional search term to filter authors by name
 * - p_sort_by_name: When true, sorts results alphabetically by author name
 *                   When false/null, sorts by author ID
 *
 * Returns: Author ID, full name, and total number of books by author
 */
CREATE PROCEDURE display_authors(
    IN p_search_name VARCHAR(255),
    IN p_sort_by_name BOOLEAN
)
BEGIN
    SELECT 
        a.author_id,
        a.full_name,
        COUNT(DISTINCT ba.book_id) as number_of_books
    FROM authors a
    LEFT JOIN book_authors ba ON a.author_id = ba.author_id
    WHERE 
        p_search_name IS NULL OR 
        a.full_name LIKE CONCAT('%', p_search_name, '%')
    GROUP BY a.author_id
    ORDER BY
        CASE WHEN p_sort_by_name = 1 THEN a.full_name END ASC,
        CASE WHEN p_sort_by_name = 0 OR p_sort_by_name IS NULL THEN a.author_id END ASC;
END //

/*
 * Display Categories
 * ----------------
 * Lists all book categories with their book counts and optional filtering/sorting
 *
 * Parameters:
 * - p_search_name: Optional search term to filter categories by name
 * - p_sort_by_name: When true, sorts results alphabetically by category name
 *                   When false/null, sorts by category ID
 *
 * Returns: Category ID, name, and total number of books in category
 */
CREATE PROCEDURE display_categories(
    IN p_search_name VARCHAR(100),
    IN p_sort_by_name BOOLEAN
)
BEGIN
    SELECT 
        c.category_id,
        c.category_name,
        COUNT(DISTINCT bc.book_id) as number_of_books
    FROM categories c
    LEFT JOIN book_category bc ON c.category_id = bc.category_id
    WHERE 
        p_search_name IS NULL OR 
        c.category_name LIKE CONCAT('%', p_search_name, '%')
    GROUP BY c.category_id
    ORDER BY
        CASE WHEN p_sort_by_name = 1 THEN c.category_name END ASC,
        CASE WHEN p_sort_by_name = 0 OR p_sort_by_name IS NULL THEN c.category_id END ASC;
END //

/*
 * Display Users
 * ------------
 * Lists library members with optional search and sorting capabilities
 *
 * Parameters:
 * - p_search_term: Optional search term to filter users by name, email, or phone
 * - p_sort_by_name: When true, sorts results alphabetically by member name
 *                   When false/null, sorts by member ID
 *
 * Returns: Member's first name, last name, email, and phone number
 */
CREATE PROCEDURE display_users(
    IN p_search_term VARCHAR(255),
    IN p_sort_by_name BOOLEAN
)
BEGIN
    SELECT 
        first_name,
        last_name,
        email,
        phone_number
    FROM members
    WHERE 
        p_search_term IS NULL OR
        first_name LIKE CONCAT('%', p_search_term, '%') OR
        last_name LIKE CONCAT('%', p_search_term, '%') OR
        email LIKE CONCAT('%', p_search_term, '%') OR
        phone_number LIKE CONCAT('%', p_search_term, '%')
    ORDER BY
        CASE WHEN p_sort_by_name = 1 THEN full_name END ASC,
        CASE WHEN p_sort_by_name = 0 OR p_sort_by_name IS NULL THEN member_id END ASC;
END //

/*
 * Display Borrowed Books
 * --------------------
 * Shows all book borrowings with detailed member information and status
 *
 * Parameters:
 * - p_search_term: Optional search term to filter by member name, email, or phone
 * - p_filter_status: Optional filter for borrowing status (borrowed/returned/overdue)
 * - p_sort_by_book_name: When true, sorts results alphabetically by book title
 *                        When false/null, sorts by borrowing ID
 *
 * Returns: Borrowing details including:
 * - Borrowing ID, book title
 * - Member's full name, email, phone
 * - Due date and return status
 */
CREATE PROCEDURE display_borrowed_books(
    IN p_search_term VARCHAR(255),
    IN p_filter_status ENUM('borrowed', 'returned', 'overdue'),
    IN p_sort_by_book_name BOOLEAN
)
BEGIN
    SELECT 
        br.borrowing_id,
        b.title as book_name,
        m.full_name as member_name,
        m.email,
        m.phone_number,
        br.due_date,
        CASE 
            WHEN br.returned_at IS NOT NULL THEN 'Returned'
            ELSE 'Not Returned'
        END as return_status
    FROM borrowings br
    INNER JOIN books b ON br.book_id = b.book_id
    INNER JOIN members m ON br.member_id = m.member_id
    WHERE 
        (p_search_term IS NULL OR
        m.full_name LIKE CONCAT('%', p_search_term, '%') OR
        m.email LIKE CONCAT('%', p_search_term, '%') OR
        m.phone_number LIKE CONCAT('%', p_search_term, '%'))
        AND (p_filter_status IS NULL OR br.status = p_filter_status)
    ORDER BY
        CASE WHEN p_sort_by_book_name = 1 THEN b.title END ASC,
        CASE WHEN p_sort_by_book_name = 0 OR p_sort_by_book_name IS NULL THEN br.borrowing_id END ASC;
END //

/* MEMBER PROCEDURES */

/*
 * Stored Procedure: add_to_cart
 * Description: Adds a book to a member's cart for later borrowing
 * Parameters:
 *   - p_member_id: ID of the member adding to cart (INT)
 *   - p_book_id: ID of the book to add (INT)
 * Returns: None
 * Example Usage: CALL add_to_cart(1, 5)
 * Notes:
 *   - Creates a new cart entry linking the member and book
 *   - Does not check book availability
 */
CREATE PROCEDURE add_to_cart(
    IN p_member_id INT,
    IN p_book_id INT
)
BEGIN
    INSERT INTO book_cart (member_id, book_id)
    VALUES (p_member_id, p_book_id);
END //

/*
 * Stored Procedure: remove_from_cart
 * Description: Removes a book from a member's cart
 * Parameters:
 *   - p_member_id: ID of the member removing from cart (INT)
 *   - p_book_id: ID of the book to remove (INT)
 * Returns: None
 * Example Usage: CALL remove_from_cart(1, 5)
 * Notes:
 *   - Deletes the cart entry for the specified member and book
 *   - No error if entry doesn't exist
 */
CREATE PROCEDURE remove_from_cart(
    IN p_member_id INT,
    IN p_book_id INT
)
BEGIN
    DELETE FROM book_cart 
    WHERE member_id = p_member_id AND book_id = p_book_id;
END //

/*
 * Stored Procedure: borrow_book
 * Description: Records a book borrowing and updates inventory
 * Parameters:
 *   - p_member_id: ID of the borrowing member (INT)
 *   - p_book_id: ID of the book being borrowed (INT)
 * Returns: None
 * Example Usage: CALL borrow_book(1, 5)
 * Notes:
 *   - Creates borrowing record with 14 day due date
 *   - Decrements available copies count
 *   - Does not validate copy availability
 */
CREATE PROCEDURE borrow_book(
    IN p_member_id INT,
    IN p_book_id INT
)
BEGIN
    INSERT INTO borrowings (member_id, book_id, due_date)
    VALUES (p_member_id, p_book_id, DATE_ADD(CURRENT_DATE, INTERVAL 14 DAY));
    
    UPDATE books 
    SET copies_available = copies_available - 1
    WHERE book_id = p_book_id;
END //

/*
 * Stored Procedure: return_book
 * Description: Processes a book return and updates inventory
 * Parameters:
 *   - p_borrowing_id: ID of the borrowing record (INT)
 * Returns: None
 * Example Usage: CALL return_book(1)
 * Notes:
 *   - Updates borrowing status to 'returned'
 *   - Records return timestamp
 *   - Increments available copies count
 */
CREATE PROCEDURE return_book(
    IN p_borrowing_id INT
)
BEGIN
    DECLARE v_book_id INT;
    
    SELECT book_id INTO v_book_id
    FROM borrowings
    WHERE borrowing_id = p_borrowing_id;
    
    UPDATE borrowings 
    SET returned_at = CURRENT_TIMESTAMP,
        status = 'returned'
    WHERE borrowing_id = p_borrowing_id;
    
    UPDATE books
    SET copies_available = copies_available + 1
    WHERE book_id = v_book_id;
END //

/*
 * Stored Procedure: popular_available_books
 * Description: Lists the most frequently borrowed books that are currently available
 * Parameters: None
 * Returns: Book titles and their borrow counts
 * Example Usage: CALL popular_available_books()
 * Notes:
 *   - Only includes books with at least one borrow
 *   - Limited to top 5 most borrowed
 *   - Only shows currently available books
 */
CREATE PROCEDURE popular_available_books()
BEGIN
    SELECT 
        b.title,
        COUNT(br.borrowing_id) as borrow_count
    FROM books b
    LEFT JOIN borrowings br ON b.book_id = br.book_id
    WHERE b.copies_available > 0
    GROUP BY b.book_id, b.title
    HAVING COUNT(br.borrowing_id) > 0
    ORDER BY borrow_count DESC
    LIMIT 5;
END //

/*
 * Stored Procedure: book_cards
 * Description: Generates book listings with filtering and sorting options
 * Parameters:
 *   - p_search_title: Search term for book title (VARCHAR(255))
 *   - p_category_id: Filter by category ID (INT)
 *   - p_sort_by_title: Sort alphabetically by title when true (BOOLEAN)
 * Returns: Book details including title, authors, categories and availability
 * Example Usage: CALL book_cards('Harry', 1, true)
 * Notes:
 *   - Only shows available books
 *   - Authors and categories are concatenated lists
 *   - Supports partial title matching
 */
CREATE PROCEDURE book_cards(
    IN p_search_title VARCHAR(255),
    IN p_category_id INT,
    IN p_sort_by_title BOOLEAN
)
BEGIN
    SELECT 
        b.title,
        GROUP_CONCAT(DISTINCT a.full_name) as authors,
        GROUP_CONCAT(DISTINCT c.category_name) as categories,
        b.copies_available
    FROM books b
    LEFT JOIN book_authors ba ON b.book_id = ba.book_id
    LEFT JOIN authors a ON ba.author_id = a.author_id
    LEFT JOIN book_category bc ON b.book_id = bc.book_id
    LEFT JOIN categories c ON bc.category_id = c.category_id
    WHERE b.copies_available > 0
    AND (p_search_title IS NULL OR b.title LIKE CONCAT('%', p_search_title, '%'))
    AND (p_category_id IS NULL OR c.category_id = p_category_id)
    GROUP BY b.book_id
    ORDER BY 
        CASE WHEN p_sort_by_title = 1 THEN b.title END ASC,
        CASE WHEN p_sort_by_title = 0 OR p_sort_by_title IS NULL THEN b.book_id END ASC;
END //

/*
 * Stored Procedure: book_view
 * Description: Retrieves detailed information for a specific book
 * Parameters:
 *   - p_book_id: ID of the book to view (INT)
 * Returns: Book details including title, authors, categories, availability and borrow history
 * Example Usage: CALL book_view(1)
 * Notes:
 *   - Authors and categories are concatenated lists
 *   - Includes total times borrowed count
 */
CREATE PROCEDURE book_view(
    IN p_book_id INT
)
BEGIN
    SELECT 
        b.title,
        GROUP_CONCAT(DISTINCT a.full_name) as authors,
        GROUP_CONCAT(DISTINCT c.category_name) as categories,
        b.copies_available,
        COUNT(DISTINCT borrowing_id) as times_borrowed
    FROM books b
    LEFT JOIN book_authors ba ON b.book_id = ba.book_id
    LEFT JOIN authors a ON ba.author_id = a.author_id
    LEFT JOIN book_category bc ON b.book_id = bc.book_id
    LEFT JOIN categories c ON bc.category_id = c.category_id
    LEFT JOIN borrowings br ON b.book_id = br.book_id
    WHERE b.book_id = p_book_id
    GROUP BY b.book_id;
END //

/*
 * Stored Procedure: member_borrowed_books
 * Description: Lists all books currently borrowed by a member
 * Parameters:
 *   - p_member_id: ID of the member (INT)
 * Returns: Titles of books currently borrowed
 * Example Usage: CALL member_borrowed_books(1)
 * Notes:
 *   - Only shows unreturned books
 *   - Uses RIGHT JOIN to ensure all borrowed books are included
 */
CREATE PROCEDURE member_borrowed_books(
    IN p_member_id INT
)
BEGIN
    SELECT b.title
    FROM borrowings br
    RIGHT JOIN books b ON br.book_id = b.book_id
    WHERE br.member_id = p_member_id
    AND br.returned_at IS NULL;
END //

/*
 * Stored Procedure: member_cart
 * Description: Lists all books in a member's cart
 * Parameters:
 *   - p_member_id: ID of the member (INT)
 * Returns: Titles of books in cart
 * Example Usage: CALL member_cart(1)
 * Notes:
 *   - Uses RIGHT JOIN to ensure all cart items are included
 */
CREATE PROCEDURE member_cart(
    IN p_member_id INT
)
BEGIN
    SELECT b.title
    FROM book_cart bc
    RIGHT JOIN books b ON bc.book_id = b.book_id
    WHERE bc.member_id = p_member_id;
END //

DELIMITER ;