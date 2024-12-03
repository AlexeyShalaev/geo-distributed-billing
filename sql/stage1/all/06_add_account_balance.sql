CREATE OR REPLACE FUNCTION add_account_balance(
    account_id INT,
    total_balance NUMERIC,
    local_node_id INT
)
RETURNS VOID AS $$
DECLARE
    node RECORD;                 -- Для итерации по узлам
    node_count INT;              -- Общее количество нод
    distributed_balance NUMERIC; -- Равномерный баланс для каждой ноды
    remainder NUMERIC;           -- Остаток, который будет добавлен одной ноде
    is_remainder_distributed BOOLEAN := FALSE; -- Флаг, указывает, был ли распределён остаток
    decrypted_dsn TEXT;          -- Расшифрованная строка подключения
    connections TEXT[] := ARRAY[]::TEXT[]; -- Список активных подключений
BEGIN
    -- Проверка наличия аккаунта с указанным account_id
    IF NOT EXISTS (
        SELECT 1 FROM accounts WHERE id = account_id
    ) THEN
        RAISE EXCEPTION 'Account with ID % does not exist.', account_id;
    END IF;

    -- Подсчитать количество нод
    SELECT COUNT(*) INTO node_count FROM node_config;

    IF node_count = 0 THEN
        RAISE EXCEPTION 'No nodes found in node_config.';
    END IF;

    -- Равномерное распределение баланса
    distributed_balance := FLOOR(total_balance / node_count);
    remainder := total_balance - (distributed_balance * node_count);

    -- Отладочный вывод: количество нод
    RAISE NOTICE 'Number of nodes: %', node_count;

    -- Начинаем транзакцию на всех нодах
    FOR node IN SELECT node_id, pgp_sym_decrypt(encrypted_dsn, get_encryption_key()) AS decrypted_dsn FROM node_config LOOP
        BEGIN
            -- Вывод информации о текущей ноде
            RAISE NOTICE 'Connecting to node %', node.node_id;

            -- Устанавливаем соединение через dblink
            PERFORM dblink_connect('conn_' || node.node_id, node.decrypted_dsn);
            connections := array_append(connections, 'conn_' || node.node_id);

            -- Открываем транзакцию
            PERFORM dblink_exec('conn_' || node.node_id, 'BEGIN');
        EXCEPTION WHEN OTHERS THEN
            RAISE EXCEPTION 'Failed to connect or start transaction on node %.', node.node_id;
        END;
    END LOOP;

    -- Вставляем данные
    FOR node IN SELECT node_id, pgp_sym_decrypt(encrypted_dsn, get_encryption_key()) AS decrypted_dsn FROM node_config LOOP
        BEGIN
            IF node.node_id = local_node_id THEN
                -- Добавляем запись на локальную ноду
                INSERT INTO account_balances (account_id, node_id, balance)
                VALUES (
                    account_id,
                    node.node_id,
                    distributed_balance + CASE 
                        WHEN NOT is_remainder_distributed THEN remainder
                        ELSE 0
                    END
                );

                -- Отмечаем, что остаток распределён
                is_remainder_distributed := TRUE;
            ELSE
                -- Добавляем запись на удалённую ноду через dblink
                PERFORM dblink_exec(
                    'conn_' || node.node_id,
                    'INSERT INTO account_balances (account_id, node_id, balance) ' ||
                    'VALUES (' || account_id || ', ' || node.node_id || ', ' ||
                    distributed_balance + CASE
                        WHEN NOT is_remainder_distributed THEN remainder
                        ELSE 0
                    END || ');'
                );

                -- Отмечаем, что остаток распределён
                is_remainder_distributed := TRUE;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            -- В случае ошибки откатываем транзакцию
            FOR i IN 1..array_length(connections, 1) LOOP
                PERFORM dblink_exec(connections[i], 'ROLLBACK');
                PERFORM dblink_disconnect(connections[i]);
            END LOOP;
            RAISE EXCEPTION 'Failed to insert account on node %. Rolling back all changes.', node.node_id;
        END;
    END LOOP;

    -- Завершаем транзакцию на всех нодах
    FOR i IN 1..array_length(connections, 1) LOOP
        BEGIN
            PERFORM dblink_exec(connections[i], 'COMMIT');
            PERFORM dblink_disconnect(connections[i]);
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Failed to commit or disconnect on connection %.', connections[i];
        END;
    END LOOP;

    RAISE NOTICE 'Account % successfully added with total balance %.', account_id, total_balance;

EXCEPTION WHEN OTHERS THEN
    -- Откат транзакции на всех нодах в случае общей ошибки
    FOR i IN 1..array_length(connections, 1) LOOP
        PERFORM dblink_exec(connections[i], 'ROLLBACK');
        PERFORM dblink_disconnect(connections[i]);
    END LOOP;
    RAISE EXCEPTION 'Transaction failed: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
