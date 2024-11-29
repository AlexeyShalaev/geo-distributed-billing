-- Создадим узел логической репликации
SELECT pglogical.create_node(
    node_name := 'node1',
    dsn := 'host=postgres1 dbname=shared_db user=admin password=password'
);

-- Настроим публикацию для общих таблиц
SELECT pglogical.create_replication_set(
    set_name := 'default',
    replicate_insert := true,
    replicate_update := true,
    replicate_delete := true,
    replicate_truncate := false
);

-- Добавим таблицы к публикации
SELECT pglogical.replication_set_add_all_tables('default', ARRAY['public']);
