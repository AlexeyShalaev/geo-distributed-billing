-- Установка расширения pglogical
CREATE EXTENSION IF NOT EXISTS pglogical;

-- Подписка на узлы
DO $$ 
BEGIN
    IF (SELECT COUNT(*) FROM pglogical.node WHERE node_name = 'node1') = 0 THEN
        SELECT pglogical.create_node(node_name := 'node1', dsn := 'host=ru-central1-a dbname=shared_db user=admin password=password');
    END IF;

    IF (SELECT COUNT(*) FROM pglogical.node WHERE node_name = 'node2') = 0 THEN
        SELECT pglogical.create_node(node_name := 'node2', dsn := 'host=us-gov-east-1 dbname=shared_db user=admin password=password');
    END IF;

    IF (SELECT COUNT(*) FROM pglogical.node WHERE node_name = 'node3') = 0 THEN
        SELECT pglogical.create_node(node_name := 'node3', dsn := 'host=eu-west-2 dbname=shared_db user=admin password=password');
    END IF;
END $$;

-- Настройка репликации для общих таблиц
DO $$
BEGIN
    PERFORM pglogical.create_subscription(
        subscription_name := 'common_tables_subscription',
        provider_dsn := 'host=ru-central1-a dbname=shared_db user=admin password=password'
    );
END $$;
