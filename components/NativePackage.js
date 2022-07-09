import * as React from 'react';
import { Text, Button } from 'react-native';
import CalendarModule from 'react-native-develop-branch-toast';

const NativePackage = () => {
  const [value, setValue] = React.useState('Hello');

  const clickMe = () => {
    console.log('Click me!');
    CalendarModule.createCalendarEvent('testName', 'testLocation').then(eventId => {
      console.log('get eventId: %s', eventId);
      setValue('get value from native method: ' + eventId);
    }).catch(error => {
      console.log('error: %s', error);
      setValue('get error from native method:' + error);
    });
  };

  return (
    <>
      <Text>Hello native package!</Text>
      <Button title='Test' onPress={clickMe}></Button>
      <Text>{value}</Text>
    </>
  );
};

export default NativePackage;