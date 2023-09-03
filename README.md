<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<p align="center">
  <img src="docs/images/logo.png" height="256">
</p>

<h1 align="center">⚡ Gojo ⚡</h1>

<p align="center">
  <strong>Synthetics platform for Starknet, inspired by GMX v2 design.</strong>
</p>

<p align="center">
  <a href="LICENSE">
    <img src="https://img.shields.io/github/license/keep-starknet-strange/gojo.svg?style=flat-square" alt="Project license">
  </a>
  <a href="https://github.com/keep-starknet-strange/gojo/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22">
    <img src="https://img.shields.io/badge/PRs-welcome-ff69b4.svg?style=flat-square" alt="Pull Requests welcome">
  </a>
  <a href="https://keep-starknet-strange.github.io/gojo/">
    <img src="https://img.shields.io/badge/Read-Gojo_Book-blue" alt="Read the Gojo Book">
  </a>
</p>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

## ⚡ About Gojo ⚡

Gojo is a cutting-edge synthetics platform for Starknet, taking inspiration from the modular design of GMX v2.

Read the [Gojo Book](https://keep-starknet-strange.github.io/gojo/) to learn more about the project.

## 🛠️ Build

To build the project, run:

```bash
scarb build
```

## 🧪 Test

To test the project, run:

```bash
snforge
```

## 🚀 Deploy

To deploy contracts of the projects, you first need to set up a smart wallet :

- Create a signer by following the tutorial : [Signers](https://book.starkli.rs/signers)

- Create an account by following the tutorial : [Accounts](https://book.starkli.rs/accounts/) 

Once your smart wallet is set up, you can now run deployment files to deploy contracts, for example :

```bash
cd scripts
```

```bash
./deploy_chain_contract.sh
```

## 📚 Resources

Here are some resources to help you get started:

- [Gojo Book](https://keep-starknet-strange.github.io/gojo/)
- [Cairo Book](https://book.cairo-lang.org/)
- [Starknet Book](https://book.starknet.io/)
- [Starknet Foundry Book](https://foundry-rs.github.io/starknet-foundry/)
- [Starknet By Example](https://starknet-by-example.voyager.online/)
- GMX v2 resources
  - [GMX Synthetics](https://github.com/gmx-io/gmx-synthetics)
  - [Trading on v2](https://docs.gmx.io/docs/trading/v2)
  - [Contracts for v2](https://docs.gmx.io/docs/api/contracts-v2/)
  - [Liquidity on v2](https://docs.gmx.io/docs/providing-liquidity/v2)

## 📖 License

This project is licensed under the **MIT license**. See [LICENSE](LICENSE) for more information.

## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/abdelhamidbakhta"><img src="https://avatars.githubusercontent.com/u/45264458?v=4?s=100" width="100px;" alt="Abdel @ StarkWare "/><br /><sub><b>Abdel @ StarkWare </b></sub></a><br /><a href="https://github.com/keep-starknet-strange/gojo/commits?author=abdelhamidbakhta" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/sparqet"><img src="https://avatars.githubusercontent.com/u/37338401?v=4?s=100" width="100px;" alt="sparqet"/><br /><sub><b>sparqet</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/gojo/commits?author=sparqet" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/zarboq"><img src="https://avatars.githubusercontent.com/u/37303126?v=4?s=100" width="100px;" alt="zarboq"/><br /><sub><b>zarboq</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/gojo/commits?author=zarboq" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!