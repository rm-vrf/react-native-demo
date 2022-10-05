import React, {useRef, useState} from 'react';
import { Image, Button, StyleSheet } from 'react-native';
import ArcGISMapView, { setLicenseKey } from './AGSMapView';

const Map = () => {
    const key = 'AAPKc85619ab61144011b89e94bd99e0a55cJXjNQG8TIn_54f2fp1azph9IB-PXQPCkJorOQirjGhb5wt7D6EreTHFLPkyIestQ';
    const points = [
        {
            latitude: 34.0005930608889,
            longitude: -118.80657463861,
            //scale: 10000.0,
        },
        {
            latitude: 42.361145,
            longitude: -71.057083,
            //scale: 9027.977411,
        },
    ];
    const overlay = {
        referenceId: 'graphicsOverlay',
        points: [{
            latitude: 34.00531212532058,
            longitude: -118.80930002749008,
            rotation: 0,
            referenceId: 'Birdview Ave',
            graphicId: 'normalPoint',
        }, {
            latitude: 42.361145,
            longitude: -71.057083,
            rotation: 0,
            referenceId: 'Boston',
            graphicId: 'personPoint',
        }],
        pointGraphics: [{
            graphicId: 'normalPoint',
            graphic: Image.resolveAssetSource(require('../image/normalpoint.png')),
        },{
            graphicId: 'personPoint',
            graphic: Image.resolveAssetSource(require('../image/personpoint.png')),
        }]
    };
    console.log('overlay', overlay);
    const addOverlay = {
        overlayReferenceId: 'graphicsOverlay',
        points: [{
            latitude: 34.00091489824838,
            longitude: -118.8068756989962,
            rotation: 0,
            referenceId: 'Point Dume',
            graphicId: 'planePoint',
        }],
        pointGraphics: [{
            graphicId: 'planePoint',
            graphic: Image.resolveAssetSource(require('../image/planepoint.png')),
        }]
    };
    const updateOverlay = {
        overlayReferenceId: 'graphicsOverlay',
        animated: true,
        updates: [{
            referenceId: 'Point Dume',
            latitude: 34.00180158650602,
            longitude: -118.80625773294051,
            graphicId: 'personPoint',
        }],
    };
    const callout = {
        title: 'Cliffside Dr',
        text: 'Cliffside Dr, Malibu, CA 90265 | Spokeo',
        shouldRecenter: true,
        point: {
            latitude: 34.007161186714214,
            longitude: -118.8004553264204,
        },
    };
    const ids = ['5be0bc3ee36c4e058f7b3cebc21c74e6', '92ad152b9da94dee89b9e387dfe21acd'];
    const [ center, setCenter ] = useState(points[0]);
    const [ basemap, setBasemap ] = useState('');
    var zoomLevel = 2;
    var scale = 10000000;

    let agsView = useRef(null);
    setLicenseKey(key);

    return (
        <>
            <Button 
                title='Change map center' 
                onPress={() => {
                    const i = points[0].latitude === center.latitude ? 1 : 0;
                    setCenter(points[i]);
                    agsView.recenterMap([center]);
                }}>
            </Button>
            <Button 
                title='Zoom map'
                onPress={() => {
                    zoomLevel = zoomLevel >= 20 ? 2 : zoomLevel + 2; 
                    console.log("zoomLevel", zoomLevel);
                    agsView.zoomMap(zoomLevel); 
                }}
            ></Button>
            <Button 
                title='Scale map'
                onPress={() => {
                    scale = scale <= 10000 ? 10000000 : scale / 2; 
                    console.log("scale", scale);
                    agsView.scaleMap(scale); 
                }}
            ></Button>
            {/* <Button 
                title='Change basemap' 
                onPress={() => { setBasemap(basemap === ids[0] ? ids[1] : ids[0]); }}>
            </Button> */}
            <Button 
                title='Add overlay'
                onPress={() => { agsView.addGraphicsOverlay(overlay); }}>
            </Button>
            <Button 
                title='Add point'
                onPress={() => { agsView.addPointsToOverlay(addOverlay); }}>
            </Button>
            <Button 
                title='Move point'
                onPress={() => { agsView.updatePointsOnOverlay(updateOverlay); }}>
            </Button>
            <Button 
                title='Remove point'
                onPress={() => { agsView.removePointsFromOverlay({overlayReferenceId: 'graphicsOverlay', referenceIds: ['Point Dume']}); }}>
            </Button>
            <Button 
                title='Remove overlay'
                onPress={() => { agsView.removeGraphicsOverlay('graphicsOverlay'); }}>
            </Button>
            <Button 
                title='Callout'
                //onPress={() => { agsView.showCallout(callout); }}>
                onPress={() => { agsView.getVisibleAreaVia().then(result => {console.log(result)}) }}>
            </Button>
            <ArcGISMapView
                style={styles.map} 
                ref={element => agsView = element}
                initialMapCenter={[center]}
                recenterIfGraphicTapped={true}
                //basemapUrl={'https://www.arcgis.com/home/item.html?id=' + basemap}
                //basemapUrl={'https://basemaps.arcgis.com/arcgis/rest/services/World_Basemap_v2/VectorTileServer'}
                //basemapUrl={'http://gis.cityofboston.gov/arcgis/rest/services/SampleWorldCities/MapServer'}//NG
                //basemapUrl={'http://gis.cityofboston.gov/arcgis/rest/services/CityServices/OpenData/MapServer'}//NG
                //basemapUrl={'https://gis.dogami.oregon.gov/arcgis/rest/services/Public/MtHoodCritFac/MapServer'}//NG
                //basemapUrl={'https://sampleserver5.arcgisonline.com/arcgis/rest/services/Elevation/WorldElevations/MapServer'}//ImageLayer
                //basemapUrl={'https://sampleserver5.arcgisonline.com/arcgis/rest/services/Census/MapServer'}//ImageLayer
                //basemapUrl={'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer'}//TiledLayer
                onMapDidLoad={e => { console.log('onMapDidLoad', e.nativeEvent) }} 
                onSingleTap={e => { console.log('onSingleTap', e.nativeEvent) }} 
                onLongPress={e => { console.log('onLongPress', e.nativeEvent) }}
                //onMapMoved={e => { console.log('onMapMoved', e.nativeEvent) }} 
                onOverlayWasAdded = {e => { console.log('onOverlayWasAdded', e.nativeEvent) }}
                onOverlayWasModified = {e => { console.log('onOverlayWasModified', e.nativeEvent) }}
                onOverlayWasRemoved = {e => { console.log('onOverlayWasRemoved', e.nativeEvent) }}
                spatialReference = {{ wkid: 4326 }}
                //spatialRef = {{ wkid: 4326 }}
            />
        </>
    );
};

const styles = StyleSheet.create({
    map: {
      flex: 4,
    },
});

export default Map;