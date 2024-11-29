-- Создадим узел логической репликации
SELECT pglogical.create_node(
    node_name := 'node1',
    dsn := 'host=postgres1 dbname=shared_db user=admin password=password'
);

-- Настроим публикацию для общих таблиц
SELECT pglogical.create_replication_set(
    set_name := 'node1_set',
    replicate_insert := true,
    replicate_update := true,
    replicate_delete := true,
    replicate_truncate := false
);

SELECT pglogical.replication_set_add_table(
    set_name := 'node1_set',
    relation := 'account_balances',
    row_filter := 'node_id = 1' -- Только строки с node_id = 1
);
