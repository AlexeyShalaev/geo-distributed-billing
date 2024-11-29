-- Переключение на базу данных billing
\c billing

SELECT add_account(1, 1000, 1);
SELECT add_account(2, 2000, 1);
SELECT add_account(3, 3000, 1);
