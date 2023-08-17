# Gojo Book Workflow Documentation

### Overview:
The "Gojo Book" GitHub Actions workflow (`book.yml`) is specifically designed for the automated build and deployment of the Gojo book's latest version.

### Workflow Details:

**Workflow Name:** Gojo Book

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
name: Gojo Book

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