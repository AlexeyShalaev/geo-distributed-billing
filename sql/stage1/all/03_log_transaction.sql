CREATE OR REPLACE FUNCTION log_transaction(
    account_id INT,
    node_id INT,
    operation_type TEXT,
    amount NUMERIC DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    -- Запись информации о транзакции в лог
    INSERT INTO transaction_log (account_id, node_id, operation_type, amount)
    VALUES (account_id, node_id, operation_type, amount);

    RAISE NOTICE 'Transaction logged: account_id=%, node_id=%, operation_type=%, amount=%.',
                 account_id, node_id, operation_type, amount;
END;
$$ LANGUAGE plpgsql;
