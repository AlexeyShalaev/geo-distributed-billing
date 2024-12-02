CREATE OR REPLACE FUNCTION add_account(
    p_username TEXT,            -- Имя пользователя
    p_initial_balance NUMERIC,  -- Начальный баланс
    p_node_id INT               -- Локальная нода для баланса
)
RETURNS VOID AS $$
DECLARE
    new_account_id INT;
    node RECORD;
BEGIN
    -- Проверка имени пользователя
    IF p_username IS NULL OR TRIM(p_username) = '' THEN
        RAISE EXCEPTION 'Username cannot be null or empty.';
    END IF;

    -- Проверка на положительный начальный баланс
    IF p_initial_balance < 0 THEN
        RAISE EXCEPTION 'Initial balance cannot be negative.';
    END IF;

    -- Проверка существования локальной ноды
    IF NOT EXISTS (
        SELECT 1 FROM node_config WHERE node_id = p_node_id
    ) THEN
        RAISE EXCEPTION 'Local node with ID % does not exist.', p_node_id;
    END IF;


    -- Создание нового аккаунта на локальном узле
    INSERT INTO accounts (username)
    VALUES (p_username)
    RETURNING id INTO new_account_id;

    -- Проверка, что аккаунт был создан
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Account with username % already exists.', p_username;
    END IF;

    -- Распространение аккаунта на все удалённые ноды через dblink
    FOR node IN 
        SELECT node_id FROM node_config
    LOOP
        IF node.node_id = p_node_id THEN
            -- Пропуск локальной ноды, так как аккаунт уже создан
            CONTINUE;
        END IF;

        -- Добавление аккаунта на удалённой ноде
        PERFORM add_account_to_node(p_username, node.node_id);
    END LOOP;

    -- Добавление начального баланса для новой записи в account_balances
    PERFORM add_account_balance(new_account_id, p_initial_balance, p_node_id);

    RAISE NOTICE 'Account was added successfully with ID % and initial balance % on all nodes.', 
                new_account_id, p_initial_balance;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Transaction failed: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Эта функция добавляет аккаунт на указанную ноду
CREATE OR REPLACE FUNCTION add_account_to_node(
    p_username TEXT,
    p_node_id INT
)
RETURNS VOID AS $$
DECLARE
    conn_name TEXT;
BEGIN
    -- Удалённая вставка через dblink
    conn_name := connect_to_node(p_node_id);
    PERFORM execute_remote_query(
        conn_name,
        format(
            'INSERT INTO accounts (username) VALUES (%L);',
            p_username
        )
    );
    RAISE NOTICE 'Account % inserted on node %.', p_username, p_node_id;
    PERFORM disconnect_from_node(conn_name);
EXCEPTION WHEN OTHERS THEN
    -- Обеспечение отключения в случае ошибки
    IF conn_name IS NOT NULL THEN
        PERFORM disconnect_from_node(conn_name);
    END IF;
    RAISE;
END;
$$ LANGUAGE plpgsql;
