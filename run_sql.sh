#!/bin/bash

set -e  # Останавливаем выполнение при ошибке

# Подключение к PostgreSQL
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_USER=${DB_USER:-postgres}
DB_PASSWORD=${DB_PASSWORD:-password}
DB_NAME=${DB_NAME:-shared_db}

# Функция выполнения SQL-файлов
execute_sql_files() {
    local dir=$1

    echo "Executing SQL scripts in $dir..."
    for sql_file in "$dir"/*.sql; do
        if [[ -f "$sql_file" ]]; then
            echo "Running $sql_file..."
            PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$sql_file" \
                || { echo "Error executing $sql_file. Exiting."; exit 1; }
        fi
    done
}

# Выполняем общие скрипты для node1
if [[ "$DB_HOST" == "postgres1" ]] && [[ -d "/scripts/sql/shared" ]]; then
    execute_sql_files "/scripts/sql/shared"
fi

# Выполняем уникальные скрипты для текущей ноды
if [[ -d "/scripts/sql/$DB_HOST" ]]; then
    execute_sql_files "/scripts/sql/$DB_HOST"
fi

echo "SQL execution completed for $DB_HOST."
