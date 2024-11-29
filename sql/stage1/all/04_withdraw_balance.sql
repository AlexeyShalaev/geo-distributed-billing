CREATE OR REPLACE FUNCTION withdraw_balance(account_id INT, amount NUMERIC, local_node_id INT)
RETURNS VOID AS $$
DECLARE
    local_balance NUMERIC;                 -- Локальный баланс
    total_balance NUMERIC;                 -- Суммарный баланс по всем нодам
    needed_balance NUMERIC;                -- Необходимая сумма для снятия
    node_balances RECORD;                  -- Запись для итерации по другим узлам
    remote_dsn TEXT;                       -- Строка подключения к узлу
BEGIN
    -- Получаем локальный баланс
    SELECT balance INTO local_balance
    FROM account_balances
    WHERE account_balances.account_id = withdraw_balance.account_id
      AND account_balances.node_id = withdraw_balance.local_node_id;

    -- Проверяем локальный баланс
    IF local_balance >= amount THEN
        -- Если хватает, снимаем локально
        UPDATE account_balances
        SET balance = balance - amount
        WHERE account_balances.account_id = withdraw_balance.account_id
          AND account_balances.node_id = withdraw_balance.local_node_id;

        RAISE NOTICE 'Withdrawn % from local balance on node %. Replication will sync changes.', amount, local_node_id;
        RETURN;
    END IF;

    -- Если не хватает локально, проверяем суммарный баланс
    SELECT SUM(balance) INTO total_balance
    FROM account_balances
    WHERE account_balances.account_id = withdraw_balance.account_id;

    -- Если суммарного баланса недостаточно
    IF total_balance < amount THEN
        RAISE EXCEPTION 'Insufficient funds';
    END IF;

    -- Определяем необходимую сумму для снятия
    needed_balance := amount - local_balance;

    -- Обнуляем локальный баланс
    UPDATE account_balances
    SET balance = 0
    WHERE account_balances.account_id = withdraw_balance.account_id
      AND account_balances.node_id = withdraw_balance.local_node_id;

    -- Итерация по другим узлам и отправка запросов
    FOR node_balances IN
        SELECT node_id, balance
        FROM account_balances
        WHERE account_balances.account_id = withdraw_balance.account_id
          AND account_balances.node_id <> withdraw_balance.local_node_id
    LOOP
        -- Получаем строку подключения для узла
        SELECT node_config.dsn INTO remote_dsn
        FROM node_config
        WHERE node_config.node_id = node_balances.node_id;

        -- Рассчитываем долю для снятия
        PERFORM dblink_exec(
            remote_dsn,
            'UPDATE account_balances ' ||
            'SET balance = balance - ' || needed_balance * (node_balances.balance / (total_balance - local_balance)) ||
            ' WHERE account_id = ' || withdraw_balance.account_id || ' AND node_id = ' || node_balances.node_id || ';'
        );

        RAISE NOTICE 'Sent withdraw request to node %.', node_balances.node_id;
    END LOOP;

    RAISE NOTICE 'Withdrawn %. Requests sent to other nodes.', amount;

END;
$$ LANGUAGE plpgsql;
