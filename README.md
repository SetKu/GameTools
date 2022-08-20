# Game Tools

![Swift](https://img.shields.io/badge/Swift%205-FA7343?style=for-the-badge&logo=swift&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode%2014-007ACC?style=for-the-badge&logo=Xcode&logoColor=white)
![Platforms](https://img.shields.io/badge/Platform-macOS%20|%20iOS%20|%20iPadOS-007ACC?style=for-the-badge)

<div align="center">
	<img src="https://i.postimg.cc/gcQj1V4w/RPReplay-Final1661020893.gif" alt="Game Tools Demo" style="border-radius:12px"/>
</div>

## About

Game Tools is a small app for Apple platforms (untested on macOS) designed to supply fun tools for various board games. So far, only two tools have been developed for the board game Risk™️. However, I hope to grow this project into the future with further tools for games such as Chess and Monopoly. This project was created out of a love for board games and joy at creating tools for the localized logical problems they propose.

This project was developed to run on iOS 16 using the Xcode 14 beta, so this project may not run properly when the OS is released and won't build for lower targets. For one, it leverages new Swift features in the realm of syntax and the new Charts framework for SwiftUI by Apple.

In the `RiskEngine` object I have developed an `AI` embedded object which is a partially finished method of modelling out how to simulate an entire game of Risk. However, I shortly abandoned the code project after realizing the sheer variation in rules between different editions and sets of the board game. Feel free to take a look for inspiration on how to possibly create AIs for other games.

Feel free to make a pull request. I'd love to see this small project become something bigger with time.

Copyright © 2022 Zachary Morden
