# MySQL - Library Management System

This repository contains a comprehensive MySQL project designed for managing a **library system**. It provides hands-on experience with **relational database design, structured queries, stored procedures, and triggers**, following a **modular and well-structured approach**.

---

## 🏛 Overview
The project consists of multiple SQL files categorized into different steps for **better maintainability and modular execution**.

1. **`setup.sql`** - The **initial database setup** file, which creates tables, relationships, and constraints.
2. **`step_1.sql`** - Procedure calls
3. **`step_2.sql`** - Procedure calls
4. **`step_3.sql`** - Procedure calls

Additionally, queries are organized into **modular subfolders** for better readability and maintainability.

---

## 📂 Folder Structure

### **Main SQL Files**
- **`setup.sql`** - The **first file** that must be executed to set up the database schema.
- **`step_1.sql`** - Contains stored procedures for **members and librarians**.
- **`step_2.sql`** - Implements **triggers and indexing** for optimization.
- **`step_3.sql`** - Includes advanced queries and other operations.

### **Query Breakdown (Modular Structure)**
This folder structure organizes queries based on their functionality:

📂 **Procedures/** - Contains modular files for stored procedures:
- 📂 `LIBRARIANS/` - All operations related to **librarians** (login, profile management, book management).
- 📂 `MEMBER/` - All operations related to **members** (signup, login, borrowing books, profile updates).

📂 **Schema/** - Contains SQL definitions for:
- 📄 `TABLE_STRUCTURES.sql` - Defines all **tables and relationships**.
- 📄 `CONSTRAINTS.sql` - Defines **foreign keys, primary keys, and unique constraints**.

📂 **Triggers/** - Contains all triggers that enforce business rules and automate database processes.

---

## 📸 SCHEMA
![schema](https://github.com/user-attachments/assets/390f2368-1def-43dd-a6dc-df5abdaa7578)

---

## 💻 Prerequisites
Before running this project, ensure you have:
- **XAMPP** or any MySQL-supported database engine installed.
- Basic knowledge of **MySQL and relational database concepts**.

---

## 🚀 Installation & Setup Guide

### **Step 1: Start MySQL Server**
- If using **XAMPP**, launch the **XAMPP Control Panel** and start the **MySQL module**.
- If using another MySQL service, make sure the server is running.

### **Step 2: Open phpMyAdmin**
- Open your browser and navigate to **[http://localhost/phpmyadmin/](http://localhost/phpmyadmin/)**.

### **Step 3: Create a New Database**
- Click on **"New"** in the left sidebar.
- Enter a database name (e.g., `library_db`) and click **"Create"**.

### **Step 4: Import the Setup File**
1. Select the **newly created database**.
2. Click on the **"Import"** tab.
3. Select **`setup.sql`** and click **"Go"** to execute it.

### **Step 5: Import Step Files (One by One)**
1. After successfully importing **setup.sql**, repeat the import process.
2. Execute **`step_1.sql`**, **`step_2.sql`**, and **`step_3.sql`** in sequence.

### **Step 6: Verify Database Setup**
- Navigate to the **"Structure"** tab in phpMyAdmin to ensure that all tables have been created.
- Run sample queries to verify data insertion and retrieval.

---

## 📌 Features
✅ **Fully normalized relational database** (3NF).  
✅ **Stored procedures for reusable query execution**.  
✅ **Triggers for automated database operations**.  
✅ **Indexed queries for better performance**.  
✅ **Comprehensive modular breakdown for easier understanding**.  

---

## ⚡ Example Queries

### **Example: Adding a New Library Member**
```sql
CALL signup_member('John', 'Doe', 'john.doe@email.com', 'John00', '+1234567890', '123 Main St');
```

### **Example: Checking Out a Book**
```sql
CALL borrow_book(1, 3); -- Member ID: 1, Book ID: 3
```

### **Example: Retrieving All Available Books**
```sql
SELECT * FROM books WHERE available_copies > 0;
```

---

## 📜 License
This project is open-source and available for **educational purposes**. Feel free to fork and modify it for your learning.

---

## 📢 Feedback & Contributions
If you have suggestions for improvements or encounter issues, feel free to **submit an issue** or contribute via **pull requests**.
