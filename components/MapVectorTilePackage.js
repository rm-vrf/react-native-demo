import React, {useEffect, useRef, useState} from 'react';
import { Text, Image, Button, StyleSheet } from 'react-native';
import RNFetchBlob from 'rn-fetch-blob';
import { unzip } from 'react-native-zip-archive'
import ArcGISMapView, { setLicenseKey } from './AGSMapView';

const MapVectorTilePackage = () => {
    const key = 'AAPKc85619ab61144011b89e94bd99e0a55cJXjNQG8TIn_54f2fp1azph9IB-PXQPCkJorOQirjGhb5wt7D6EreTHFLPkyIestQ';
    const basemapURL = 'https://www.arcgis.com/sharing/rest/content/items/b5106355f1634b8996e634c04b6a930a/data';
    const basemapName = 'FillmoreTopographicMap.vtpk';
    const { config, fs } = RNFetchBlob;
    const documentDir = fs.dirs.DocumentDir;
    const [ message, setMessage ] = useState('N/A'); 
    const [ basemap, setBasemap ] = useState('');
    let agsView = useRef(null);

    setLicenseKey(key);

    const downloadBasemap = (url, filename) => {
        let options = {
            fileCache: true,
            addAndroidDownloads: {
                path: documentDir,
                description: 'downloading file...',
                notification: false,
                useDownloadManager: false,
            }
        };
        config(options).fetch('GET', url).then(res => {
            console.log('res', res);
            if (res.respInfo && res.respInfo.status) {
                var msg = 'HTTP status: ' + res.respInfo.status;
                setMessage(msg);
                if (res.respInfo.status === 200) {
                    fs.mv(res.data, documentDir + '/' + filename);
                    msg += ', move file: ' + filename;
                    setMessage(msg);
                }
            }
        });
    };

    return (
        <>
            <Text>{message}</Text>
            <Button 
                title='Download basemap'
                onPress={() => {
                    setMessage('downloading...');
                    downloadBasemap(basemapURL, basemapName);
                }}
            />
            <Button 
                title='Load offline map'
                onPress={() => {
                    setBasemap('file://' + documentDir + '/' + basemapName);
                }}
            />
            <Button 
                title='Add Base Layer'
                onPress={() => {
                    agsView.addBaseLayer({referenceId: 'baseLayerId', url: 'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer'});
                }}
            />
            <Button 
                title='Remove Base Layer'
                onPress={() => {
                    agsView.removeBaseLayer('baseLayerId');
                }}
            />
            <ArcGISMapView
                style={styles.map} 
                ref={element => agsView = element}
                basemapUrl={basemap}
                recenterIfGraphicTapped={false}
                onMapDidLoad={e => { console.log('onMapDidLoad', e.nativeEvent) }} 
                onSingleTap={e => { console.log('onSingleTap', e.nativeEvent) }} 
                onOverlayWasModified = {e => { console.log('onOverlayWasModified', e.nativeEvent) }}
            />
        </>
    );
};

const styles = StyleSheet.create({
    map: {
      flex: 4,
    },
});

export default MapVectorTilePackage;