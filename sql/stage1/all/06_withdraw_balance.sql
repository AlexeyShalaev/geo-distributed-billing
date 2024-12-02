CREATE OR REPLACE FUNCTION withdraw_balance(p_account_id INT, p_amount NUMERIC, p_node_id INT)
RETURNS VOID AS $$
DECLARE
    local_balance NUMERIC;                 -- Локальный баланс
    total_balance NUMERIC;                 -- Суммарный баланс по всем нодам
    needed_balance NUMERIC;                -- Необходимая сумма для снятия
    node_balances RECORD;                  -- Запись для итерации по другим узлам
    remote_dsn TEXT;                       -- Расшифрованная строка подключения к узлу
BEGIN
    -- Проверяем, что запись о балансе существует
    IF NOT EXISTS (
        SELECT 1 FROM account_balances
        WHERE account_id = p_account_id AND node_id = p_node_id
    ) THEN
        RAISE EXCEPTION 'No balance record found for account % on node %', p_account_id, p_node_id;
    END IF;

    -- Проверяем, что сумма положительна
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Withdrawal amount must be positive';
    END IF;

    -- Получаем локальный баланс
    SELECT balance INTO local_balance
    FROM account_balances
    WHERE account_balances.account_id = p_account_id
      AND account_balances.node_id = p_node_id;

    -- Проверяем локальный баланс
    IF local_balance >= p_amount THEN
        -- Если хватает, снимаем локально
        UPDATE account_balances
        SET balance = balance - p_amount
        WHERE account_balances.account_id = p_account_id
          AND account_balances.node_id = p_node_id;

        -- Логируем транзакцию
        PERFORM log_transaction(p_account_id, p_node_id, 'withdraw', p_amount);

        RAISE NOTICE 'Withdrawn % from local balance on node %. Replication will sync changes.', p_amount, p_node_id;
        RETURN;
    END IF;

    -- Если не хватает локально, проверяем суммарный баланс
    SELECT SUM(balance) INTO total_balance
    FROM account_balances
    WHERE account_balances.account_id = p_account_id;

    -- Если суммарного баланса недостаточно
    IF total_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient funds';
    END IF;

    -- Определяем необходимую сумму для снятия
    needed_balance := p_amount - local_balance;

    -- Обнуляем локальный баланс
    UPDATE account_balances
    SET balance = 0
    WHERE account_balances.account_id = p_account_id
      AND account_balances.node_id = p_node_id;

    -- Итерация по другим узлам и отправка запросов
    FOR node_balances IN
        SELECT node_id, balance
        FROM account_balances
        WHERE account_balances.account_id = p_account_id
          AND account_balances.node_id <> p_node_id
    LOOP
        -- Расшифровываем строку подключения для узла
        SELECT pgp_sym_decrypt(node_config.encrypted_dsn::bytea, get_encryption_key()) INTO remote_dsn
        FROM node_config
        WHERE node_config.node_id = node_balances.node_id;

        -- Рассчитываем долю для снятия
        PERFORM dblink_exec(
            remote_dsn,
            'UPDATE account_balances ' ||
            'SET balance = balance - ' || needed_balance * (node_balances.balance / (total_balance - local_balance)) ||
            ' WHERE account_id = ' || p_account_id || ' AND node_id = ' || node_balances.node_id || ';'
        );

        RAISE NOTICE 'Sent withdraw request to node %.', node_balances.node_id;
    END LOOP;

    -- Логируем транзакцию после завершения
    PERFORM log_transaction(p_account_id, p_node_id, 'withdraw', p_amount);

    RAISE NOTICE 'Withdrawn %. Requests sent to other nodes.', p_amount;

END;
$$ LANGUAGE plpgsql;
