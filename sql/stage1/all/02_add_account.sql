CREATE OR REPLACE FUNCTION add_account(
    account_id INT,
    total_balance NUMERIC,
    local_node_id INT
)
RETURNS VOID AS $$
DECLARE
    node RECORD;                 -- Для итерации по узлам
    node_count INT;              -- Общее количество нод
    distributed_balance NUMERIC; -- Баланс для каждой ноды
    remainder NUMERIC;           -- Остаток баланса
BEGIN
    -- Подсчитать количество нод
    SELECT COUNT(*) INTO node_count FROM node_config;

    -- Распределить баланс
    distributed_balance := total_balance / node_count;
    remainder := MOD(total_balance, node_count); -- Остаток для равномерного распределения

    -- Итерация по всем нодам
    FOR node IN SELECT * FROM node_config LOOP
        IF node.node_id = local_node_id THEN
            -- Добавляем запись на текущую ноду
            INSERT INTO account_balances (account_id, node_id, balance)
            VALUES (
                account_id,
                node.node_id,
                distributed_balance + remainder -- Локальная нода получает остаток
            );

            RAISE NOTICE 'Account % added locally on node % with balance %.',
                account_id, node.node_id, distributed_balance + remainder;
        ELSE
            -- Добавляем запись на удалённую ноду через dblink
            PERFORM dblink_exec(
                node.dsn, -- Явная ссылка на поле "dsn" из таблицы "node_config"
                'INSERT INTO account_balances (account_id, node_id, balance) ' ||
                'VALUES (' || account_id || ', ' || node.node_id || ', ' ||
                distributed_balance || ');'
            );

            RAISE NOTICE 'Account % added remotely on node % with balance %.',
                account_id, node.node_id, distributed_balance;
        END IF;
    END LOOP;

    RAISE NOTICE 'Account % successfully added with total balance %.', account_id, total_balance;
END;
$$ LANGUAGE plpgsql;
