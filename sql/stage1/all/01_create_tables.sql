-- Переключение на базу данных shared_db
\c shared_db

-- Создание таблицы services
CREATE TABLE IF NOT EXISTS services (
    id SERIAL PRIMARY KEY,       -- Уникальный идентификатор услуги
    name TEXT NOT NULL,          -- Название услуги
    price NUMERIC(10, 2) NOT NULL, -- Цена услуги
    currency CHAR(3) NOT NULL    -- Валюта услуги (например, USD, EUR)
);

CREATE TABLE account_balances (
    account_id INT NOT NULL,       -- ID аккаунта
    node_id INT NOT NULL,          -- ID узла
    balance NUMERIC NOT NULL,      -- Баланс аккаунта
    PRIMARY KEY (account_id, node_id) -- Составной первичный ключ
);

CREATE TABLE node_config (
    node_id INT PRIMARY KEY,          -- ID узла
    dsn TEXT NOT NULL                 -- Строка подключения к узлу
);

CREATE TABLE transaction_log (
    id SERIAL PRIMARY KEY,           -- Уникальный идентификатор записи
    account_id INT NOT NULL,         -- ID аккаунта
    node_id INT NOT NULL,            -- Узел, инициировавший операцию
    operation_type TEXT NOT NULL,    -- Тип операции ('deposit' / 'withdraw')
    amount NUMERIC NOT NULL,         -- Сумма операции
    timestamp TIMESTAMP DEFAULT NOW()-- Время операции
);
