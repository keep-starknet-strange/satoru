## Build Workflow Documentation

### Overview:
The "Build" GitHub Actions workflow (`build.yml`) is made for building Cairo files using Scarb and checking their format.

### Workflow Details:

**Workflow Name:** Build

**Trigger Conditions:**
1. **Push Event:** Activated when changes are pushed to the `main` branch.
2. **Pull Request Event:** Triggered for every pull request targeting the `main` branch.

**Environment Variables:**
- **SCARB_VERSION:** Specifies the version of Scarb to be used, currently set to `0.6.1+nightly-2023-08-16`.

> **Note:** Currently, we are utilizing the nightly versions of Scarb to leverage the latest features of Cairo. The installation process is slightly different than using non-nightly versions. Once Cairo and Scarb stabilize, we will migrate to stable versions and employ the `software-mansion/setup-scarb` action for easier setup.

**Jobs:**
1. **Cairo Check & Build Job**:
   - **Environment:** Latest version of Ubuntu.
   - **Steps:**
     1. **Checkout Repository**: Fetches the repository's content.
     2. **Set up Scarb**: Instead of using the conventional setup action, we fetch the nightly version of Scarb directly from its release page and place the binary in the required path.
     3. **Check Cairo Format**: Ensures the Cairo files follow the expected format.
     4. **Build Cairo Programs**: Compiles the Cairo files.

```yml
name: Build

on:
  pull_request:
    branches:
      - main
  push:
    branches:
      - main
env:
  SCARB_VERSION: 0.6.1+nightly-2023-08-16

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
      - name: Check cairo format
        run: scarb fmt --check
      - name: Build cairo programs
        run: scarb build
```