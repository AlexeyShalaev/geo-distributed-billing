-- Переключение на базу данных billing
\c billing

SELECT add_account_balance(add_account('Aleksandrov'), 1000, 1);
SELECT add_account_balance(add_account('Pavlichev'), 2000, 1);
SELECT add_account_balance(add_account('Shalaev'), 3000, 1);
