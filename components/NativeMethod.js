import * as React from 'react';
import { Text, Button } from 'react-native';

const NativeMethodScreen = () => {
    const clickMe = () => {
      setValue(value === 'Hello' ? 'World' : 'Hello');
      console.log('Click me! %s', value);
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
  
  export default NativeMethodScreen;
  