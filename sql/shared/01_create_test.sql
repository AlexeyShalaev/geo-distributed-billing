-- Создание базы данных
CREATE DATABASE example_db;

-- Подключение к созданной базе данных
\c example_db;

-- Создание таблицы services
CREATE TABLE example_table (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

-- Пример вставки данных
INSERT INTO example_table (name)
VALUES 
    ('a'),
    ('b'),
    ('c');

