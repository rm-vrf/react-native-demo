import * as React from 'react';
import { Text, View } from 'react-native';

const RemoteNotification = ({ navigation, route }) => {
    return <Text>RemoteNotification: {route.params.message}</Text>
}

export default RemoteNotification;