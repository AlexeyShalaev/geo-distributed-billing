SELECT pglogical.create_subscription(
    subscription_name := 'subscription_from_node1_to_node3',
    provider_dsn := 'host=postgres1 dbname=billing user=admin password=password',
    replication_sets := ARRAY['node1_set']
);

SELECT pglogical.create_subscription(
    subscription_name := 'subscription_from_node2_to_node3',
    provider_dsn := 'host=postgres2 dbname=billing user=admin password=password',
    replication_sets := ARRAY['node2_set']
);
