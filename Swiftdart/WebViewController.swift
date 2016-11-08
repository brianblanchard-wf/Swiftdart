//
//  WebViewController.swift
//  Swiftdart

import UIKit
import WebKit
import SnapKit

protocol JSEvalDelegate: class {
    func evaluateJS(_ jsString: String)
}

class WebViewController: UIViewController, JSEvalDelegate {
    var webview: WKWebView!
    let userController = WKUserContentController()
    let todoContainer = UIView()

    let bridge = Bridge()
    var contentRendererModule: Module<ContentRendererEvents, ContentRendererApi>?

    override func viewDidLoad() {
        super.viewDidLoad()

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userController

        userController.add(bridge, name: "bridge")
        bridge.jsEvalDelegate = self

        webview = WKWebView(frame: .zero, configuration: configuration)

        view.addSubview(webview)

        setupModules()
        doConstraints()

        webview.load(URLRequest(url: URL(string: "http://localhost:8080/a/QWNjb3VudB81NjM5NDQ1NjA0NzI4ODMy/mobileview/cmVzb3VyY2VfaWQ9VjBaRVlYUmhSVzUwYVhSNUhrUnZZM1Z0Wlc1ME9rSXdNamN6UWpBM1JUTTNOekUyTTBVMU5VRkdRVVl6TXpNME9FSXdRVU15T2pFd056WXpOVGsxUTBORE4wWkNRamM0UTBVeFFVWXpNekkzUlRWRk4wRXkmcmVmZXJyZXI9d2ZfaG9tZV9wcmV2aWV3")!,
                                cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60))
    }

    func doConstraints() {
        webview.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.bottom.equalTo(0)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        todoContainer.layoutIfNeeded()
    }

    func setupModules() {
        // Where a module is created and registed with the bridge
        let todoModule = Module<TodoEvents, TodoApi>(moduleType: .Todo)
        bridge.registerModule(todoModule)

        contentRendererModule = Module<ContentRendererEvents, ContentRendererApi>(moduleType: .ContentRenderer)
        bridge.registerModule(contentRendererModule!)

        _ = contentRendererModule?.events?.didLoad.addHandler(self, handler: WebViewController.onContentRendererWillLoad)
        _ = contentRendererModule?.events?.willUnload.addHandler(self, handler: WebViewController.onContentRendererWillUnload)
    }

    func onContentRendererWillLoad(_: Any) {
        let zoomInButton = UIBarButtonItem(title: "Zoom In", style: .plain, target: contentRendererModule!.api, action: #selector(ContentRendererApi.zoomIn))
        let zoomOutButton = UIBarButtonItem(title: "Zoom To Fit", style: .plain, target: contentRendererModule!.api, action: #selector(ContentRendererApi.zoomToFit))

        navigationItem.rightBarButtonItems = [zoomInButton, zoomOutButton]
    }

    func onContentRendererWillUnload(_: Any) {
        navigationItem.rightBarButtonItems = []
    }

    func addViewContoller(_ viewController: UIViewController, toView view: UIView) {
        addChildViewController(viewController)
        view.addSubview(viewController.view)

        viewController.view.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }
    }

    func evaluateJS(_ jsString: String) {
        webview.evaluateJavaScript(jsString, completionHandler: nil)
    }
}
