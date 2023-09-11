<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<p align="center">
  <img src="docs/images/logo.png" height="256">
</p>

<h1 align="center">⚡ Satoru ⚡</h1>

<p align="center">
  <strong>Synthetics platform for Starknet, inspired by GMX v2 design.</strong>
</p>

<p align="center">
  <a href="LICENSE">
    <img src="https://img.shields.io/github/license/keep-starknet-strange/satoru.svg?style=flat-square" alt="Project license">
  </a>
  <a href="https://github.com/keep-starknet-strange/satoru/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22">
    <img src="https://img.shields.io/badge/PRs-welcome-ff69b4.svg?style=flat-square" alt="Pull Requests welcome">
  </a>
  <a href="https://keep-starknet-strange.github.io/satoru/">
    <img src="https://img.shields.io/badge/Read-Satoru_Book-blue" alt="Read the Satoru Book">
  </a>
</p>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

## ⚡ About Satoru ⚡

Satoru is a cutting-edge synthetics platform for Starknet, taking inspiration from the modular design of GMX v2.

Read the [Satoru Book](https://keep-starknet-strange.github.io/satoru/) to learn more about the project.

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

To deploy contracts of the saturo, you first need to setup a smart wallet :

- Create a signer by following this tutorial : [Signers](https://book.starkli.rs/signers)

- Create an account by following this tutorial : [Accounts](https://book.starkli.rs/accounts/) 

Once your smart wallet is setup, you can now run deployment files to deploy contracts, for example :

```bash
cd scripts

./deploy_contract.sh
```


## 📚 Resources

Here are some resources to help you get started:

- [Satoru Book](https://keep-starknet-strange.github.io/satoru/)
- [Cairo Book](https://book.cairo-lang.org/)
- [Starknet Book](https://book.starknet.io/)
- [Starknet Foundry Book](https://foundry-rs.github.io/starknet-foundry/)
- [Starknet By Example](https://starknet-by-example.voyager.online/)
- [Starkli Book](https://book.starkli.rs/)
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
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/abdelhamidbakhta"><img src="https://avatars.githubusercontent.com/u/45264458?v=4?s=100" width="100px;" alt="Abdel @ StarkWare "/><br /><sub><b>Abdel @ StarkWare </b></sub></a><br /><a href="https://github.com/keep-starknet-strange/satoru/commits?author=abdelhamidbakhta" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/sparqet"><img src="https://avatars.githubusercontent.com/u/37338401?v=4?s=100" width="100px;" alt="sparqet"/><br /><sub><b>sparqet</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/satoru/commits?author=sparqet" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/zarboq"><img src="https://avatars.githubusercontent.com/u/37303126?v=4?s=100" width="100px;" alt="zarboq"/><br /><sub><b>zarboq</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/satoru/commits?author=zarboq" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/drspacemn"><img src="https://avatars.githubusercontent.com/u/16685321?v=4?s=100" width="100px;" alt="drspacemn"/><br /><sub><b>drspacemn</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/satoru/commits?author=drspacemn" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Sk8erboi84"><img src="https://avatars.githubusercontent.com/u/105498726?v=4?s=100" width="100px;" alt="Michel"/><br /><sub><b>Michel</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/satoru/commits?author=Sk8erboi84" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/delaaxe"><img src="https://avatars.githubusercontent.com/u/1091900?v=4?s=100" width="100px;" alt="delaaxe"/><br /><sub><b>delaaxe</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/satoru/commits?author=delaaxe" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/danilowhk"><img src="https://avatars.githubusercontent.com/u/12735159?v=4?s=100" width="100px;" alt="danilowhk"/><br /><sub><b>danilowhk</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/satoru/commits?author=danilowhk" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/ermvrs"><img src="https://avatars.githubusercontent.com/u/3417324?v=4?s=100" width="100px;" alt="Erim"/><br /><sub><b>Erim</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/satoru/commits?author=ermvrs" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/parketh"><img src="https://avatars.githubusercontent.com/u/27808560?v=4?s=100" width="100px;" alt="parketh"/><br /><sub><b>parketh</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/satoru/commits?author=parketh" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/enitrat"><img src="https://avatars.githubusercontent.com/u/60658558?v=4?s=100" width="100px;" alt="Mathieu"/><br /><sub><b>Mathieu</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/satoru/commits?author=enitrat" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/gaetbout"><img src="https://avatars.githubusercontent.com/u/16206518?v=4?s=100" width="100px;" alt="gaetbout"/><br /><sub><b>gaetbout</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/satoru/commits?author=gaetbout" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/ametel01"><img src="https://avatars.githubusercontent.com/u/91626827?v=4?s=100" width="100px;" alt="Alex Metelli"/><br /><sub><b>Alex Metelli</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/satoru/commits?author=ametel01" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/FabienCoutant"><img src="https://avatars.githubusercontent.com/u/16558702?v=4?s=100" width="100px;" alt="Fabien C"/><br /><sub><b>Fabien C</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/satoru/commits?author=FabienCoutant" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/rmzlb"><img src="https://avatars.githubusercontent.com/u/25151724?v=4?s=100" width="100px;" alt="rmzlb"/><br /><sub><b>rmzlb</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/satoru/commits?author=rmzlb" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/0xTitan"><img src="https://avatars.githubusercontent.com/u/104304962?v=4?s=100" width="100px;" alt="0xTitan"/><br /><sub><b>0xTitan</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/satoru/commits?author=0xTitan" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Bal7hazar"><img src="https://avatars.githubusercontent.com/u/97087040?v=4?s=100" width="100px;" alt="Bal7hazar @ Carbonable"/><br /><sub><b>Bal7hazar @ Carbonable</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/satoru/commits?author=Bal7hazar" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!