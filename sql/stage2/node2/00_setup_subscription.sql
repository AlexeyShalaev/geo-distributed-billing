SELECT pglogical.create_subscription(
    subscription_name := 'subscription_from_node1_to_node2',
    provider_dsn := 'host=postgres1 dbname=shared_db user=admin password=password',
    replication_sets := ARRAY['default']
);

SELECT pglogical.create_subscription(
    subscription_name := 'subscription_from_node3_to_node2',
    provider_dsn := 'host=postgres3 dbname=shared_db user=admin password=password',
    replication_sets := ARRAY['default']
);
