import * as React from 'react';
import { Text, View } from 'react-native';
import NetInfo from '@react-native-community/netinfo';

const NetInfoDemo = () => {
    const [stat, setStat] = React.useState({});
    const [isLoading, setIsLoading] = React.useState(true);

    NetInfo.configure({
        reachabilityUrl: "https://www.baidu.com/",
        reachabilityTest: async (response) => response.status >= 200 && response.status < 400,
    });

    NetInfo.addEventListener((state) => {
        setStat(state);
    });

    const netInfoState = NetInfo.useNetInfo();
    const { type, isInternetReachable } = netInfoState;

    React.useEffect(() => {
        if (type !== 'unknown' && typeof isInternetReachable === 'boolean') {
            setIsLoading(false);
        }
    }, [type, isInternetReachable]);

    return (
        <>
            <Text>state: {JSON.stringify(stat)}</Text>
            <Text>type: {type}, isInternetReachable: {isInternetReachable}</Text>
        </>
    );
};

export default NetInfoDemo;