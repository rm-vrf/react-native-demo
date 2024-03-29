//
//  RNArcGISMapView.swift
//  SampleArcGIS
//
//  Created by David Galindo on 1/31/19.
//  Copyright © 2019 David Galindo. All rights reserved.
//

import UIKit
import ArcGIS

@objc(RNArcGISMapView)
public class RNArcGISMapView: AGSMapView, AGSGeoViewTouchDelegate {
    // MARK: Properties
    var routeGraphicsOverlay = AGSGraphicsOverlay()
    var geodatabases: [NSString: RNAGSGeodatabase] = [:]
    var router: RNAGSRouter?
    var bridge: RCTBridge?
    var spaRef: AGSSpatialReference = AGSSpatialReference.wgs84()
  var baseLayers: [String: AGSLayer] = [:]
  var mapExporter: RNAGSMapExporter?
  static var apiKey: String?
    
    // MARK: Initializers and helper methods
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpMap()
      mapExporter = RNAGSMapExporter(mapView: self, progressEvent: onMapExportProgress)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpMap()
      mapExporter = RNAGSMapExporter(mapView: self, progressEvent: onMapExportProgress)
    }
    
    func setUpMap() {
        // Default is to Esri HQ
      if let apiKey = RNArcGISMapView.apiKey {
        AGSArcGISRuntimeEnvironment.apiKey = apiKey
      }
      self.map = AGSMap(basemapStyle: .arcGISStreets)
        self.map?.load(completion: {[weak self] (error) in
            if (self?.onMapDidLoad != nil){
                var reactResult: [AnyHashable: Any] = ["success" : error == nil]
                if (error != nil) {
                    reactResult["errorMessage"] = error!.localizedDescription
                }
                self?.onMapDidLoad!(reactResult)
            }
        })
        self.touchDelegate = self
        self.graphicsOverlays.add(routeGraphicsOverlay)
        self.viewpointChangedHandler = { [weak self] in
            self?.raiseOnMapMoved()
        }
    }
    
    // MARK: Native methods
    @objc public func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        self.callout.dismiss()
        if let onSingleTap = onSingleTap {
            raiseEvent(event: onSingleTap, screenPoint: screenPoint, mapPoint: mapPoint)
        }
    }
    
    @objc public func geoView(_ geoView: AGSGeoView, didLongPressAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        self.callout.dismiss()
        if let onLongPress = onLongPress {
            raiseEvent(event: onLongPress, screenPoint: screenPoint, mapPoint: mapPoint)
        }
    }

    func raiseEvent(event: @escaping RCTDirectEventBlock, screenPoint: CGPoint, mapPoint: AGSPoint) {
        let latLongPoint = AGSGeometryEngine.projectGeometry(mapPoint, to: spaRef) as! AGSPoint
        var reactResult: [AnyHashable: Any] = [
            "mapPoint": ["latitude" : latLongPoint.y, "longitude": latLongPoint.x],
            "screenPoint" : ["x": screenPoint.x, "y": screenPoint.y]
        ]
      
        // Geodatabase feature layer & annotation layer
        var layers: [AGSLayer] = []
        if let operationalLayers = self.map?.operationalLayers as? [AGSLayer] {
            layers.append(contentsOf: operationalLayers)
        }
      
        if !layers.isEmpty {
            // Identity feature layer & annotation layer
            for layer in layers {
                self.identifyLayer(layer, screenPoint: screenPoint, tolerance: 15, returnPopupsOnly: false, maximumResults: 10) {[weak self] (result) in
                    if let error = result.error {
                        reactResult["success"] = false
                        reactResult["errorMessage"] = error.localizedDescription
                    } else {
                        reactResult["success"] = true
                    }
                    guard !result.geoElements.isEmpty else {
                        event(reactResult)
                        return
                    }
                    for element in result.geoElements {
                        //print("\(item.attributes)")
                        reactResult["geoElementAttributes"] = element.attributes
                        if self?.recenterIfGraphicTapped ?? false {
                            self?.setViewpointCenter(mapPoint, completion: nil)
                        }
                    }
                    event(reactResult)
                }
            }
        } else {
            // Identity graphics overlay
            self.identifyGraphicsOverlays(atScreenPoint: screenPoint, tolerance: 15, returnPopupsOnly: false) { [weak self] (result, error) in
                if let error = error {
                    reactResult["success"] = false
                    reactResult["errorMessage"] = error.localizedDescription
                } else {
                    reactResult["success"] = true
                }
                guard let result = result, !result.isEmpty else {
                    event(reactResult)
                    return
                }
                for item in result {
                    if item.graphicsOverlay is RNAGSGraphicsOverlay, let closestGraphic = item.graphics.first, let referenceId = closestGraphic.attributes["referenceId"] as? NSString{
                        reactResult["graphicReferenceId"] = referenceId
                        if self?.recenterIfGraphicTapped ?? false {
                            self?.setViewpointCenter(mapPoint, completion: nil)
                        }
                    }
                }
                event(reactResult)
            }
        }
    }

    func raiseOnMapMoved() {
        if let onMapMoved = onMapMoved {
            let env = AGSGeometryEngine.projectGeometry(self.visibleArea!.extent, to: spaRef) as! AGSEnvelope
            //print("viewpointChangedHandler \(env.xMin), \(env.xMax), \(env.yMin), \(env.yMax), \(env.center.x), \(env.center.y), \(env.width), \(env.height)")
            let reactResult: [AnyHashable: Any] = [
                "mapPoint" : ["latitude" : env.center.y, "longitude": env.center.x]
            ]
            onMapMoved(reactResult)
        }
    }
    
    // MARK: Exposed RN Event Emitters
    @objc var onSingleTap: RCTDirectEventBlock?
    @objc var onLongPress: RCTDirectEventBlock?
    @objc var onMapDidLoad: RCTDirectEventBlock?
    @objc var onOverlayWasModified: RCTDirectEventBlock?
    @objc var onOverlayWasAdded: RCTDirectEventBlock?
    @objc var onOverlayWasRemoved: RCTDirectEventBlock?
    @objc var onMapMoved: RCTDirectEventBlock?
    @objc var onGeodatabaseWasAdded: RCTDirectEventBlock?
    @objc var onGeodatabaseWasModified: RCTDirectEventBlock?
    @objc var onGeodatabaseWasRemoved: RCTDirectEventBlock?
  @objc var onMapExportProgress: RCTDirectEventBlock?
    
    // MARK: Exposed RN methods
    @objc func showCallout(_ args: NSDictionary) {
        let point = args["point"] as? NSDictionary
        guard let latitude = point?["latitude"] as? NSNumber, let longitude = point?["longitude"] as? NSNumber,
            let title = args["title"] as? NSString, let text = args["text"] as? NSString, let shouldRecenter = args["shouldRecenter"] as? Bool
            else {
                print("WARNING: The point object did not contian a proper latitude and longitude.")
                return
        }
        let agsPoint = AGSPoint(x: longitude.doubleValue, y: latitude.doubleValue, spatialReference: spaRef)
        self.callout.title = String(title)
        self.callout.detail = String(text)
        self.callout.isAccessoryButtonHidden = true
        if shouldRecenter {
            self.setViewpointCenter(agsPoint) { [weak self](_) in
                self?.callout.show(at: agsPoint, screenOffset: CGPoint.zero, rotateOffsetWithMap: false, animated: true)
            }
        } else {
            self.callout.show(at: agsPoint, screenOffset: CGPoint.zero, rotateOffsetWithMap: false, animated: true)
        }
    }
    
    @objc func centerMap(_ args: NSArray) {
        var points = [AGSPoint]()
        if let argsCasted = args as? [NSDictionary] {
            for rawPoint in argsCasted {
                if let latitude = rawPoint["latitude"] as? NSNumber, let longitude = rawPoint["longitude"] as? NSNumber {
                    points.append(AGSPoint(x: longitude.doubleValue, y: latitude.doubleValue, spatialReference: spaRef))
                }
            }
        }
        if (points.count == 0){
            print("WARNING: Recenter point array was empty or contained invalid data.")
        } else if points.count == 1 {
            self.setViewpointCenter(points.first!)
        } else {
            let polygon = AGSPolygon(points: points)
            self.setViewpointGeometry(polygon, padding: 50, completion: nil)
        }
    }
    
    @objc func scaleMap(_ args: NSNumber) {
        let scale = args.doubleValue
        self.setViewpointScale(scale)
    }

    @objc func zoomMap(_ args: NSNumber) {
        let scale = 591657550.5 / pow(2, args.doubleValue)
        scaleMap(NSNumber(value: scale))
    }
    
    @objc func addGraphicsOverlay(_ args: NSDictionary) {
        let rnRawGraphicsOverlay = RNAGSGraphicsOverlay(rawData: args, spaRef: spaRef)
        self.graphicsOverlays.add(rnRawGraphicsOverlay)
        if (onOverlayWasAdded != nil) {
            onOverlayWasAdded!([NSString(string: "referenceId"): rnRawGraphicsOverlay.referenceId]);
        }
    }
    
    @objc func addPointsToGraphicsOverlay(_ args: NSDictionary) {
        guard let name = args["overlayReferenceId"] as? NSString,  let overlay = getOverlay(byReferenceId: name) else {
            print("WARNING: Invalid layer name entered. No points will be added.")
            reportToOverlayDidLoadListener(referenceId: args["overlayReferenceId"] as? NSString ?? NSString(string:"unknown"), action: "add", success: false, errorMessage: "Invalid layer name entered.")
            return
        }
        guard let rawPointsCasted = args["points"] as? [NSDictionary] else {
            print("WARNING: No reference IDs provided. No points will be added.")
            reportToOverlayDidLoadListener(referenceId: name, action: "add", success: false, errorMessage: "No reference IDs provided.")
            
            return
        }
        // Create point image dictionary
        var pointImageDictionary: [NSString: UIImage] = [:]
        if let pointGraphics = args["pointGraphics"] as? [NSDictionary] {
            for item in pointGraphics {
                if let graphicId = item["graphicId"] as? NSString, let graphic = RCTConvert.uiImage(item["graphic"]) {
                    pointImageDictionary[graphicId] = graphic
                }
            }
        }
        for item in rawPointsCasted {
            if let point = RNAGSGraphicsOverlay.createPoint(rawData: item) {
                let graphic = RNAGSGraphicsOverlay.rnPointToAGSGraphic(point, pointImageDictionary: pointImageDictionary)
                overlay.graphics.add(graphic)
            }
        }
        reportToOverlayDidLoadListener(referenceId: name, action: "add", success: true, errorMessage: nil)
    }
    
    @objc func removePointsFromGraphicsOverlay(_ args: NSDictionary) {
        guard let name = args["overlayReferenceId"] as? NSString,  let overlay = getOverlay(byReferenceId: name) else {
            print("WARNING: Invalid layer name entered. No points will be removed.")
            reportToOverlayDidLoadListener(referenceId: args["overlayReferenceId"] as? NSString ?? NSString(string:"unknown"), action: "remove", success: false, errorMessage: "Invalid layer name entered.")
            return
        }
        guard let pointsToRemove = args["referenceIds"] as? [NSString] else {
            print("WARNING: No reference IDs provided. No points will be removed.")
            reportToOverlayDidLoadListener(referenceId: name, action: "remove", success: false, errorMessage: "No reference IDs provided.")
            return
        }
        for graphic in overlay.graphics as! [AGSGraphic] {
            let id = graphic.attributes["referenceId"] as! NSString
            if pointsToRemove.contains(id) {
                overlay.graphics.remove(graphic)
            }
        }
        reportToOverlayDidLoadListener(referenceId: name, action: "remove", success: true, errorMessage: nil)
    }
    
    @objc func updatePointsInGraphicsOverlay(_ args: NSDictionary) {
        guard let name = args["overlayReferenceId"] as? NSString,  let overlay = getOverlay(byReferenceId: name) else  {
            print("WARNING: Invalid layer name entered. No points will be modified.")
            reportToOverlayDidLoadListener(referenceId: args["overlayReferenceId"] as? NSString ?? NSString(string: "Unknown"), action: "update", success: false, errorMessage: "Invalid layer name entered.")
            return
        }
        let shouldAnimateUpdate = (args["animated"] as? Bool) ?? false
        overlay.shouldAnimateUpdate = shouldAnimateUpdate
        if let updates = args["updates"] as? [NSDictionary] {
            for update in updates {
                overlay.updateGraphic(with: update)
            }
        }
        reportToOverlayDidLoadListener(referenceId: args["overlayReferenceId"] as! NSString, action: "update", success: true, errorMessage: nil)
    }
  
    @objc func addGeodatabase(_ args: NSDictionary) {
        let geodatabase = RNAGSGeodatabase(rawData: args);
        geodatabases[geodatabase.referenceId] = geodatabase
        geodatabase.geodatabaseDidLoad() {featureLayers, annotationLayers in
            var featureLayerIds:[NSString] = []
            if let featureLayers = featureLayers {
                self.map?.operationalLayers.addObjects(from: featureLayers)
                featureLayerIds.append(contentsOf: featureLayers.map({$0.referenceId}))
            }

            var annotationLayerIds: [NSString] = []
            if let annotationLayers = annotationLayers {
                self.map?.operationalLayers.addObjects(from: annotationLayers)
                annotationLayerIds.append(contentsOf: annotationLayers.map({$0.referenceId}))
            }
      
            if (self.onGeodatabaseWasAdded != nil) {
                let arg = [NSString(string: "referenceId"): geodatabase.referenceId, NSString(string: "featureLayers"): featureLayerIds, NSString(string: "annotationLayers"): annotationLayerIds] as [NSString : Any]
                self.onGeodatabaseWasAdded!(arg);
            }
        }
    }
  
    @objc func removeGraphicsOverlay(_ name: NSString) {
        guard let overlay = getOverlay(named: name) else {
            print("WARNING: Invalid layer name entered. No overlay will be removed.")
            return
        }
        self.graphicsOverlays.remove(overlay)
        if (onOverlayWasRemoved != nil) {
            onOverlayWasRemoved!([NSString(string: "referenceId"): name])
        }
    }
  
    @objc func addLayersToGeodatabase(_ args: NSDictionary) {
        guard let name = args["geodatabaseReferenceId"] as? NSString,  let geodatabase = geodatabases[name] else {
            print("WARNING: Invalid geodatabase name entered. No layers will be added.")
            reportToLayerDidLoadListener(referenceId: args["geodatabaseReferenceId"] as? NSString ?? NSString(string:"unknown"), action: "add", success: false, errorMessage: "Invalid layer name entered.", featureLayers: nil, annotationLayers: nil)
            return
        }

        geodatabase.update(rawData: args)
        geodatabase.geodatabaseDidLoad() {featureLayers, annotationLayers in
            guard let operationalLayers = self.map?.operationalLayers else {
                return
            }

            var featureLayerIds:[NSString] = []
            if let featureLayers = featureLayers {
                for featureLayer in featureLayers {
                    if !operationalLayers.contains(featureLayer) {
                        operationalLayers.add(featureLayer)
                        featureLayerIds.append(featureLayer.referenceId)
                    }
                }
            }
      
            var annotationLayerIds: [NSString] = []
            if let annotationLayers = annotationLayers {
                for annotationLayer in annotationLayers {
                    if !operationalLayers.contains(annotationLayer) {
                        operationalLayers.add(annotationLayer)
                        annotationLayerIds.append(annotationLayer.referenceId)
                    }
                }
            }
      
            self.reportToLayerDidLoadListener(referenceId: name, action: "add", success: true, errorMessage: nil, featureLayers: featureLayerIds, annotationLayers: annotationLayerIds)
        }
    }
  
    @objc func removeLayersFromGeodatabase(_ args: NSDictionary) {
        guard let name = args["geodatabaseReferenceId"] as? NSString, let _ = geodatabases[name] else {
            print("WARNING: Invalid geodatabase name entered. No layers will be modified.")
            reportToLayerDidLoadListener(referenceId: args["geodatabaseReferenceId"] as? NSString ?? NSString(string: "Unknown"), action: "remove", success: false, errorMessage: "Invalid geodatabase name entered.", featureLayers: nil, annotationLayers: nil)
            return
        }
        var featureLayerIds = args["featureLayerReferenceIds"] as? [NSString]
        var annotationLayerIds = args["annotationLayerReferenceIds"] as? [NSString]
        let layers = self.getOprationalLayers(byGeodatabaeId: name, byFeatureLayerIds: featureLayerIds, byAnnotationLayerIds: annotationLayerIds)

        featureLayerIds?.removeAll()
        annotationLayerIds?.removeAll()
        guard let operationalLayers = self.map?.operationalLayers else {
            return
        }

        for layer in layers {
            if layer is RNAGSFeatureLayer && operationalLayers.contains(layer) {
                operationalLayers.remove(layer)
                featureLayerIds?.append((layer as! RNAGSFeatureLayer).referenceId)
            } else if layer is RNAGSAnnotationLayer && operationalLayers.contains(layer) {
                operationalLayers.remove(layer)
                annotationLayerIds?.append((layer as! RNAGSAnnotationLayer).referenceId)
            }
        }
        reportToLayerDidLoadListener(referenceId: name, action: "remove", success: true, errorMessage: nil, featureLayers: featureLayerIds, annotationLayers: annotationLayerIds)
    }
  
    @objc func removeGeodatabase(_ name: NSString) {
        let layers = getOprationalLayers(byGeodatabaeId: name)
        for layer in layers {
            self.map?.operationalLayers.remove(layer)
        }
        if (onGeodatabaseWasRemoved != nil) {
            onGeodatabaseWasRemoved!([NSString(string: "referenceId"): name])
        }
        geodatabases.removeValue(forKey: name)
    }
  
  @objc func addBaseLayer(_ args: NSDictionary) {
    guard let baseLayerReferenceId = args["referenceId"] as? String,  let basemapUrlString = args["url"] as? String else {
      print("WARNING: Invalid base layer entered. No layers will be added.")
      reportToOverlayDidLoadListener(referenceId: args["referenceId"] as? NSString ?? NSString(string:"unknown"), action: "add", success: false, errorMessage: "Invalid base layer entered.")
      return
    }
    
    if let url = URL(string: basemapUrlString), let layer = createLayer(url: url) {
      self.baseLayers[baseLayerReferenceId] = layer
      self.map?.basemap.baseLayers.add(layer)
      reportToOverlayDidLoadListener(referenceId: NSString(string: baseLayerReferenceId), action: "add", success: true, errorMessage: nil)
    }
  }
  
  @objc func removeBaseLayer(_ arg: NSString) {
    if let baseLayerReferenceId = arg as String?, let layer = self.baseLayers[baseLayerReferenceId] {
      self.baseLayers.removeValue(forKey: baseLayerReferenceId)
      self.map?.basemap.baseLayers.remove(layer)
      reportToOverlayDidLoadListener(referenceId: NSString(string: baseLayerReferenceId), action: "remove", success: true, errorMessage: nil)
    }
  }
    
    @objc func routeGraphicsOverlay(_ args: NSDictionary) {
        guard let router = router else {
            print ("RNAGSMapView - WARNING: No router was initialized. Perhaps no routeUrl was provided?")
            return
        }
        guard let name = args["overlayReferenceId"] as? NSString,  let overlay = getOverlay(byReferenceId: name) else {
            print("RNAGSMapView - WARNING: Invalid layer name entered. No overlay will be routed.")
            return
        }
        let excludeGraphics = args["excludeGraphics"] as? [NSString]
        let color = UIColor(hex: String(args["routeColor"] as? NSString ?? "#FF0000"))!
        let module = self.bridge!.module(forName: "RNArcGISMapViewModule") as! RNArcGISMapViewModule
        module.sendIsRoutingChanged(true)
        router.createRoute(withGraphicOverlay: overlay, excludeGraphics: excludeGraphics) { [weak self] (result, error) in
            if let error = error {
                module.sendIsRoutingChanged(false)
                print("RNAGSMapView - WARNING: Error while routing: \(error.localizedDescription)")
                return
            }
            guard let result = result else {
                module.sendIsRoutingChanged(false)
                print("RNAGSMapView - WARNING: No result obtained.")
                return
            }
            // TODO: Draw routes onto graphics overlay
            print("RNAGSMapView - Route Completed")
            let generatedRoute = result.routes[0]
            self?.draw(route: generatedRoute, with: color)
            module.sendIsRoutingChanged(false)
            
        }
    }
    
    @objc func getVisibleArea(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) {
        let env = AGSGeometryEngine.projectGeometry(self.visibleArea!.extent, to: spaRef) as! AGSEnvelope
        let reactResult: [AnyHashable: Any] = [
            "min": ["latitude" : env.yMin, "longitude": env.xMin],
            "max": ["latitude" : env.yMax, "longitude": env.xMax],
            "center": ["latitude" : env.center.y, "longitude": env.center.x],
            "area": ["height": env.height, "width": env.width]
        ]
        resolve(reactResult)
    }
  
  @objc func exportVectorTiles(_ args: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    if let mapExporter = mapExporter {
      //mapExporter.spaRef = spaRef
      mapExporter.progressEvent = onMapExportProgress
      mapExporter.exportVectorTiles(args, resolve: resolve, reject: reject)
    }
  }

    @objc func getRouteIsVisible(_ args: RCTResponseSenderBlock) {
        args([routeGraphicsOverlay.isVisible])
    }
    
    @objc func setRouteIsVisible(_ args: Bool){
        routeGraphicsOverlay.isVisible = args
    }
    
    // MARK: Exposed RN props
    @objc var basemapUrl: NSString? {
        didSet{
            // TODO: allow for basemap name to be passed depending on enum
          if let apiKey = RNArcGISMapView.apiKey {
            AGSArcGISRuntimeEnvironment.apiKey = apiKey
          }
            let basemapUrlString = String(basemapUrl ?? "")
            if (self.map == nil) {
                setUpMap()
            }
            if let url = URL(string: basemapUrlString), let basemap = createBasemap(url: url) {
                basemap.load { [weak self] (error) in
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        self?.map?.basemap = basemap
                    }
                }
            } else {
                print("==> Warning: Invalid Basemap URL Provided. A stock basemap will be used. <==")
            }
        }
    }
  
  private func createBasemap(url: URL) -> AGSBasemap? {
    if let layer = createLayer(url: url) {
      return AGSBasemap(baseLayer: layer)
    } else {
      return AGSBasemap(url: url)
    }
  }
  
  private func createLayer(url: URL) -> AGSLayer? {
    var layer: AGSLayer? = nil
    if url.isFileURL && url.pathExtension.lowercased() == "vtpk" {
      layer = AGSArcGISVectorTiledLayer(url: url)
    } else if url.isFileURL && url.pathExtension.lowercased() == "tpkx" {
      let cache = AGSTileCache(fileURL: url)
      layer = AGSArcGISTiledLayer(tileCache: cache)
    } else if !url.isFileURL && url.lastPathComponent == "VectorTileServer" {
      layer = AGSArcGISVectorTiledLayer(url: url)
    } else if !url.isFileURL && url.lastPathComponent == "MapServer" {// MapImageLayer or TiledLayer
      let urlAndParams:URL = URL(string: "\(url)?f=pjson")!
      let jsonData = URLSession(configuration: .default).synchronousGet(with: urlAndParams, params: nil);
      do {
        let json = try JSONSerialization.jsonObject(with: jsonData.0!, options: []) as? [String: Any]
        if let json = json, let _ = json["tileInfo"] {
          layer = AGSArcGISTiledLayer(url: url)
        } else {
          layer = AGSArcGISMapImageLayer(url: url)
        }
      } catch {
        print(error.localizedDescription)
      }
    }
    return layer
  }
    
    @objc var recenterIfGraphicTapped: Bool = false
    
    @objc var routeUrl: NSString? {
        didSet {
            if let routeUrl = URL(string: String(routeUrl ?? "")) {
                router = RNAGSRouter(routeUrl: routeUrl, spaRef: spaRef)
            }
        }
    }

    @objc var initialMapCenter: NSArray? {
        didSet{
          if let initialMapCenter = initialMapCenter {
            centerMap(initialMapCenter)
          }
        }// end didSet
    }// end initialMapCenter declaration
    
    @objc var minZoom:NSNumber = 0 {
        didSet{
            self.map?.minScale = minZoom.doubleValue
        }
    }
    
    @objc var maxZoom:NSNumber = 0 {
        didSet{
            self.map?.maxScale = maxZoom.doubleValue
        }
    }
    
    @objc var rotationEnabled = true{
        didSet{
            self.interactionOptions.isRotateEnabled = rotationEnabled
        }
    };
    
    @objc var spatialRef: NSDictionary = [:] {
        didSet {
            if let wkid = spatialRef["wkid"] as? NSNumber {
                if let verticalWKID = spatialRef["verticalWKID"] as? NSNumber {
                    self.spaRef = AGSSpatialReference(wkid: wkid.intValue, verticalWKID: verticalWKID.intValue)!
                } else {
                    self.spaRef = AGSSpatialReference(wkid: wkid.intValue)!
                }
            } else if let wkText = spatialRef["wkText"] as? String {
                self.spaRef = AGSSpatialReference(wkText: wkText)!
            }
            print("\(self.spaRef.wkid) \(self.spaRef.wkText)")
        }
    }

    // MARK: Misc.
    private func getOverlay(byReferenceId referenceId: NSString?) -> RNAGSGraphicsOverlay? {
        if let referenceId = referenceId {
            return self.graphicsOverlays.first(where: {
                if $0 is RNAGSGraphicsOverlay {
                    return ($0 as! RNAGSGraphicsOverlay).referenceId == referenceId
                } else {
                    return false
                }
            }) as? RNAGSGraphicsOverlay
        } else {
            return nil
        }
    }
  
    private func getOprationalLayers(byGeodatabaeId geodatabaseId: NSString?) -> [AGSLayer] {
        var layers: [AGSLayer] = []
        if let geodatabaseId = geodatabaseId {
            self.map?.operationalLayers.forEach({
                if $0 is RNAGSFeatureLayer && ($0 as! RNAGSFeatureLayer).geodatabaseReferenceId == geodatabaseId {
                    layers.append($0 as! AGSLayer)
                } else if $0 is RNAGSAnnotationLayer && ($0 as! RNAGSAnnotationLayer).geodatabaseReferenceId == geodatabaseId {
                    layers.append($0 as! AGSLayer)
                }
            })
        }
        return layers
    }
  
    private func getOprationalLayers(byGeodatabaeId geodatabaseId: NSString?, byFeatureLayerIds featureLayerIds: [NSString]?, byAnnotationLayerIds annotationLayerIds: [NSString]?) -> [AGSLayer] {
        var layers: [AGSLayer] = []
        if let geodatabaseId = geodatabaseId {
            self.map?.operationalLayers.forEach({
                if $0 is RNAGSFeatureLayer && ($0 as! RNAGSFeatureLayer).geodatabaseReferenceId == geodatabaseId {
                    if let featureLayerIds = featureLayerIds, featureLayerIds.contains(($0 as! RNAGSFeatureLayer).referenceId) {
                        layers.append($0 as! AGSLayer)
                    }
                } else if $0 is RNAGSAnnotationLayer && ($0 as! RNAGSAnnotationLayer).geodatabaseReferenceId == geodatabaseId {
                    if let annotationLayerIds = annotationLayerIds, annotationLayerIds.contains(($0 as! RNAGSAnnotationLayer).referenceId) {
                        layers.append($0 as! AGSLayer)
                    }
                }
            })
        }
        return layers
    }
  
    func reportToOverlayDidLoadListener(referenceId: NSString, action: NSString, success: Bool, errorMessage: NSString?){
        if (onOverlayWasModified != nil) {
            var reactResult: [AnyHashable: Any] = [
                "referenceId" : referenceId, "action": action, "success": success
            ]
            if let errorMessage = errorMessage {
                reactResult["errorMessage"] = errorMessage
            }
            onOverlayWasModified!(reactResult)
        }
    }
    func reportToLayerDidLoadListener(referenceId: NSString, action: NSString, success: Bool, errorMessage: NSString?, featureLayers: [NSString]?, annotationLayers: [NSString]?){
        if (onGeodatabaseWasModified != nil) {
            var reactResult: [AnyHashable: Any] = [
                "referenceId" : referenceId, "action": action, "success": success
            ]
            if let errorMessage = errorMessage {
                reactResult["errorMessage"] = errorMessage
            }
            if let featureLayers = featureLayers {
                reactResult["featureLayers"] = featureLayers
            }
            if let annotationLayers = annotationLayers {
                reactResult["annotationLayers"] = annotationLayers
            }
            onGeodatabaseWasModified!(reactResult)
        }
    }
    private func getOverlay(named name: NSString) -> RNAGSGraphicsOverlay?{
        return self.graphicsOverlays.first(where: { (item) -> Bool in
            guard let item = item as? RNAGSGraphicsOverlay else {
                return false
            }
            return item.referenceId == name
        }) as? RNAGSGraphicsOverlay
    }
    
    private func draw(route: AGSRoute, with color: UIColor){
        DispatchQueue.main.async {
            self.routeGraphicsOverlay.graphics.removeAllObjects()
            let routeSymbol = AGSSimpleLineSymbol(style: .solid, color: color, width: 5)
            let routeGraphic = AGSGraphic(geometry: route.routeGeometry, symbol: routeSymbol, attributes: nil)
            self.routeGraphicsOverlay.graphics.add(routeGraphic)
        }
    }
}
