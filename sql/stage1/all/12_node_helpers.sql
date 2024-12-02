-- Эта функция получает расшифрованную строку подключения для заданной ноды
CREATE OR REPLACE FUNCTION get_decrypted_dsn(p_node_id INT)
RETURNS TEXT AS $$
BEGIN
    RETURN (
        SELECT pgp_sym_decrypt(encrypted_dsn::bytea, get_encryption_key())
        FROM node_config
        WHERE node_id = p_node_id
    );
END;
$$ LANGUAGE plpgsql;

-- Эта функция устанавливает соединение с указанной нодой и возвращает имя соединения
CREATE OR REPLACE FUNCTION connect_to_node(p_node_id INT)
RETURNS TEXT AS $$
DECLARE
    conn_name TEXT := 'conn_' || p_node_id;
    dsn TEXT;
BEGIN
    dsn := get_decrypted_dsn(p_node_id);
    
    IF dsn IS NULL OR TRIM(dsn) = '' THEN
        RAISE EXCEPTION 'Decrypted DSN for node % is invalid.', p_node_id;
    END IF;
    
    -- Отключение существующего соединения с таким же именем, если оно есть
    BEGIN
        PERFORM dblink_disconnect(conn_name);
    EXCEPTION WHEN OTHERS THEN
        -- Игнорировать ошибку, если соединение не существует
    END;
    
    PERFORM dblink_connect(conn_name, dsn);
    RAISE NOTICE 'Connected to node % with connection name %.', p_node_id, conn_name;
    RETURN conn_name;
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to connect to node %. Details: %', p_node_id, SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Эта функция отключает соединение с заданной нодой
CREATE OR REPLACE FUNCTION disconnect_from_node(p_conn_name TEXT)
RETURNS VOID AS $$
BEGIN
    PERFORM dblink_disconnect(p_conn_name);
    RAISE NOTICE 'Disconnected from connection %.', p_conn_name;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Failed to disconnect from connection %.', p_conn_name;
END;
$$ LANGUAGE plpgsql;

-- Эта функция выполняет заданный SQL-запрос на удалённой ноде через dblink
CREATE OR REPLACE FUNCTION execute_remote_query(p_conn_name TEXT, p_query TEXT)
RETURNS VOID AS $$
BEGIN
    PERFORM dblink_exec(p_conn_name, p_query);
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to execute remote query on connection %. Details: %', p_conn_name, SQLERRM;
END;
$$ LANGUAGE plpgsql;

