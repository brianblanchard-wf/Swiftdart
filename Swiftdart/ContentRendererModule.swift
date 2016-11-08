//
//  ContentRendererModule.swift
//  Swiftdart
//
//  Created by Brian.Blanchard on 10/25/16.
//  Copyright © 2016 Workiva. All rights reserved.
//

import UIKit

// These correspond one to one of events that are fired by the Dart w_module
class ContentRendererEvents: ModuleEvents {
    let todoCreated = Event<[String: Any]>()
    let todoDeleted = Event<[String: Any]>()
    let todoCompleted = Event<[String: Any]>()
    let todoListCleared = Event<Any>()
}

// These correspond one to one to api methods in the Dart w_module
class ContentRendererApi: ModuleApi {
    func zoomIn() {
        delegate?.sendApiCall(ContentRendererApiMethods.ZoomIn, data: [])
    }

    func zoomOut() {
        delegate?.sendApiCall(ContentRendererApiMethods.ZoomOut, data: [])
    }

    func zoomToFit() {
        delegate?.sendApiCall(ContentRendererApiMethods.ZoomToFit, data: [])
    }
}

// These correspond the actual string name of the Dart api methods
enum ContentRendererApiMethods: String {
    case ZoomIn = "zoomIn"
    case ZoomOut = "zoomOut"
    case ZoomToFit = "zoomToFit"
}
