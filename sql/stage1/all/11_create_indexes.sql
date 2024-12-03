-- Таблица account_balances
CREATE INDEX idx_account_balances_account_id ON account_balances (account_id);

-- Таблица transaction_log
CREATE INDEX idx_transaction_log_account_id ON transaction_log (account_id);
CREATE INDEX idx_transaction_log_created_at ON transaction_log (created_at);
