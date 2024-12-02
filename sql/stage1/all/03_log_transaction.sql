CREATE OR REPLACE FUNCTION log_transaction(
    p_account_id INT,
    p_node_id INT,
    p_operation_type TEXT,
    p_amount NUMERIC DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    -- Проверка наличия записи о балансе
    IF NOT EXISTS (
        SELECT 1 FROM account_balances
        WHERE account_id = p_account_id AND node_id = p_node_id
    ) THEN
        RAISE EXCEPTION 'No balance record found for account % on node %', p_account_id, p_node_id;
    END IF;

    -- Запись информации о транзакции в лог
    INSERT INTO transaction_log (account_id, node_id, operation_type, amount)
    VALUES (p_account_id, p_node_id, p_operation_type, p_amount);

    RAISE NOTICE 'Transaction logged: account_id=%, node_id=%, operation_type=%, amount=%.',
                 p_account_id, p_node_id, p_operation_type, p_amount;
END;
$$ LANGUAGE plpgsql;
