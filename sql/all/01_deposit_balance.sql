CREATE OR REPLACE FUNCTION deposit_balance(account_id INT, amount NUMERIC, local_node_id INT)
RETURNS VOID AS $$
BEGIN
    -- Увеличиваем баланс для текущей ноды
    UPDATE account_balances
    SET balance = balance + amount
    WHERE account_id = account_id AND node_id = local_node_id;

    -- Репликация выполнится автоматически через pglogical
    RAISE NOTICE 'Balance updated locally on node % and changes will replicate asynchronously.', local_node_id;
END;
$$ LANGUAGE plpgsql;
