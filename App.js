/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow strict-local
 */

import * as React from 'react';
import { Text, Button, Image } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import NativeMethod from './components/NativeMethod';
import BarcodeScanner from './components/BarcodeScanner';

const Stack = createNativeStackNavigator();

const App = () => {
  return (
    <NavigationContainer>
      <Stack.Navigator>
        <Stack.Screen name="Home" component={HomeScreen} options={{ title: 'React Native Demo' }} />
        <Stack.Screen name="Profile" component={ProfileScreen} />
        <Stack.Screen name="NativeMethod" component={NativeMethod} />
        <Stack.Screen name="BarcodeScanner" component={BarcodeScanner} />
      </Stack.Navigator>
    </NavigationContainer>
  );
};

const HomeScreen = ({ navigation }) => {
  return (
    <>
      <Button title="Go to profile" onPress={() => navigation.navigate('Profile', { name: 'Lane' })} />
      <Button title="Call native method" onPress={() => navigation.navigate('NativeMethod', {})} />
      <Button title="Scan barcode" onPress={() => navigation.navigate('BarcodeScanner', {})} />
    </>
  );
};

const ProfileScreen = ({ navigation, route }) => {
  return (
    <>
      <Text>This is {route.params.name}'s profile</Text>
      <Image source={{uri: 'https://clipground.com/images/desert-biome-outline-clipart-2.jpg'}}
        style={{width: 195, height: 136}} />
    </>
  );
};

export default App;
