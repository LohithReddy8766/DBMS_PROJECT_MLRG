DROP DATABASE MRLG;
CREATE DATABASE MRLG;
USE MRLG;
-- ========================
-- USERS TABLE
-- ========================
CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    cooking_level ENUM('beginner', 'intermediate', 'advanced') DEFAULT 'beginner',
    experience_points INT DEFAULT 0
);

-- ========================
-- RECIPES TABLE
-- ========================
CREATE TABLE Recipes (
    recipe_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    ingredients TEXT,
    instructions TEXT,
    preparation_time INT,
    cooking_time INT,
    difficulty_level ENUM('beginner', 'intermediate', 'advanced'),
    servings INT,
    image_url TEXT,
    user_id INT,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE SET NULL
);

-- ========================
-- CATEGORIES TABLE
-- ========================
CREATE TABLE Categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

-- ========================
-- RECIPE_CATEGORIES TABLE
-- ========================
CREATE TABLE Recipe_Categories (
    recipe_id INT,
    category_id INT,
    PRIMARY KEY (recipe_id, category_id),
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id) ON DELETE CASCADE
);

-- ========================
-- REVIEWS TABLE
-- ========================
CREATE TABLE Reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    recipe_id INT,
    comment TEXT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE
);

-- ========================
-- USER PROGRESS TABLE
-- ========================
CREATE TABLE UserProgress (
    user_id INT,
    recipe_id INT,
    completed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, recipe_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE
);

-- ========================
-- TROPHIES TABLE
-- ========================
CREATE TABLE Trophies (
    trophy_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    description TEXT,
    image_url TEXT
);

-- ========================
-- USER TROPHIES TABLE
-- ========================
CREATE TABLE UserTrophies (
    user_id INT,
    trophy_id INT,
    awarded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, trophy_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (trophy_id) REFERENCES Trophies(trophy_id) ON DELETE CASCADE
);

-- ========================
-- STORED PROCEDURES
-- ========================

-- Create User
DELIMITER //
CREATE PROCEDURE CreateUser(
    IN p_username VARCHAR(50),
    IN p_email VARCHAR(100),
    IN p_password_hash VARCHAR(255)
)
BEGIN
    INSERT INTO Users (username, email, password_hash)
    VALUES (p_username, p_email, p_password_hash);
END;
//
DELIMITER ;

-- Get User By Username
DELIMITER //
CREATE PROCEDURE GetUserByUsername(
    IN p_username VARCHAR(50)
)
BEGIN
    SELECT * FROM Users WHERE username = p_username;
END;
//
DELIMITER ;

-- Complete a Recipe
DELIMITER //
CREATE PROCEDURE CompleteRecipe(
    IN p_user_id INT,
    IN p_recipe_id INT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM UserProgress WHERE user_id = p_user_id AND recipe_id = p_recipe_id
    ) THEN
        INSERT INTO UserProgress (user_id, recipe_id) VALUES (p_user_id, p_recipe_id);
        
        UPDATE Users
        SET experience_points = experience_points + 10
        WHERE user_id = p_user_id;

        UPDATE Users
        SET cooking_level = CASE
            WHEN experience_points >= 100 THEN 'advanced'
            WHEN experience_points >= 50 THEN 'intermediate'
            ELSE 'beginner'
        END
        WHERE user_id = p_user_id;
    END IF;
END;
//
DELIMITER ;

-- Add a Review
DELIMITER //
CREATE PROCEDURE AddReview(
    IN p_user_id INT,
    IN p_recipe_id INT,
    IN p_comment TEXT,
    IN p_rating INT
)
BEGIN
    INSERT INTO Reviews (user_id, recipe_id, comment, rating)
    VALUES (p_user_id, p_recipe_id, p_comment, p_rating);
END;
//
DELIMITER ;

-- Get Reviews For Recipe
DELIMITER //
CREATE PROCEDURE GetReviews(
    IN p_recipe_id INT
)
BEGIN
    SELECT r.comment, r.rating, r.created_at, u.username
    FROM Reviews r
    JOIN Users u ON r.user_id = u.user_id
    WHERE r.recipe_id = p_recipe_id
    ORDER BY r.created_at DESC;
END;
//
DELIMITER ;

-- Get User Dashboard Info
DELIMITER //
CREATE PROCEDURE GetUserDashboard(
    IN p_user_id INT
)
BEGIN
    SELECT 
        u.username, 
        u.cooking_level, 
        u.experience_points,
        (SELECT COUNT(*) FROM UserProgress WHERE user_id = p_user_id) AS completed_recipes,
        (SELECT COUNT(*) FROM UserTrophies WHERE user_id = p_user_id) AS trophies_earned;
END;
//
DELIMITER ;
