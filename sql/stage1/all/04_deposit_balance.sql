CREATE OR REPLACE FUNCTION deposit_balance(account_id INT, amount NUMERIC, local_node_id INT)
RETURNS VOID AS $$
BEGIN
    -- Увеличиваем баланс для текущей ноды
    UPDATE account_balances
    SET balance = balance + amount
    WHERE account_balances.account_id = deposit_balance.account_id
      AND account_balances.node_id = deposit_balance.local_node_id;

    -- Логируем транзакцию
    PERFORM log_transaction(account_id, local_node_id, 'deposit', amount);

    -- Репликация выполнится автоматически через pglogical
    RAISE NOTICE 'Balance updated locally on node % and changes will replicate asynchronously.', local_node_id;
END;
$$ LANGUAGE plpgsql;
