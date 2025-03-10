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