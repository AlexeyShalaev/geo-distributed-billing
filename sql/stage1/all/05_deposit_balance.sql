CREATE OR REPLACE FUNCTION deposit_balance(p_account_id INT, p_amount NUMERIC, p_node_id INT)
RETURNS VOID AS $$
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
        RAISE EXCEPTION 'Deposit amount must be positive';
    END IF;

    -- Увеличиваем баланс для текущей ноды
    UPDATE account_balances
    SET balance = balance + p_amount
    WHERE account_id = p_account_id
      AND node_id = p_node_id;

    -- Логируем транзакцию
    PERFORM log_transaction(p_account_id, p_node_id, 'deposit', p_amount);

    -- Репликация выполнится автоматически через pglogical
    RAISE NOTICE 'Balance updated locally on node % and changes will replicate asynchronously.', p_node_id;
END;
$$ LANGUAGE plpgsql;
