/**
 * @format
 */

import {AppRegistry} from 'react-native';
import App from './App';
import {name as appName} from './app.json';
import messaging from '@react-native-firebase/messaging';

// Receive notification message when app is off or in background
messaging().setBackgroundMessageHandler(async remoteMessage => {
    console.log("Message handler in background, ", remoteMessage);
});

AppRegistry.registerComponent(appName, () => App);
