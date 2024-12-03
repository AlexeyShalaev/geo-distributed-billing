CREATE OR REPLACE FUNCTION add_account(
    p_username TEXT            -- Имя пользователя
)
RETURNS INT AS $$
DECLARE
    new_account_id INT;
BEGIN
    -- Проверка имени пользователя
    IF p_username IS NULL OR TRIM(p_username) = '' THEN
        RAISE EXCEPTION 'Username cannot be null or empty.';
    END IF;

    -- Создание нового аккаунта на локальном узле
    INSERT INTO accounts (username)
    VALUES (p_username)
    RETURNING id INTO new_account_id;

    -- Проверка, что аккаунт был создан
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Account with username % already exists.', p_username;
    END IF;

    RAISE NOTICE 'Account was added successfully with ID %.', 
                new_account_id;
                
    RETURN new_account_id;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Transaction failed: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
