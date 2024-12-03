INSERT INTO node_config (node_id, encrypted_dsn)
VALUES
    (1, pgp_sym_encrypt('host=postgres1 dbname=billing user=admin password=password', get_encryption_key())),
    (2, pgp_sym_encrypt('host=postgres2 dbname=billing user=admin password=password', get_encryption_key())),
    (3, pgp_sym_encrypt('host=postgres3 dbname=billing user=admin password=password', get_encryption_key()));
