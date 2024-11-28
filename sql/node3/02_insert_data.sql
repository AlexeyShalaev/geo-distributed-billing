-- Переключение на базу данных shared_db
\c shared_db

INSERT INTO account_balances (account_id, node_id, balance)
VALUES
    -- Баланс аккаунта 1
    (1, 1, 1000.0),   -- Узел 1: запись для чтения
    (1, 2, 200.0),   -- Узел 2: запись для чтения
    (1, 3, 400.0),   -- Узел 3: запись для записи

    -- Баланс аккаунта 2
    (2, 1, 1500.0),  -- Узел 1: запись для чтения
    (2, 2, 800.0),    -- Узел 2: запись для чтения
    (2, 3, 600.0),   -- Узел 3: запись для записи

    -- Баланс аккаунта 3
    (3, 1, 300.0),   -- Узел 1: запись для чтения
    (3, 2, 500.0),   -- Узел 2: запись для чтения
    (3, 3, 900.0);    -- Узел 3: запись для записи
