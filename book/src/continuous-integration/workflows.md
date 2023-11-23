# Github Workflows Documentation

## Satoru Book Workflow Documentation

### Overview:
The "Satoru Book" GitHub Actions workflow (`book.yml`) is specifically designed for the automated build and deployment of the Satoru book's latest version.

### Workflow Details:

**Workflow Name:** Satoru Book

**Trigger Conditions:**
1. **Push Event:** Activated when changes are pushed to the `main` branch.
2. **Pull Request Event:** Activated for every pull request.

**Jobs:**
1. **Book Build & Deploy Job**:
   - **Environment:** Ubuntu 20.04
   - **Concurrency:** Ensures that only one job runs at a time per branch or pull request, preventing potential conflicts.
   - **Steps:**
     1. **Checkout Repository**: Fetches the repository's content.
     2. **Setup mdBook**: Initializes mdBook, a utility for creating online books from markdown files. It uses the latest available version.
     3. **Build mdBook**: Constructs the online book using mdBook from the source files located in the `./book` directory.
     4. **Deploy**: If the trigger branch is `main`, the built book is deployed to GitHub Pages using the specified token. The content to be published is sourced from the `./book/book` directory.

```yml
name: Satoru Book

on:
  push:
    branches:
      - main
  pull_request:

jobs:
  book:
    runs-on: ubuntu-20.04
    concurrency:
      group: ${{ github.workflow }}-${{ github.ref }}
    steps:
      - uses: actions/checkout@v2

      - name: Setup mdBook
        uses: peaceiris/actions-mdbook@v1
        with:
          mdbook-version: 'latest'

      - run: mdbook build
        working-directory: ./book

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        if: ${{ github.ref == 'refs/heads/main' }}
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./book/book
```

## Build Workflow Documentation

### Overview:
The "Build" GitHub Actions workflow (`build.yml`) is made for building Cairo files using Scarb and checking their format.

### Workflow Details:

**Workflow Name:** Build

**Trigger Conditions:**
1. **Push Event:** Activated when changes are pushed to the `main` branch.
2. **Pull Request Event:** Triggered for every pull request targeting the `main` branch.

**Environment Variables:**
- **SCARB_VERSION:** Specifies the version of Scarb to be used, currently set to `0.7.0`.

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
  SCARB_VERSION: 0.7.0

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: software-mansion/setup-scarb@v1
        with:
          scarb-version: "0.7.0"
      - name: Check cairo format
        run: scarb fmt --check
      - name: Build cairo programs
        run: scarb build
```

## Security Workflow Documentation

### Overview:
The "Security" GitHub Actions workflow (`security.yml`) is designed to enforce security standards and conduct safety checks on the codebase. It ensures that code modifications follow best security practices and identifies potential vulnerabilities.

### Workflow Details:

**Workflow Name:** Security

**Trigger Conditions:**
1. **Push Event:** Activated when changes are pushed to the `main` branch.
2. **Pull Request Event:** Triggered for every pull request targeting the `main` branch.

**Jobs:**
1. **Security Check Job**:
   - **Environment:** Latest version of Ubuntu.
   - **Steps:**
     1. **Checkout Repository**: Retrieves the repository's content.
     2. **Install Semgrep**: Installs Semgrep, a static code analysis tool, to identify potential security issues.
     3. **Run Semgrep**: Executes Semgrep with a custom configuration sourced from a release of `semgrep-cairo-rules`. Results are written to `semgrep-output.txt`.
     4. **Save Semgrep Output**: Archives the Semgrep results as an artifact named `semgrep-cairo`.

```yml
name: Security

on:
  pull_request:
    branches:
      - main
  push:
    branches:
      - main

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Semgrep
        run: |
          pip install semgrep
      - name: Run Semgrep
        run: semgrep --config https://github.com/avnu-labs/semgrep-cairo-rules/releases/download/v0.0.1/cairo-rules.yaml ./src > semgrep-output.txt
      - name: Save Semgrep Output as an Artifact
        uses: actions/upload-artifact@v3
        with:
          name: semgrep-cairo
          path: semgrep-output.txt
```

## Test Workflow Documentation

### Overview:
The "Test" GitHub Actions workflow (`test.yml`) ensures the code's integrity by validating its functionality. It aims to detect any potential issues introduced by new code modifications, guaranteeing that they do not impact the existing codebase.

### Workflow Details:

**Workflow Name:** Test

**Trigger Conditions:**
1. **Push Event:** Activated when changes are pushed to the `main` branch.
2. **Pull Request Event:** Triggered for pull requests targeting the `main` branch.

**Environment Variables:**
- **SCARB_VERSION:** Specifies the Scarb version, currently set to `0.7.0`.
- **STARKNET_FOUNDRY_VERSION:** Defines the version of Starknet Foundry, currently set to `0.8.3`.

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
  SCARB_VERSION: 0.7.0

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: foundry-rs/setup-snfoundry@v1
        with:
          starknet-foundry-version: 0.11.0
      - uses: software-mansion/setup-scarb@v1
        with:
          scarb-version: "0.7.0"
      - name: Run cairo tests
        run: snforge
```