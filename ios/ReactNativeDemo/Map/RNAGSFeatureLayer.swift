//
//  RNAGSFeatureLayer.swift
//  ReactNativeDemo
//
//  Created by Lane Lu on 2022/8/12.
//

import ArcGIS
import Foundation

public class RNAGSFeatureLayer : AGSFeatureLayer {
  let geodatabaseReferenceId: NSString
  let referenceId: NSString
  let extent: String
  
  init(geodatabase: RNAGSGeodatabase, featureTable: AGSGeodatabaseFeatureTable, rawData: NSDictionary?) {
    geodatabaseReferenceId = geodatabase.referenceId
    
    if let referenceIdRaw = rawData?["referenceId"] as? NSString {
      referenceId = referenceIdRaw
    } else {
      referenceId = NSString(string: featureTable.tableName)
    }
    
    if let extentRaw = rawData?["extent"] as? NSString {
      extent = String(extentRaw)
    } else {
      extent = ""
    }

    super.init(featureTable: featureTable)
    
    if let definitionExpressionRaw = rawData?["definitionExpression"] as? NSString {
      definitionExpression = String(definitionExpressionRaw)
    }
  }
}
