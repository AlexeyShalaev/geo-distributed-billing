CREATE OR REPLACE FUNCTION delete_account(account_id INT)
RETURNS VOID AS $$
BEGIN
    -- Проверяем, что аккаунт существует и не удалён
    IF EXISTS (
        SELECT 1 FROM accounts
        WHERE id = account_id AND is_deleted = FALSE
    ) THEN
        -- Помечаем аккаунт как удалённый
        UPDATE accounts
        SET is_deleted = TRUE
        WHERE id = account_id;
    
        RAISE NOTICE 'Account % has been marked as deleted.', account_id;
    ELSE
        RAISE EXCEPTION 'Account % does not exist or is already deleted.', account_id;
    END IF;
END;
$$ LANGUAGE plpgsql;
