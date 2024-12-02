CREATE OR REPLACE FUNCTION add_account_balance(
    p_account_id INT,
    p_total_balance NUMERIC,
    p_node_id INT
)
RETURNS VOID AS $$
DECLARE
    node RECORD;                 -- Для итерации по узлам
    node_count INT;              -- Общее количество нод
    distributed_balance NUMERIC; -- Равномерный баланс для каждой ноды
    remainder NUMERIC;           -- Остаток, который будет добавлен одной ноде
    is_remainder_distributed BOOLEAN := FALSE; -- Флаг, указывает, был ли распределён остаток
BEGIN
    -- Проверка наличия аккаунта с указанным p_account_id
    IF NOT EXISTS (
        SELECT 1 FROM accounts WHERE id = p_account_id
    ) THEN
        RAISE EXCEPTION 'Account with ID % does not exist.', p_account_id;
    END IF;

    -- Подсчитать количество нод
    SELECT COUNT(*) INTO node_count FROM node_config;

    -- Равномерное распределение баланса
    distributed_balance := FLOOR(p_total_balance / node_count);
    remainder := p_total_balance - (distributed_balance * node_count);

    -- Распределение баланса на все ноды
    FOR node IN 
        SELECT node_id FROM node_config
    LOOP
        BEGIN
            IF node.node_id = p_node_id THEN
                -- Локальная нода
                PERFORM add_account_balance_to_node(p_account_id, node.node_id, distributed_balance + (CASE WHEN NOT is_remainder_distributed THEN remainder ELSE 0 END));
            ELSE
                -- Удалённая нода
                PERFORM add_account_balance_to_node(p_account_id, node.node_id, distributed_balance + (CASE WHEN NOT is_remainder_distributed THEN remainder ELSE 0 END));
            END IF;
            is_remainder_distributed := TRUE; -- Остаток распределён
        EXCEPTION WHEN OTHERS THEN
            -- Обработка ошибок
            RAISE EXCEPTION 'Failed to add balance on node %. Details: %', node.node_id, SQLERRM;
        END;
    END LOOP;

    RAISE NOTICE 'Account balance of account with id % successfully added with total balance %.', p_account_id, p_total_balance;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Transaction failed: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Эта функция добавляет баланс аккаунта на указанную ноду
CREATE OR REPLACE FUNCTION add_account_balance_to_node(
    p_account_id INT,
    p_node_id INT,
    p_balance NUMERIC
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
            'INSERT INTO account_balances (account_id, node_id, balance) VALUES (%L, %L, %L);',
            p_account_id,
            p_node_id,
            p_balance
        )
    );
    RAISE NOTICE 'Balance % inserted for account ID % on node %.', p_balance, p_account_id, p_node_id;
    PERFORM disconnect_from_node(conn_name);
EXCEPTION WHEN OTHERS THEN
    -- Обеспечение отключения в случае ошибки
    IF conn_name IS NOT NULL THEN
        PERFORM disconnect_from_node(conn_name);
    END IF;
    RAISE;
END;
$$ LANGUAGE plpgsql;
