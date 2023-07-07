# 🫡 Contributing to 🐍 snekmate

🙏 Thank you so much for your help in improving the project and pushing 🐍Vyper's long-term success! Many folks will be grateful to you. We are so glad to have you!

There are many ways to get involved at every level. It does not matter if you have just started with 🐍Vyper or are the most experienced expert, we can use your help.

**No contribution is too small and all contributions are highly appreciated.**

We particularly welcome support in the following areas:

- [Reporting issues](https://github.com/pcaversaccio/snekmate/issues/new?assignees=pcaversaccio&labels=bug+%F0%9F%90%9B&template=bug_report.yml&title=%5BBug-Candidate%5D%3A+). For security issues, see our [Security Policy](./SECURITY.md).
- Fixing and responding to [existing issues](https://github.com/pcaversaccio/snekmate/issues).
- Proposing changes and/or [new features](https://github.com/pcaversaccio/snekmate/issues/new?assignees=pcaversaccio&labels=feature+%F0%9F%92%A5&template=feature_request.yml&title=%5BFeature-Request%5D%3A+).
- Implementing changes and/or new features.
- Improving documentation and fixing typos.

> If you are writing a new feature and/or a breaking change, please ensure that you include appropriate test cases.

## 🙋‍♀️ Opening an Issue

If you encounter a bug or want to suggest a feature, you are welcome to [open an issue](https://github.com/pcaversaccio/snekmate/issues/new/choose). For serious bugs, please do **not** open an issue, but refer to our [Security Policy](./SECURITY.md).

Before opening an issue, please review the existing open and closed issues as well as the existing [discussions](https://github.com/pcaversaccio/snekmate/discussions) and consider commenting on one of them instead.

For general types of discussion, e.g. on best practices, formatting, etc., please consider opening a [new discussion](https://github.com/pcaversaccio/snekmate/discussions/new/choose).

When you propose a new feature, you should provide as much detail as possible, especially on the use cases that motivate it. Features are prioritised by their potential impact on the ecosystem, so we value information that shows the impact could be high.

## 🛠 Submitting a Pull Request (PR)

As a contributor, you are expected to fork the `main` branch of this repository, work on your own fork, and then submit pull requests. The pull requests are reviewed and eventually merged into the `main` repository. See ["Fork-a-Repo"](https://help.github.com/articles/fork-a-repo) for how this works.

Ensure you read and follow our [Engineering Guidelines](./GUIDELINES.md). Run prettier, linter, and tests to make sure your PR is sound before submitting it.

When you open a PR, you will be provided with a [template](./.github/pull_request_template.md) and a checklist. Read it carefully and follow the steps accordingly. You can expect a review and feedback from the maintainer [pcaversaccio](https://github.com/pcaversaccio) afterwards.

If you are looking for an easy starting point, look for issues labelled as [good first issue 🎉](https://github.com/pcaversaccio/snekmate/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue+%F0%9F%8E%89%22)!

## 🌀 Dependencies

You will need the following dependencies:

- [Git](https://git-scm.com)
- [Node.js](https://nodejs.org)
- [Yarn](https://classic.yarnpkg.com)
- [🐍Vyper](https://github.com/vyperlang/vyper)
- [Foundry](https://github.com/foundry-rs/foundry)

## ⚙️ Installation

It is recommended to install [Yarn](https://classic.yarnpkg.com) through the `npm` package manager, which comes bundled with [Node.js](https://nodejs.org) when you install it on your system. It is recommended to use a Node.js version `>= 18.0.0`.

Once you have `npm` installed, you can run the following both to install and upgrade Yarn:

```console
npm install --global yarn
```

After having installed Yarn, simply run:

```console
yarn install
```

This repository also includes the [Foundry](https://github.com/foundry-rs/foundry) toolkit. You can simply run `forge install` to install all the submodule dependencies that are in this repository. If you need help getting started with Foundry, we recommend reading the [📖 Foundry Book](https://book.getfoundry.sh).
