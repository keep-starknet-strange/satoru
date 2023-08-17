## Test Workflow Documentation

### Overview:
The "Test" GitHub Actions workflow (`test.yml`) ensures the code's integrity by validating its functionality. It aims to detect any potential issues introduced by new code modifications, guaranteeing that they do not impact the existing codebase.

### Workflow Details:

**Workflow Name:** Test

**Trigger Conditions:**
1. **Push Event:** Activated when changes are pushed to the `main` branch.
2. **Pull Request Event:** Triggered for pull requests targeting the `main` branch.

**Environment Variables:**
- **SCARB_VERSION:** Specifies the Scarb version, currently set to `0.6.1+nightly-2023-08-16`.
- **STARKNET_FOUNDRY_VERSION:** Defines the version of Starknet Foundry, currently set to `0.3.0`.

**Jobs:**
1. **Test & Check Job**:
   - **Environment:** Latest version of Ubuntu.
   - **Steps:**
     1. **Checkout Repository**: Retrieves the contents of the repository.
     2. **Set up Scarb**: Fetches the nightly version of Scarb directly from its release page and places the binary in the required path.
     3. **Install Starknet Foundry**: Installs the specified version of Starknet Foundry using a curl command.
     4. **Run Cairo Tests**: Executes tests using the `snforge` command.

```yml
name: Test

on:
  pull_request:
    branches:
      - main
  push:
    branches:
      - main
env:
  SCARB_VERSION: 0.6.1+nightly-2023-08-16
  STARKNET_FOUNDRY_VERSION: 0.3.0

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Scarb
        run: |
          NIGHTLY_DATE=$(echo ${SCARB_VERSION} | cut -d '+' -f 2)
          wget https://github.com/software-mansion/scarb-nightlies/releases/download/${NIGHTLY_DATE}/scarb-${NIGHTLY_DATE}-x86_64-unknown-linux-gnu.tar.gz
          tar -xvf scarb-${NIGHTLY_DATE}-x86_64-unknown-linux-gnu.tar.gz
          sudo mv scarb-v${SCARB_VERSION}-x86_64-unknown-linux-gnu/bin/scarb /usr/local/bin
      - name: Install starknet foundry
        run: curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh -s -- -v ${STARKNET_FOUNDRY_VERSION}
      - name: Run cairo tests
        run: snforge
```