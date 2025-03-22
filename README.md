<p align="center">
  <img width="256px" src="./docs/logo.png" alt="FitAI Logo" />
  <h1 align="center">FitAI</h1>
  <p align="center">
    [ <b><ins>FitAI</ins></b> ] ·
    [ <a href="https://github.com/x2oreo/FitAI-api">FitAI API</a> ] · 
    [ <a href="https://github.com/x2oreo/FitAI-vscode-extension">FitAI VS Code Extension</a> ]
  </p>
  <p align="center">
    FitAI is an innovative ecosystem tailored specifically for developers who face challenges balancing health with their demanding coding schedules. Our solution simplifies achieving fitness goals by providing personalized workout and meal plans, AI expert advice and integration in the VSCode ecosystem.
  </p>
</p>

<p align="center">
    <a href="https://github.com/x2oreo/fitai/releases">
      <img alt="GitHub Release" src="https://img.shields.io/github/v/release/x2oreo/FitAI?color=88ff0c&style=flat-square">
    </a>
    <a href="https://github.com/orgs/x2oreo/projects/2">
      <img alt="GitHub Issues or Pull Requests" src="https://img.shields.io/github/issues/x2oreo/fitai?color=88ff0c&style=flat-square">
    </a>
    <a href="https://github.com/x2oreo/fitai/fork">
        <img src="https://img.shields.io/badge/contributions-welcome-brightgreen.svg?color=88ff0c&style=flat-square" alt="Contributions welcome" />
    </a>
    <a href="LICENSE">
        <img src="https://img.shields.io/github/license/x2oreo/fitai?color=88ff0c&style=flat-square" alt="License" />
    </a>
</p>

---

## Getting Started

The FitAI ecosystem consists of three primary components:

- **Mobile Application** *(this repository)*: Offers personalized meal and workout plans tailored to your available time and financial situation. You can also chat with a personal AI health assistant, which is designed specifically for programmers
- **AI Model API Server** *(available at [FitAI API](https://github.com/x2oreo/FitAI-api))*: Generates personalized fitness and meal plans based on your profile and preferences, and provides the AI chat assistant.
- **Visual Studio Code Extension** *(available at [FitAI VS Code Extension](https://github.com/x2oreo/FitAI-vscode-extension))*: Integrates health guidance directly into your coding workflow.

Each component has detailed setup instructions available in their respective repositories.

## Download FitAI

<p align="center">
  You may download the latest FitAI release here or via the following QR code:
</p>
<p align="center">
  <img src="./docs/releases-qr.png" alt="Releases page">
</p>

## Mobile App Development

App is made on **Flutter (Dart)**, with an **Emulator** (mobile phone simulation) and **Firebase** for the data base. To build it locally, you need to do the following:

1. Download and install the Flutter SDK.
2. Add and configure the Android SDK. You may verify its installation via the `flutter doctor` command.
3. Connect an real/emulated Android 7.1 or higher device. You may verify it is available via the `flutter devices` command.
4. Start the application by running: `flutter run`.
   - **Important notice**<br>
    For Google authentication to properly work, you may need to build the application with development/production signing keys, registered to Firebase account. To view your local keys, you may run `./gradlew signingReport` from within the `/FITAI/android` directory.
5. **Enjoy! 🎉**

## Authors
<table width="100%">
  <tr>
    <td align="center">
        <img width="150px" src="https://github.com/FantomJx.png" alt="Mark Danileychenko" />
        <p><b>Mark Danileychenko</b><br/><a href="https://github.com/FantomJx/"><img src="https://img.shields.io/badge/GitHub-100000?style=flat-square&logo=github&logoColor=white" /></a></p>
    </td>
    <td align="center">
        <img width="150px" src="https://github.com/Fichoto.png" alt="Filip Mutafis" />
        <p><b>Filip Mutafis</b><br/><a href="https://github.com/Fichoto/"><img src="https://img.shields.io/badge/GitHub-100000?style=flat-square&logo=github&logoColor=white" /></a></p>
    </td>
    <td align="center">
        <img width="150px" src="https://github.com/kaloyan-gavrilov.png" alt="Kaloyan Gavrilov" />
        <p><b>Kaloyan Gavrilov</b><br/><a href="https://github.com/kaloyan-gavrilov/"><img src="https://img.shields.io/badge/GitHub-100000?style=flat-square&logo=github&logoColor=white" /></a></p>
    </td>
    <td align="center">
        <img width="150px" src="https://github.com/krister078.png" alt="Kristiyan Kulekov" />
        <p><b>Kristiyan Kulekov</b><br/><a href="https://github.com/simo1209/"><img src="https://img.shields.io/badge/GitHub-100000?style=flat-square&logo=github&logoColor=white" /></a></p>
    </td>
  </tr>
</table>

---

## Contribution Guidelines

We welcome contributions to the FitAI ecosystem! Follow these steps:

1. Fork the repository: <https://github.com/x2oreo/FitAI/fork>
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit your changes: `git commit -m "Add your message here"`
4. Push to your branch: `git push origin feature/your-feature-name`
5. Open a Pull Request

Your contributions will be reviewed and merged promptly!

---

## License

FitAI is distributed under the MIT License. See the [LICENSE](LICENSE) file for more details.
