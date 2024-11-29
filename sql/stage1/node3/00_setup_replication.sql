-- Создадим узел логической репликации
SELECT pglogical.create_node(
    node_name := 'node3',
    dsn := 'host=postgres3 dbname=billing user=admin password=password'
);

-- Настроим публикацию для общих таблиц
SELECT pglogical.create_replication_set(
    set_name := 'node3_set',
    replicate_insert := true,
    replicate_update := true,
    replicate_delete := true,
    replicate_truncate := false
);

SELECT pglogical.replication_set_add_table(
    set_name := 'node3_set',
    relation := 'account_balances',
    row_filter := 'node_id = 3'
);
