#!/bin/bash

# Настройки подключения
declare -A nodes=(
    [node1]="host=ru-central1-a port=5432 user=admin password=password dbname=shared_db"
    [node2]="host=us-gov-east-1 port=5432 user=admin password=password dbname=shared_db"
    [node3]="host=eu-west-2 port=5432 user=admin password=password dbname=shared_db"
)

# Функция для выполнения SQL-файлов
execute_sql() {
    local node=$1
    local dsn=$2
    local dir=$3

    echo "Executing SQL scripts in $dir for $node..."
    for sql_file in "$dir"/*.sql; do
        if [[ -f "$sql_file" ]]; then
            echo "Running $sql_file on $node..."
            PGPASSWORD=${dsn#*password=} psql -h ${dsn%% *} -p ${dsn#*port=}; d=${d%% *}; d=shared_db \
                -U ${dsn#*user=} -f "$sql_file" \
                || { echo "Error executing $sql_file on $node. Exiting."; exit 1; }
        fi
    done
}

# Выполнение общих скриптов (только на node1)
if [[ -d "sql/shared" ]]; then
    execute_sql "node1" "${nodes[node1]}" "sql/shared"
fi

# Выполнение уникальных скриптов для каждой ноды
for node in "${!nodes[@]}"; do
    if [[ -d "sql/$node" ]]; then
        execute_sql "$node" "${nodes[$node]}" "sql/$node"
    fi
done

echo "All SQL scripts executed successfully."

