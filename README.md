<p align="center">
		<a href="https://serversideup.net/open-source/spin/"><img src=".github/small-header.png" width="1200" alt="Spin Header" /></a>
</p>
<p align="center">
		<a href="https://serversideup.net/open-source/spin/"><img src="https://raw.githubusercontent.com/serversideup/media-assets/main/spin/spin-demo_spin-up.gif" width="1200" alt="Spin Header" /></a>
</p>
<p align="center">
	<a href="https://actions-badge.atrox.dev/serversideup/spin/goto?ref=main"><img alt="Build Status" src="https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fserversideup%2Fspin%2Fbadge%3Fref%3Dmain&style=flat" /></a>
	<a href="https://github.com/serversideup/spin/blob/main/LICENSE" target="_blank"><img src="https://badgen.net/github/license/serversideup/spin" alt="License"></a>
	<a href="https://github.com/sponsors/serversideup"><img src="https://badgen.net/badge/icon/Support%20Us?label=GitHub%20Sponsors&color=orange" alt="Support us"></a>
	<br />
	<a href="https://www.npmjs.com/package/@serversideup/spin"><img alt="npm" src="https://img.shields.io/npm/dm/@serversideup/spin?color=red&label=downloads&logo=npm"></a>
	<a href="https://packagist.org/packages/serversideup/spin"><img alt="Packagist Downloads" src="https://img.shields.io/packagist/dm/serversideup/spin?color=blue&logo=packagist"></a>
	<a href="https://community.serversideup.net"><img alt="Discourse users" src="https://img.shields.io/discourse/users?color=blue&server=https%3A%2F%2Fcommunity.serversideup.net"></a>
  <a href="https://serversideup.net/discord"><img alt="Discord" src="https://img.shields.io/discord/910287105714954251?color=blueviolet"></a>
</p>

# Introduction

**Stop wasting time fixing production issues you've already solved.** Spin is a bash utility that improves the user-experience for teams using Docker. Replicate any environment on any machine, regardless if they are running MacOS, Windows, or Linux. Centralize your infrastructure from a single configuration file using Docker.

Spin is a wrapper script that dramatically improves the developer experience when working with Docker. Spin uses officially supported features and best practices from Docker.

<details open>
<summary>
 <b>Features</b>
</summary> <br />

|<picture><img width="100%" alt="Replicate in any Environment" src="https://serversideup.net/wp-content/uploads/2024/01/replicate.png"></picture>|<picture><img width="100%" alt="Runs on Mac, Windows, Linux" src="https://serversideup.net/wp-content/uploads/2024/01/run-on-anything.png"></picture>|<picture><img width="100%" alt="Choose Any Host" src="https://serversideup.net/wp-content/uploads/2024/01/choose-any-host.png"></picture>|
|:---:|:---:|:---:|
|<picture><img width="100%" alt="Framework Agnostic" src="https://serversideup.net/wp-content/uploads/2024/01/framework-agnostic.png"></picture>|<picture><img width="100%" alt="Zero-downtime Deployments" src="https://serversideup.net/wp-content/uploads/2024/01/zero-downtime-deployments.png"></picture>|<picture><img width="100%" alt="Docker Syntax Simplified" src="https://serversideup.net/wp-content/uploads/2024/01/docker-simplified.png"></picture>|
|<picture><img width="100%" alt="Simple Server Management" src="https://serversideup.net/wp-content/uploads/2024/01/simple-server-management.png"></picture>|<picture><img width="100%" alt="GitHub Action Support" src="https://serversideup.net/wp-content/uploads/2024/01/github-action-support.png"></picture>|<picture><img width="100%" alt="Automated SSL" src="https://serversideup.net/wp-content/uploads/2024/01/automated-ssl.png"></picture>|

</details>

## Installation & Usage
Spin is flexible and able to be installed via:
- [macOS](https://serversideup.net/open-source/spin/docs/installation/install-macos)
- [Windows](https://serversideup.net/open-source/spin/docs/installation/install-windows)
- [Linux](https://serversideup.net/open-source/spin/docs/installation/install-linux)
- [Composer](https://serversideup.net/open-source/spin/docs/installation/install-composer)
- [NPM/Yarn](https://serversideup.net/open-source/spin/docs/installation/install-npm-yarn)

### Simple Install Command
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/serversideup/spin/main/tools/install.sh)"
```
### Create a new project
Spin has `spin new` to create a new project with Spin installed, as well as `spin init` to add Spin to an existing project.

```
spin new laravel {{ your project name }}
```
## Looking for more features?
We have a "[Spin Pro Laravel Template](https://getspin.pro)" that includes more features for Laravel Pros:

| Feature | Spin Basic Laravel Template | Spin Pro Laravel Template |
|---------|---------------------------|-----------|
| Price | Free | $199/once (lifetime access) |
| Automated Deployments with GitHub Actions | ❌ | ✅ |
| Local Development SSL | ❌ | ✅ (Trusted) |
| Tunnel Support | ❌ | ✅ |
| SMTP Trapping | ❌ | ✅ (Mailpit) |
| Vite over HTTPS | ❌ | ✅ |
| Databases | SQLite | ✅ MariaDB, MySQL, PostgreSQL, SQLite |
| Redis | ❌ | ✅ |
| Laravel Horizon | ❌ | ✅ |
| Laravel Reverb | ❌ | ✅ |
| Laravel Queues | ❌ | ✅ |
| Mailpit over HTTPS | ❌ | ✅ |
| Node Package Manager | `yarn` | `yarn` or `npm` |
| Support | ✅ Discord, GitHub Discussions | ✅ Private Community Support |

If you're interested in the Pro version, you visit [https://getspin.pro](https://getspin.pro) for more information.

## How Spin Works
Spin serves as a collection of open source technologies, put together in one simple experience.

<p>
	<img src="./.github/spin-diagram.png" />
</p>

#### Spin uses these proven technologies
- [Docker](https://www.docker.com/) (Docker Desktop, Docker Compose, Docker Swarm Mode)
- [Ansible](https://www.ansible.com/)
- Includes [GitHub Actions](https://docs.github.com/en/actions) templates (but can work with [GitLab CI](https://docs.gitlab.com/ee/ci/) too)

#### We also use a number of our other open source projects in Spin
- [Spin Ansible Collection](https://github.com/serversideup/ansible-collection-spin) - Used to provision and maintain your production server.
- [serversideup/docker-build-action](https://github.com/marketplace/actions/docker-build-action) - A simplified syntax to build and publish your Docker images with GitHub Actions.
- [serversideup/docker-swarm-deploy-github-action](https://github.com/marketplace/actions/docker-swarm-deploy-github-action) - A simplified syntax to deploy to Docker Swarm Mode via GitHub Actions.
- [serversideup/php](https://serversideup.net/open-source/docker-php/) - PHP Docker images highly optimized to work with Laravel + Spin.
- [serversideup/docker-ssh](https://github.com/serversideup/docker-ssh) - A lightweight docker image that runs SSH. This is a fantastic method on using a secure SSH tunnel into your database cluster.
- [serversideup/docker-ansible](https://github.com/serversideup/docker-ansible) - A lightweight docker image that runs Ansible.
- [serversideup/docker-github-cli](https://github.com/serversideup/docker-github-cli) - A lightweight docker image that runs GitHub CLI.

## Resources
- **[Website](https://serversideup.net/open-source/spin/)** overview of the product.
- **[Docs](https://serversideup.net/open-source/spin/docs)** for a deep-dive on how to use the product.
- **[Discord](https://serversideup.net/discord)** for friendly support from the community and the team.
- **[GitHub](https://github.com/serversideup/spin)** for source code, bug reports, and project management.
- **[Get Professional Help](https://serversideup.net/professional-support)** - Get video + screen-sharing help directly from the core contributors.

## Contributing
As an open-source project, we strive for transparency and collaboration in our development process. We greatly appreciate any contributions members of our community can provide. Whether you're fixing bugs, proposing features, improving documentation, or spreading awareness - your involvement strengthens the project. Please review our [contribution guidelines](https://serversideup.net/open-source/spin/docs/community/contributing) and [code of conduct](./.github/code_of_conduct.md) to understand how we work together respectfully.

- **Bug Report**: If you're experiencing an issue while using these images, please [create an issue](https://github.com/serversideup/spin/issues/new/choose).
- **Feature Request**: Make this project better by [submitting a feature request](https://github.com/serversideup/spin/discussions/9).
- **Documentation**: Improve our documentation by [submitting a documentation change](./docs/README.md).
- **Community Support**: Help others on [GitHub Discussions](https://github.com/serversideup/spin/discussions) or [Discord](https://serversideup.net/discord).
- **Security Report**: Report critical security issues via [our responsible disclosure policy](https://www.notion.so/Responsible-Disclosure-Policy-421a6a3be1714d388ebbadba7eebbdc8).

Need help getting started? Join our Discord community and we'll help you out!

<a href="https://serversideup.net/discord"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/join-discord.svg" title="Join Discord"></a>

<!-- serversideup-sponsors -->
## Our Sponsors
All of our software is free and open to the world. None of this can be brought to you without the financial backing of our sponsors.

<p align="center"><a href="https://github.com/sponsors/serversideup"><img src="https://521public.s3.amazonaws.com/serversideup/sponsors/sponsor-box.png" alt="Become a sponsor"></a></p>

### Platinum Sponsors
<a href="https://sevalla.com"><img src="https://serversideup.net/sponsors/sevalla.png" alt="Sevalla" width="500px"></a>

### Silver Sponsors
<a href="https://giga-infosystems.com"><img src="https://serversideup.net/sponsors/giga-infosystems.png" alt="GiGa infosystems" width="200px"></a>

### Infrastructure Sponsors
These companies give us free access to the tools and infrastructure we use to build, test, and ship our open source projects. Their support helps our entire community.

<a href="https://depot.dev"><img src="https://serversideup.net/sponsors/depot.png" alt="Depot" width="250px"></a>&nbsp;&nbsp;<a href="https://hub.docker.com/u/serversideup"><img src="https://serversideup.net/sponsors/docker.png" alt="Docker" width="250px"></a>
<!-- serversideup-sponsors -->

<!-- serversideup-about -->
## About Us
We're [Dan](https://x.com/danpastori) and [Jay](https://x.com/jaydrogers) - a two-person team with a passion for open source products. We created [Server Side Up](https://serversideup.net) to help share what we learn.

<div align="center">

| <div align="center">Dan Pastori</div> | <div align="center">Jay Rogers</div> |
| --- | --- |
| <div align="center"><a href="https://x.com/danpastori"><img src="https://serversideup.net/wp-content/uploads/2023/08/dan.jpg" title="Dan Pastori" width="150px"></a><br /><a href="https://x.com/danpastori"><img src="https://serversideup.net/logos/x.svg" title="X" width="24px"></a><a href="https://github.com/danpastori"><img src="https://serversideup.net/logos/github.svg" title="GitHub" width="24px"></a></div> | <div align="center"><a href="https://x.com/jaydrogers"><img src="https://serversideup.net/wp-content/uploads/2023/08/jay.jpg" title="Jay Rogers" width="150px"></a><br /><a href="https://x.com/jaydrogers"><img src="https://serversideup.net/logos/x.svg" title="X" width="24px"></a><a href="https://github.com/jaydrogers"><img src="https://serversideup.net/logos/github.svg" title="GitHub" width="24px"></a></div> |

</div>

### Hire Us
Get two senior Laravel experts who deliver quality code with predictable monthly pricing. [Dan](https://x.com/danpastori) and [Jay](https://x.com/jaydrogers) have 30+ years of combined experience building scalable Laravel applications.

- **🎯 Complete Laravel expertise** - Full-stack development, CI/CD, database optimization, mobile apps
- **💰 Predictable pricing** - Fixed monthly subscription, no hourly billing surprises, 40%+ savings
- **⚡ Maximum productivity** - 90%+ development time, no meetings, results in days not weeks
- **🛡️ Risk-free** - 7-day money-back guarantee, cancel anytime

**[💬 Discuss Your Project →](https://serversideup.net/hire-us)**

### Find us at:

* **📖 [Blog](https://serversideup.net)** - Get the latest guides and free courses on all things web/mobile development.
* **🙋 [Community](https://community.serversideup.net)** - Get friendly help from our community members.
* **🤵‍♂️ [Get Professional Help](https://serversideup.net/professional-support)** - Get video + screen-sharing support from the core contributors.
* **💻 [GitHub](https://github.com/serversideup)** - Check out our other open source projects.
* **📫 [Newsletter](https://serversideup.net/subscribe)** - Skip the algorithms and get quality content right to your inbox.
* **🐥 [X (Twitter)](https://x.com/serversideup)** - You can also follow [Dan](https://x.com/danpastori) and [Jay](https://x.com/jaydrogers).
* **❤️ [Sponsor Us](https://github.com/sponsors/serversideup)** - Please consider sponsoring us so we can create more helpful resources.

## Our Products
If you appreciate this project, be sure to check out our other projects.

### 🛠️ Premium
- **[Self-Host Pro](https://selfhostpro.com)**: Sell self-hosted software in minutes.
- **[Bugflow](https://bugflow.io)**: Get product feedback directly in GitHub, GitLab, and more.
- **[Spin Pro](https://getspin.pro)**: Production-ready Docker templates for shipping quickly.

### 🌍 Open Source
- **[serversideup/php](https://serversideup.net/open-source/docker-php/)**: Supercharged PHP Docker images, based off the official PHP images. <!-- repo:serversideup/docker-php -->
- **[Financial Freedom](https://serversideup.net/open-source/financial-freedom/)**: Open source alternative to Mint, YNAB, and more. <!-- repo:serversideup/financial-freedom -->
- **[AmplitudeJS](https://serversideup.net/open-source/amplitudejs/)**: Customize the design of any element of the HTML5 Audio Player. <!-- repo:521dimensions/amplitudejs -->
- **[webext-bridge](https://serversideup.net/open-source/webext-bridge/)**: Messaging in Web Extensions made easy. Batteries included. <!-- repo:serversideup/webext-bridge -->
- **[serversideup/ansible](https://github.com/serversideup/docker-ansible)**: Run Ansible anywhere with a lightweight and powerful Docker image. <!-- repo:serversideup/docker-ansible -->

### 📚 Books
- **[Building Browser Extensions](https://serversideup.net/products/building-multi-platform-browser-extensions/)**: Build browser extensions for Firefox, Chrome, and more.
- **[Ultimate Guide To Building APIs & SPAs](https://serversideup.net/products/ultimate-guide-to-building-apis-and-spas-with-laravel-and-nuxt3/)**: Build web and mobile apps from the same codebase.
<!-- serversideup-about -->
