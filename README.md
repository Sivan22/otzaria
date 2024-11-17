
<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]




<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/sivan22/otzaria">
    <img src="images/logo.svg" alt="Logo" width="80" height="80">
  </a>

  <h3 align="center">Otzaria</h3>

  <p align="center">
    Making the jewish library accessible to everyone by creating an app with a modern UI/UX, that could run on any device
    <br />
    <a href="https://sivan22.github.io/otzaria-download/"><strong>See our site »</strong></a>
    <br />
    <br/>  
    <a href="https://github.com/sivan22/otzaria/issues/new?labels=bug&template=bug-report---.md">Report Bug</a>
    ·
    <a href="https://github.com/sivan22/otzaria/issues/new?labels=enhancement&template=feature-request---.md">Request Feature</a>
    ·
    <a href="https://github.com/sivan22/otzaria/wiki">user's manual</a>
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

![alt text](image.png)

I felt the lack of an open source app of the jewish library, for PCs.


Torat Ememt is old and no longer maintained, and Sefaria's app is great, however, it does not work well on computers.

So i decided to make one myself. I did not know Dart and Flutter at all in the beginning, but it was fun. I **love** to learn new technologies!

The database itself is accessible to everyone following the important work of the Sefaria organization, so a big thank to them for that.

Key features of the project:
* the software is FREE and will be ALLWAYS FREE.
* Built to work effeciently on any device, including Windows, Linux, and Android.
* The app is designed to be as user friendly as possible.
* A thorough selection process has been undertaken to ensure that the books are suitable for the Torah community
* the library is flexible, means that you can add or remove books from the library.
* fast search engine, including the user-added books.
* the app supports the following formats: TXT, Docx and PDF.

I hope that my work will help the Torah community to learn easiely and effectively anytime and anywhere.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



### Built With



* [![Dart][dart]][Dart-url]
* [![Flutter][Flutter]][Flutter-url]

I Choose to use Dart and Flutter. I think that is the most efficient and most modern way to build a GUI app.

Also, it is a multiplatform framework.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

### windows
#### Prerequisites
make sure that Visual C++ Redistributable is installed on your computer. if not, download it from [Here](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170) and install it.

#### Installation
download the latest build for windows from [releases](https://github.com/Sivan22/otzaria/releases). 
the library is included in the .exe file.
in case you need only the app itself (for upgrading) you can download the .msix file.

### linux
#### Prerequisites
```sudo apt-get install libgtk-3-0 libblkid1 liblzma5```
#### Installation
* download the linux build from releases, extarct and run otzaria.
* when first running the app, you will be asked to download the library.
* alternatively, you can download the library manualy from [here], extarct it and provide path to the app.

### android
* Download the .apk file from the releases page, and install it.
* when first running the app,.you will be asked to download the library.
* alternatively, you can download the library manualy from [here] and provide the zip file to the app.

### iOS (iPhone/iPad)
* you can try the beta version through TestFlight. 
* follow this [link](https://testflight.apple.com/join/yvNbmaX4).
* when first running the app,.you will be asked to download the library.

### macos
* download the latest macos build from the releases page.
* run the app while pressing ctl.
* when first running the app, you will be asked to download the library.
* alternatively, you can download the library manualy from [here], extarct it and provide path to the app.



<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

See the Wiki section for documentation.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ROADMAP -->
## Roadmap

- [ ] Add business logic layer by switching the state management library to Bloc.
- [ ] Transfer books data from text files to SQLite database
- [ ] add option for semantic search using an embedding ML model and vector database
- [ ] language Support
    - [ ] English
    - [X] Hebrew

See the [open issues](https://github.com/sivan22/otzaria/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- LICENSE -->
## License

the code is currently Unlicensed. it may change in the future, but it will allways stay open-sourced.

the texts has different open licenses. you may check Sefaria's site for more info on that.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Sivan Ratson-  - sivan.ratson@gmail.com

Project Link: [https://github.com/sivan22/otzaria](https://github.com/sivan22/otzaria)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

the project was avavilable because of Sefaria's amazing project. 
<br>
and Dicta association, by which many important books were added.
<br>
<br>
<a href="https://www.sefaria.org/texts" title="ספריא" target="_blank"><img src="images/safria logo.png" alt="ספריא" width="154" height="80"/></a>
<a href="https://github.com/Dicta-Israel-Center-for-Text-Analysis/Dicta-Library-Download" title="דיקטה" target="_blank"><img src="images/dicta_logo.jpg" alt="דיקטה" width="154" height="80"/></a>
<a href="https://github.com/MosheWagner/Orayta-Books" title="אורייתא" target="_blank"><img src="images/Orayta.png" alt="אורייתא" width="200" height="80"/></a>
<a href="http://mobile.tora.ws" title="ובלכתך בדרך" target="_blank"><img src="images/OnYourWay_logo.jpg" alt="ובלכתך בדרך" width="80" height="80"/></a>
<a href="http://www.toratemetfreeware.com/index.html?downloads;1;" title="תורת אמת" target="_blank"><img src="images/toratemet.png" alt="תורת אמת" width="80" height="80"/></a>
<!--a href="https://github.com/projectbenyehuda/public_domain_dump" title="פרוייקט בן יהודה" target="_blank"><img src="images/Project Ben-Yehuda logo.jpg" alt="פרוייקט בן יהודה" width="80" height="80"/></a -->

the PDF viewer is powered by [pdfrx](https://pub.dev/packages/pdfrx).

for automatic updates, i used [updat](https://pub.dev/packages/updat).

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/sivan22/otzaria.svg?style=for-the-badge
[contributors-url]: https://github.com/sivan22/otzaria/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/sivan22/otzaria.svg?style=for-the-badge
[forks-url]: https://github.com/sivan22/otzaria/network/members
[stars-shield]: https://img.shields.io/github/stars/sivan22/otzaria.svg?style=for-the-badge
[stars-url]: https://github.com/sivan22/otzaria/stargazers
[issues-shield]: https://img.shields.io/github/issues/sivan22/otzaria.svg?style=for-the-badge
[issues-url]: https://github.com/sivan22/otzaria/issues
[license-shield]: https://img.shields.io/github/license/sivan22/otzaria.svg?style=for-the-badge
[license-url]: https://github.com/sivan22/otzaria/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/othneildrew
[product-screenshot]: images/screenshot.png
[dart]: https://img.shields.io/badge/dart-000000?style=for-the-badge&logo=dart&logoColor=61DAFB
[Dart-url]: https://dart.dev/
[Flutter]: https://img.shields.io/badge/Flutter-20232A?style=for-the-badge&logo=flutter&logoColor=61DAFB
[Flutter-url]: https://flutter.dev/
[Vue.js]: https://img.shields.io/badge/Vue.js-35495E?style=for-the-badge&logo=vuedotjs&logoColor=4FC08D
[Vue-url]: https://vuejs.org/
[Angular.io]: https://img.shields.io/badge/Angular-DD0031?style=for-the-badge&logo=angular&logoColor=white
[Angular-url]: https://angular.io/
[Svelte.dev]: https://img.shields.io/badge/Svelte-4A4A55?style=for-the-badge&logo=svelte&logoColor=FF3E00
[Svelte-url]: https://svelte.dev/
[Laravel.com]: https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white
[Laravel-url]: https://laravel.com
[Bootstrap.com]: https://img.shields.io/badge/Bootstrap-563D7C?style=for-the-badge&logo=bootstrap&logoColor=white
[Bootstrap-url]: https://getbootstrap.com
[JQuery.com]: https://img.shields.io/badge/jQuery-0769AD?style=for-the-badge&logo=jquery&logoColor=white
[JQuery-url]: https://jquery.com 
