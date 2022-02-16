React Native Demo
====

## Development Environment

- Node v17.5.0
- NPM 8.4.1
- Yarn 1.22.17
- CocoaPods 1.11.2
- Xcode 13.2

## Create Project

```
react-native init ReactNativeDemo
```

React Native CLI creates code structure for you, containing `ios` and `android` folder. Run `pod install` automaticly to resolve dependencies in iOS project.

When you want to install new components in project, firstly need to install them in node project. For example: 

```
yarn add @react-navigation/native @react-navigation/native-stack
yarn add react-native-screens react-native-safe-area-context
```

For iOS with bare React Native project, make sure you have Cocoapods installed. Then install the pods to complete the installation:

```
cd ios
pod install
cd ..
```

## Build Project

```
yarn install
cd ios
pod install
cd ..
```

Open `ios/ReactNativeDemo.xcworkspace` with Xcode. Press Command+B to build this app.

## Run App for Debug

To debug the app on simulator or real device, must run up launch packager first:

```
yarn run start
```

Open `ios/ReactNativeDemo.xcworkspace` with Xcode. Press Command+R to run app on iPhone.

Make sure to start the simulator before start launch packager, this way the auto refresh can take effect. You can see the app screen refresh on the silulator after you change the code.

To debug the app, press Command+D on simulator to call out the developer menu. Click 'Debug with Chrome'. 

Open http://localhost:8081/debugger-ui/ with Chrome. You can see the React Native Debugger on the screen. It holds a debugger session. Follow the instruments on the page, press Command+Option+I to open the developer tools. 

In 'Console' tab, you can see the `console.log` output in the app.

In 'Sources' tab, you can setup the breakpoint and watch the local variations' value to debug the code.

You may also install the standalone version of React Developer Tools to inspect the React component hierarchy, their props, and state.

To run the app on real device, connect the Xcode to a iPhone and switch the device setting before Command+R. You can shake the device to call out the developer menu on iPhone.