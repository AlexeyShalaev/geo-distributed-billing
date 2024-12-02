CREATE OR REPLACE FUNCTION add_account(
    p_username TEXT,            -- Имя пользователя
    p_initial_balance NUMERIC,  -- Начальный баланс
    p_node_id INT               -- Локальная нода для баланса
)
RETURNS VOID AS $$
DECLARE
    new_account_id INT;         -- ID нового аккаунта
    node RECORD;                -- Для итерации по нодам
    conn_name TEXT;             -- Имя подключения
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

    RAISE NOTICE 'Local account created with ID %.', new_account_id;

    -- Распространение аккаунта на все удалённые ноды через dblink
    FOR node IN 
        SELECT node_id, pgp_sym_decrypt(encrypted_dsn::bytea, get_encryption_key()) AS decrypted_dsn 
        FROM node_config
    LOOP
        -- Пропуск локальной ноды, так как аккаунт уже создан
        IF node.node_id = p_node_id THEN
            CONTINUE;
        END IF;

        -- Проверка корректности decrypted_dsn
        IF node.decrypted_dsn IS NULL OR TRIM(node.decrypted_dsn) = '' THEN
            RAISE EXCEPTION 'Decrypted DSN for node % is invalid.', node.node_id;
        END IF;

        -- Установка соединения через dblink
        BEGIN
            -- Отключение, если соединение с таким именем уже существует
            BEGIN
                PERFORM dblink_disconnect('conn_' || node.node_id);
            EXCEPTION WHEN OTHERS THEN
                -- Игнорировать ошибку, если соединение не существует
            END;

            PERFORM dblink_connect('conn_' || node.node_id, node.decrypted_dsn);
            RAISE NOTICE 'Connected to node %.', node.node_id;

            -- Вставка аккаунта на удалённом узле
            PERFORM dblink_exec(
                'conn_' || node.node_id,
                format(
                    'INSERT INTO accounts (username) VALUES (%L);',
                    p_username
                )
            );
            RAISE NOTICE 'Account % inserted on node %.', p_username, node.node_id;

            -- Отключение после вставки
            PERFORM dblink_disconnect('conn_' || node.node_id);
            RAISE NOTICE 'Disconnected from node %.', node.node_id;
        EXCEPTION WHEN OTHERS THEN
            -- Откат транзакции при ошибке и отключение
            PERFORM dblink_disconnect('conn_' || node.node_id);
            RAISE EXCEPTION 'Failed to connect or insert account on node %. Details: %', node.node_id, SQLERRM;
        END;
    END LOOP;

    -- Добавление начального баланса для новой записи в account_balances
    PERFORM add_account_balance(new_account_id, p_initial_balance, p_node_id);

    RAISE NOTICE 'Account was added successfully with ID % and initial balance % on node %.', 
                new_account_id, p_initial_balance, p_node_id;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Transaction failed: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
