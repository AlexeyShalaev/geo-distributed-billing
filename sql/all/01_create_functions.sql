CREATE OR REPLACE FUNCTION deposit_balance(account_id INT, amount NUMERIC)
RETURNS VOID AS $$
DECLARE
    local_node_id INT;
BEGIN
    -- Определяем ID текущего узла
    SELECT node_id INTO local_node_id
    FROM account_balances
    WHERE write_permission = TRUE LIMIT 1;

    -- Увеличиваем баланс локально
    UPDATE account_balances
    SET balance = balance + amount
    WHERE account_id = account_id AND write_permission = TRUE;

    -- Репликация выполнится автоматически через pglogical
    RAISE NOTICE 'Balance updated locally and changes will replicate asynchronously.';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION withdraw_balance(account_id INT, amount NUMERIC)
RETURNS VOID AS $$
DECLARE
    local_node_id INT;                     -- ID текущего узла
    local_balance NUMERIC;                 -- Локальный баланс
    total_balance NUMERIC;                 -- Суммарный баланс по всем узлам
    needed_balance NUMERIC;                -- Необходимая сумма для снятия
    node_balances RECORD;                  -- Запись для итерации по другим узлам
    balance_ratio NUMERIC;                 -- Доля для снятия с конкретного узла
BEGIN
    -- Получаем ID текущего узла
    SELECT node_id INTO local_node_id
    FROM account_balances
    WHERE account_id = account_id AND write_permission = TRUE;

    -- Получаем локальный баланс
    SELECT balance INTO local_balance
    FROM account_balances
    WHERE account_id = account_id AND node_id = local_node_id;

    -- Проверяем локальный баланс
    IF local_balance >= amount THEN
        -- Если хватает, снимаем локально
        UPDATE account_balances
        SET balance = balance - amount
        WHERE account_id = account_id AND node_id = local_node_id;

        RAISE NOTICE 'Withdrawn % from local balance. Replication will sync changes.', amount;
        RETURN;
    END IF;

    -- Если не хватает локально, проверяем суммарный баланс
    SELECT SUM(balance) INTO total_balance
    FROM account_balances
    WHERE account_id = account_id;

    -- Если суммарного баланса недостаточно
    IF total_balance < amount THEN
        RAISE EXCEPTION 'Insufficient funds';
    END IF;

    -- Определяем необходимую сумму для снятия
    needed_balance := amount - local_balance;

    -- Обнуляем локальный баланс
    UPDATE account_balances
    SET balance = 0
    WHERE account_id = account_id AND node_id = local_node_id;

    -- Итерация по другим узлам и пропорциональное распределение
    FOR node_balances IN
        SELECT node_id, balance
        FROM account_balances
        WHERE account_id = account_id AND node_id <> local_node_id
    LOOP
        -- Рассчитываем долю для снятия с текущего узла
        balance_ratio := needed_balance * (node_balances.balance / (total_balance - local_balance));

        -- Уменьшаем баланс на текущем узле
        UPDATE account_balances
        SET balance = balance - balance_ratio
        WHERE account_id = account_id AND node_id = node_balances.node_id;

        RAISE NOTICE 'Withdrawn % from node %. Remaining balance: %',
            balance_ratio, node_balances.node_id, node_balances.balance - balance_ratio;
    END LOOP;

    RAISE NOTICE 'Total amount withdrawn: %. Replication will sync changes.', amount;

END;
$$ LANGUAGE plpgsql;
