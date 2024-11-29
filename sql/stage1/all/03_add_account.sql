CREATE OR REPLACE FUNCTION add_account(
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
BEGIN
    -- Подсчитать количество нод
    SELECT COUNT(*) INTO node_count FROM node_config;

    -- Равномерное распределение баланса
    distributed_balance := FLOOR(total_balance / node_count);
    remainder := total_balance - (distributed_balance * node_count);

    -- Итерация по всем нодам
    FOR node IN SELECT * FROM node_config LOOP
        IF node.node_id = local_node_id THEN
            -- Добавляем запись на текущую ноду
            INSERT INTO account_balances (account_id, node_id, balance)
            VALUES (
                account_id,
                node.node_id,
                distributed_balance + CASE 
                    WHEN NOT is_remainder_distributed THEN remainder
                    ELSE 0
                END -- Добавляем остаток только один раз
            );

            -- Отмечаем, что остаток распределён
            is_remainder_distributed := TRUE;

            RAISE NOTICE 'Account % added locally on node % with balance %.',
                account_id, node.node_id,
                distributed_balance + CASE 
                    WHEN NOT is_remainder_distributed THEN remainder
                    ELSE 0
                END;
        ELSE
            -- Добавляем запись на удалённую ноду через dblink
            PERFORM dblink_exec(
                node.dsn,
                'INSERT INTO account_balances (account_id, node_id, balance) ' ||
                'VALUES (' || account_id || ', ' || node.node_id || ', ' ||
                distributed_balance + CASE
                    WHEN NOT is_remainder_distributed THEN remainder
                    ELSE 0
                END || ');'
            );

            -- Отмечаем, что остаток распределён
            is_remainder_distributed := TRUE;

            RAISE NOTICE 'Account % added remotely on node % with balance %.',
                account_id, node.node_id,
                distributed_balance + CASE 
                    WHEN NOT is_remainder_distributed THEN remainder
                    ELSE 0
                END;
        END IF;
    END LOOP;

    RAISE NOTICE 'Account % successfully added with total balance %.', account_id, total_balance;
END;
$$ LANGUAGE plpgsql;
