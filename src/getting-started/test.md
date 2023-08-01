# Test the contracts

Open a terminal and run the following command:

```shell
snforge
```

This will execute the tests in `tests` directory and print the results.

Sample output:

```shell
Collected 4 test(s) and 3 test file(s)
Running 0 test(s) from src/lib.cairo
Running 2 test(s) from tests/data/test_data_store.cairo
[PASS] test_data_store::test_data_store::test_get_and_set_felt252
[PASS] test_data_store::test_data_store::test_get_and_set_u256
Running 2 test(s) from tests/role/test_role_store.cairo
[PASS] test_role_store::test_role_store::test_grant_role
[PASS] test_role_store::test_role_store::test_revoke_role
Tests: 4 passed, 0 failed, 0 skipped
```
