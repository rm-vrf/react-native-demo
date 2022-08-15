import React, {useEffect, useRef, useState} from 'react';
import { Text, Image, Button, StyleSheet } from 'react-native';
import RNFetchBlob from 'rn-fetch-blob';
import { unzip } from 'react-native-zip-archive'
import ArcGISMapView, { setLicenseKey } from './AGSMapView';

const MapOffline = () => {
    const key = 'AAPKc85619ab61144011b89e94bd99e0a55cJXjNQG8TIn_54f2fp1azph9IB-PXQPCkJorOQirjGhb5wt7D6EreTHFLPkyIestQ';
    const basemapURL = 'https://www.arcgis.com/sharing/rest/content/items/b5106355f1634b8996e634c04b6a930a/data';
    const basemapName = 'FillmoreTopographicMap.vtpk';
//    const gdbURL = 'https://www.arcgis.com/sharing/rest/content/items/e12b54ea799f4606a2712157cf9f6e41/data';
//    const gdbName = 'ContingentValuesBirdNests.geodatabase';
    const gdbURL = 'https://www.arcgis.com/sharing/rest/content/items/74c0c9fa80f4498c9739cc42531e9948/data';
    const gdbName = 'loudoun_anno.geodatabase';
    const { config, fs } = RNFetchBlob;
    const documentDir = fs.dirs.DocumentDir;
    const [ message, setMessage ] = useState('N/A'); 
    const [ basemap, setBasemap ] = useState('');
    let agsView = useRef(null);
    const options = {
        fileCache: true,
        addAndroidDownloads: {
            path: documentDir,
            description: 'downloading file...',
            notification: false,
            useDownloadManager: false,
        }
    };
    const center = {
//        latitude: 34.38941562189429,
//        longitude: -118.90099973080952,
        latitude: 39.02021585807587,
        longitude: -77.41744847727631,
        scale: 9027.977411,
    };
    const addGeodatabaseArg = {
        referenceId: gdbName,
        geodatabaseURL: 'file://' + documentDir + '/' + gdbName,
        featureLayers: [{
            referenceId: 'ParcelLines_1',
            tableName: 'ParcelLines_1',
            definitionExpression: 'Length > 0',
        }],
        annotationLayers: [{
            referenceId: 'ParcelLinesAnno_1',
            tableName: 'ParcelLinesAnno_1',
        }],
    };
    const addLayersToGeodatabaseArg = {
        geodatabaseReferenceId: gdbName, 
        featureLayers: [{
            referenceId: 'Loudoun_Address_Points_1',
            tableName: 'Loudoun_Address_Points_1',
        }], 
        annotationLayers: [{
            referenceId: 'Loudoun_Address_PointsAnno_1',
            tableName: 'Loudoun_Address_PointsAnno_1',
        }]
    };
    const removeLayersFromGeodatabaseArg = {
        geodatabaseReferenceId: gdbName, 
        featureLayerReferenceIds: ['Loudoun_Address_Points_1'],
        annotationLayerReferenceIds: ['Loudoun_Address_PointsAnno_1'],
    };

    setLicenseKey(key);

    const downloadAndUnzip = (url, filename) => {
        config(options).fetch('GET', url).then(res => {
            console.log('res', res);
            if (res.respInfo && res.respInfo.status) {
                var msg = 'HTTP status: ' + res.respInfo.status;
                setMessage(msg);
                if (res.respInfo.status === 200) {
                    unzip(res.data, documentDir).then(path => {
                        fs.unlink(res.data);
                        msg += ', unzip file: ' + filename;
                        setMessage(msg);
                    });
                }
            }
        });
    };

    const downloadAndMove = (url, filename) => {
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

    const callout = (e) => {
        console.log('onSingleTap', e);
        let arg = {
            title: 'Geo Element',
            text: JSON.stringify(e.geoElementAttributes),
            shouldRecenter: false,
            point: {
                latitude: e.mapPoint.latitude,
                longitude: e.mapPoint.longitude
            }
        };
        agsView.showCallout(arg);
    };

    return (
        <>
            <Text>{message}</Text>
            <Button 
                title='Download basemap'
                onPress={() => {
                    setMessage('downloading...');
                    downloadAndMove(basemapURL, basemapName);
                }}
            />
            <Button 
                title='Load offline map'
                onPress={() => {
                    setBasemap('file://' + documentDir + '/' + basemapName);
                }}
            />
            <Button 
                title='Download geodatabase'
                onPress={() => {
                    setMessage('downloading...');
                    downloadAndUnzip(gdbURL, gdbName);
                }}
            />
            <Button 
                title='Show geodatabase'
                onPress={() => {
                    agsView.addGeodatabase(addGeodatabaseArg);
                }}
            />
            <Button 
                title='Add geodatabase layer'
                onPress={() => {
                    agsView.addLayersToGeodatabase(addLayersToGeodatabaseArg);
                }}
            />
            <Button 
                title='Remove geodatabase layer'
                onPress={() => {
                    agsView.removeLayersFromGeodatabase(removeLayersFromGeodatabaseArg);
                }}
            />
            <Button 
                title='Remove geodatabase'
                onPress={() => {
                    agsView.removeGeodatabase(gdbName);
                }}
            />
            <ArcGISMapView
                style={styles.map} 
                ref={element => agsView = element}
                basemapUrl={basemap}
                initialMapCenter={[center]}
                recenterIfGraphicTapped={false}
                onMapDidLoad={e => { console.log('onMapDidLoad', e.nativeEvent) }} 
                onSingleTap={e => { callout(e.nativeEvent) }} 
                onMapMoved={e => { console.log('onMapMoved', e.nativeEvent) }} 
                onGeodatabaseWasAdded = {e => { console.log('onGeodatabaseWasAdded', e.nativeEvent) }}
                onGeodatabaseWasModified = {e => { console.log('onGeodatabaseWasModified', e.nativeEvent) }}
                onGeodatabaseWasRemoved = {e => { console.log('onGeodatabaseWasRemoved', e.nativeEvent) }}
            />
        </>
    );
};

const styles = StyleSheet.create({
    map: {
      flex: 4,
    },
});

export default MapOffline;