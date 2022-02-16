import * as React from 'react';
import { NativeModules, Text, Button } from 'react-native';

const BarcodeScanner = () => {
    const [code, setCode] = React.useState({type: null, value: null});

    const { BarcodeScannerWrapper } = NativeModules;
    console.log(BarcodeScannerWrapper);

    React.useEffect(() => {
        console.log('didLoad');
        setCode({
            type: BarcodeScannerWrapper.defaultType,
            value: BarcodeScannerWrapper.defaultValue
        });
    }, []);

    const clickMe = () => {
        console.log('scan barcode');
        BarcodeScannerWrapper.scanBarcode().then(resp => {
            console.log("barcode scan result: " + resp);
            setCode(resp);
        }).catch(error => {
            console.log("barcode scan error: " + error);
            setCode({
                type: BarcodeScannerWrapper.defaultType,
                value: error.toString()
            });
        });
    };

    return (
        <>
            <Text>This is barcode/QR code scanner screen. Show how to scan barcode/QR code and get result (barcode type and value) from native method.</Text>
            <Button title='Scan barcode' onPress={clickMe} />
            <Text>Barcode type: {code.type}, value: {code.value}</Text>
        </>
    )
};

export default BarcodeScanner;