//
//  Bridge.swift
//  Swiftdart

import UIKit
import WebKit

protocol ApiDelegate: class {
    func sendApiCall<M: RawRepresentable>(_ method: M, data: Any) where M.RawValue == String
}

protocol BridgeEvent {
    func didRecieveEvent<T>(_ rawEvent: String, data: T)
}

protocol KeyValueCodable {
    func valueForKey<T>(key : String) -> T?
    subscript (key : String) -> Any? { get }
}

extension KeyValueCodable {
    // Returns the value for the property identified by a given key.
    func valueForKey<T>(key : String) -> T? {

        let mirror = Mirror(reflecting: self)

        for (_, child) in mirror.children.enumerated() {
            if child.label == key {
                return child.value as? T
            }
        }

        return nil
    }

    subscript (key : String) -> Any? {
        get {
            return self.valueForKey(key: key)
        }
    }
}

class Bridge: NSObject, WKScriptMessageHandler {
    let jsString = "var event = new CustomEvent('bridge', { detail: %@ });" +
    "window.dispatchEvent(event);"

    lazy var registeredModules = [String: BridgeEvent]()

    weak var jsEvalDelegate: JSEvalDelegate?

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // Entry point where events from Dart get handled
        if let body = message.body as? [String: Any] {
            if let module = body["module"] as? String, let event = body["event"] as? String {
                if let registeredModule = registeredModules[module] {
                    // This is a limitation of swift generics so I have to try to cast individually
                    // This is done here so when events are called they are passed the correctly typed data
                    if let data = body["data"] as? Int {
                        registeredModule.didRecieveEvent(event, data: data)
                    } else if let data = body["data"] as? String {
                        registeredModule.didRecieveEvent(event, data: data)
                    } else if let data = body["data"] as? [String: Any] {
                        registeredModule.didRecieveEvent(event, data: data)
                    } else if let data = body["data"] as? [Int] {
                        registeredModule.didRecieveEvent(event, data: data)
                    } else if let data = body["data"] as? [Any] {
                        registeredModule.didRecieveEvent(event, data: data)
                    } else if let data = body["data"] as? [String] {
                        registeredModule.didRecieveEvent(event, data: data)
                    }
                    else {
                        registeredModule.didRecieveEvent(event, data: body["data"] ?? NSNull())
                    }
                }
            }
        }
    }

    func registerModule<E: ModuleEvents, A: ModuleApi>(_ module: Module<E, A>) {
        registeredModules[module.moduleType.rawValue] = module
        module.bridge = self
    }

    func sendApiCall<A: RawRepresentable>(_ module: ModuleType, method: A, data: Any) where A.RawValue == String {
        let payload: [String: Any] = [
            "module": module.rawValue as Any,
            "method": method.rawValue as Any,
            "data": data as AnyObject
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
            let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)

            if let jsonString = jsonString {
                let stringToEval = String(format: jsString as String, jsonString)
                jsEvalDelegate?.evaluateJS(stringToEval)
            }
        } catch {
            print("Unable to serialize json")
        }
    }
}

enum ModuleType: String {
    case Unknown = ""
    case ContentRenderer = "contentRenderer" // These match the module names in Dart
    case Todo = "todo"
}

class Module<E, A>: NSObject, ApiDelegate, BridgeEvent where E: ModuleEvents, E: KeyValueCodable, A: ModuleApi {
    var moduleType: ModuleType

    weak var bridge: Bridge?

    var api: A?
    var events: E?

    required init(moduleType: ModuleType) {
        self.moduleType = moduleType
        super.init()
        commonInit()
    }

    func commonInit() {
        api = A()
        api?.delegate = self
        events = E()
    }

    func moduleApi() -> ModuleApi? {
        return api
    }

    func moduleEvents() -> ModuleEvents? {
        return events
    }

    func didRecieveEvent<T>(_ rawEvent: String, data: T) {
        if let events = events, let event: Event<T> = events.valueForKey(key: rawEvent) {
            // This will delegate out the event and data to any other objects listening for it
            event.raise(data)
        }
    }

    func sendApiCall<M: RawRepresentable>(_ method: M, data: Any) where M.RawValue == String {
        // This sends calls the method on the corresponding api of the Dart module
        // 'data' are positional arguments to the Dart api method and is required
        // Methods that take no args should pass up an empty array
        bridge?.sendApiCall(moduleType, method: method, data: data)
    }
}

class ModuleApi: NSObject {
    var delegate: ApiDelegate?

    required override init() {
        super.init()
    }
}

class ModuleEvents: NSObject, KeyValueCodable {
    required override init() {
        super.init()
    }
}
