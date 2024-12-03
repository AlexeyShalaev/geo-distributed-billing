CREATE OR REPLACE FUNCTION delete_account(p_account_id INT)
RETURNS VOID AS $$
BEGIN
    -- Проверяем, что аккаунт существует и не удалён
    IF EXISTS (
        SELECT 1 FROM accounts
        WHERE id = p_account_id AND is_deleted = FALSE
    ) THEN
        -- Помечаем аккаунт как удалённый
        UPDATE accounts
        SET is_deleted = TRUE
        WHERE id = p_account_id;
    
        RAISE NOTICE 'Account % has been marked as deleted.', p_account_id;
    ELSE
        RAISE EXCEPTION 'Account % does not exist or is already deleted.', p_account_id;
    END IF;
END;
$$ LANGUAGE plpgsql;
