-- Переключение на базу данных shared_db
\c shared_db

-- Создание таблицы services
CREATE TABLE IF NOT EXISTS services (
    id SERIAL PRIMARY KEY,       -- Уникальный идентификатор услуги
    name TEXT NOT NULL,          -- Название услуги
    price NUMERIC(10, 2) NOT NULL, -- Цена услуги
    currency CHAR(3) NOT NULL    -- Валюта услуги (например, USD, EUR)
);

-- Пример вставки данных в таблицу
INSERT INTO services (name, price, currency)
VALUES 
    ('Консультация специалиста', 50.00, 'USD'),
    ('Аренда оборудования', 100.00, 'EUR'),
    ('Обучение персонала', 200.00, 'USD');

