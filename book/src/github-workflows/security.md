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