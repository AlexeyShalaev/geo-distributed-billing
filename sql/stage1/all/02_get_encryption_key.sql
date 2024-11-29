CREATE OR REPLACE FUNCTION get_encryption_key()
RETURNS TEXT AS $$
BEGIN
    RETURN pg_read_file('/pgcrypto_key.txt');
END;
$$ LANGUAGE plpgsql;
