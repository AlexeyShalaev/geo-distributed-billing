CREATE OR REPLACE FUNCTION log_transaction(
    account_id INT,
    node_id INT,
    operation_type TEXT,
    amount NUMERIC DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    -- Проверка наличия записи о балансе
    IF NOT EXISTS (
        SELECT 1 FROM account_balances
        WHERE account_id = account_id AND node_id = node_id
    ) THEN
        RAISE EXCEPTION 'No balance record found for account % on node %', account_id, node_id;
    END IF;

    -- Запись информации о транзакции в лог
    INSERT INTO transaction_log (account_id, node_id, operation_type, amount)
    VALUES (account_id, node_id, operation_type, amount);

    RAISE NOTICE 'Transaction logged: account_id=%, node_id=%, operation_type=%, amount=%.',
                 account_id, node_id, operation_type, amount;
END;
$$ LANGUAGE plpgsql;
