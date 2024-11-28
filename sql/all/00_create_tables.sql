-- Переключение на базу данных shared_db
\c shared_db

-- Создание таблицы services
CREATE TABLE IF NOT EXISTS services (
    id SERIAL PRIMARY KEY,       -- Уникальный идентификатор услуги
    name TEXT NOT NULL,          -- Название услуги
    price NUMERIC(10, 2) NOT NULL, -- Цена услуги
    currency CHAR(3) NOT NULL    -- Валюта услуги (например, USD, EUR)
);
