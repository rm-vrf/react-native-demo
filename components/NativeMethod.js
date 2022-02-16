import * as React from 'react';
import { NativeModules, Text, Button } from 'react-native';

const NativeMethod = () => {
    const { CalendarModule } = NativeModules;

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
  
    const [value, setValue] = React.useState('Hello');
  
    return (
      <>
        <Text>This is native method screen. Show how to call native method and get callback result on this screen.</Text>
        <Button title='Test' onPress={clickMe}></Button>
        <Text>{value}</Text>
      </>
    );
  };
  
  export default NativeMethod;
  