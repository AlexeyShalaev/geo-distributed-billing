SELECT pglogical.create_subscription(
    subscription_name := 'subscription_from_node2_to_node1',
    provider_dsn := 'host=postgres2 dbname=shared_db user=admin password=password',
    replication_sets := ARRAY['node2_set']
);

SELECT pglogical.create_subscription(
    subscription_name := 'subscription_from_node3_to_node1',
    provider_dsn := 'host=postgres3 dbname=shared_db user=admin password=password',
    replication_sets := ARRAY['node3_set']
);
