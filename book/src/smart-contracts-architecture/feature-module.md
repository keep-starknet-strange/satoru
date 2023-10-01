# Feature Module

The Feature Module checks if different parts of the system are turned on or off. It’s really important for keeping the system stable and working correctly.

It encompasses the following smart contracts:
- [feature_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/feature/feature_utils.cairo): Central to the module, this contract is responsible for validating the operational status of a feature, determining whether it is enabled or disabled.

## ⚠️ Warning
Disabling a feature should be performed with extreme caution and only in absolutely necessary situations, as it can lead to unexpected and potentially harmful effects, such as operational discrepancies and system instability.

## Functions

### `is_feature_disabled`

```cairo
fn is_feature_disabled(data_store: IDataStoreDispatcher, key: felt252) -> bool
```

- **Objective:** Determines the operational status of a specified feature.
- **Parameters:**
    - `data_store`: The data storage contract dispatcher, facilitating interaction with stored data.
    - `key`: The feature key representing the specific feature in question.
- **Returns:** A boolean indicating whether the feature is disabled.

### `validate_feature`

```cairo
fn validate_feature(data_store: IDataStoreDispatcher, key: felt252)
```

- **Objective:** Validates the operational status of a specified feature and reverts the operation if the feature is disabled.
- **Parameters:**
    - `data_store`: The data storage contract dispatcher.
    - `key`: The feature key representing the specific feature in question.
- **Implications:** Essential for maintaining system integrity by halting operations related to disabled features.

## Errors

### `FeatureError`

- **DISABLED_FEATURE:** This error is triggered when an attempt is made to operate a disabled feature, indicating a breach in feature utilization protocols.