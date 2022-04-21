import React, { useState } from "react";
import { Text, TextInput } from 'react-native';

const RemoteNotification = ({ navigation, route }) => {
    const [ params, setParams ] = useState({
        remoteMessage: null, 
        fcmToken: null
    }); 

    const { remoteMessage, fcmToken } = route.params;
    if (remoteMessage) {
        params.remoteMessage = remoteMessage;
    }
    if (fcmToken) {
        params.fcmToken = fcmToken;
    }

    return (
        <>
            <Text style={{ fontWeight: "bold" }}>FCM Token: </Text>
            <TextInput multiline numberOfLines={8} value={params.fcmToken}/>
            <Text style={{ fontWeight: "bold" }}>Remote Notification:</Text>
            <Text>{JSON.stringify(params.remoteMessage)}</Text>
        </>
    );
}

export default RemoteNotification;