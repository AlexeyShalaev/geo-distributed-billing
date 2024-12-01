-- Запрет на отрицательный баланс
CREATE OR REPLACE FUNCTION prevent_negative_balance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.balance < 0 THEN
        RAISE EXCEPTION 'Balance cannot be negative for account % on node %', NEW.account_id, NEW.node_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_negative_balance
BEFORE INSERT OR UPDATE ON account_balances
FOR EACH ROW EXECUTE FUNCTION prevent_negative_balance();

-- Запрет на прямое удаление аккаунта
CREATE OR REPLACE FUNCTION prevent_account_deletion()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Direct deletion from accounts is not allowed. Use the delete_account function.';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_account_deletion
BEFORE DELETE ON accounts
FOR EACH ROW
EXECUTE FUNCTION prevent_account_deletion();

-- Запрет на операции с удалёнными аккаунтами
CREATE OR REPLACE FUNCTION prevent_operations_on_deleted_accounts()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM accounts
        WHERE id = NEW.account_id AND is_deleted = TRUE
    ) THEN
        RAISE EXCEPTION 'Cannot perform operation on deleted account %.', NEW.account_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_operations_on_deleted_accounts_account_balances
BEFORE INSERT OR UPDATE ON account_balances
FOR EACH ROW
EXECUTE FUNCTION prevent_operations_on_deleted_accounts();

CREATE TRIGGER trg_prevent_operations_on_deleted_accounts_transaction_log
BEFORE INSERT OR UPDATE ON transaction_log
FOR EACH ROW
EXECUTE FUNCTION prevent_operations_on_deleted_accounts();
