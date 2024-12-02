-- Переключение на базу данных billing
\c billing

SELECT add_account('user1', 1000, 1);
SELECT add_account('user2', 2000, 1);
SELECT add_account('user3', 3000, 1);
