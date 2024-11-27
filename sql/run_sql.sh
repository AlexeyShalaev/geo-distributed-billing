#!/bin/bash

# Настройки подключения
declare -A nodes=(
    [node1]="postgres1 5432 admin password shared_db"
    [node2]="postgres2 5432 admin password shared_db"
    [node3]="postgres3 5432 admin password shared_db"
)

# Функция для выполнения SQL-файлов
execute_sql() {
    local node=$1
    local dsn=($2)  # Разбиваем строку подключения в массив
    local dir=$3

    local host=${dsn[0]}
    local port=${dsn[1]}
    local user=${dsn[2]}
    local password=${dsn[3]}
    local dbname=${dsn[4]}

    echo "Executing SQL scripts in $dir for $node..."
    for sql_file in "$dir"/*.sql; do
        if [[ -f "$sql_file" ]]; then
            echo "Running $sql_file on $node..."
            PGPASSWORD=$password psql -h $host -p $port -U $user -d $dbname -f "$sql_file" \
                || { echo "Error executing $sql_file on $node. Exiting."; exit 1; }
        fi
    done
}

# Выполнение общих скриптов (только на node1)
if [[ -d "./shared" ]]; then
    execute_sql "node1" "${nodes[node1]}" "./shared"
fi

# Выполнение уникальных скриптов для каждой ноды
for node in "${!nodes[@]}"; do
    if [[ -d "./$node" ]]; then
        execute_sql "$node" "${nodes[$node]}" "./$node"
    fi
done

echo "All SQL scripts executed successfully."