-- Переключение на базу данных billing
\c billing

-- Создание таблицы accounts
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- Создание таблицы services
CREATE TABLE IF NOT EXISTS services (
    id SERIAL PRIMARY KEY,                              -- Уникальный идентификатор услуги
    name TEXT NOT NULL,                                 -- Название услуги
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),   -- Цена услуги
    currency CHAR(3) NOT NULL                           -- Валюта услуги (например, USD, EUR)
);

CREATE TABLE account_balances (
    account_id INT NOT NULL,            -- ID аккаунта
    node_id INT NOT NULL,               -- ID узла
    balance NUMERIC NOT NULL,           -- Баланс аккаунта
    PRIMARY KEY (account_id, node_id)   -- Составной первичный ключ
);

CREATE TABLE node_config (
    node_id INT PRIMARY KEY,            -- ID ноды
    encrypted_dsn BYTEA NOT NULL        -- Зашифрованная строка подключения
);

CREATE TABLE transaction_log (
    id SERIAL PRIMARY KEY,              -- Уникальный идентификатор записи
    account_id INT NOT NULL,            -- ID аккаунта
    node_id INT NOT NULL,               -- Узел, инициировавший операцию
    -- Тип операции ('deposit' / 'withdraw')
    operation_type TEXT NOT NULL CHECK (operation_type IN ('deposit', 'withdraw')),
    amount NUMERIC NOT NULL,            -- Сумма операции
    created_at TIMESTAMP DEFAULT NOW()  -- Время операции
);

-- Foreign key constraints

ALTER TABLE account_balances
ADD CONSTRAINT fk_account_balances_node
FOREIGN KEY (node_id) REFERENCES node_config (node_id)
ON DELETE RESTRICT;

ALTER TABLE transaction_log
ADD CONSTRAINT fk_transaction_log_node
FOREIGN KEY (node_id) REFERENCES node_config (node_id)
ON DELETE RESTRICT;