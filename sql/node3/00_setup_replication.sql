-- Установим расширение pglogical, если оно еще не установлено
CREATE EXTENSION IF NOT EXISTS pglogical;

-- Создадим узел логической репликации
SELECT pglogical.create_node(
    node_name := 'node3',
    dsn := 'host=postgres3 dbname=shared_db user=admin password=password'
);

-- Настроим подписку на публикацию от postgres1
SELECT pglogical.create_subscription(
    subscription_name := 'subscription_from_node1',
    provider_dsn := 'host=postgres1 dbname=shared_db user=admin password=password',
    replication_sets := ARRAY['default']
);
