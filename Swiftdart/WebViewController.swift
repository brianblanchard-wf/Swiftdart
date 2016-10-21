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

    override func viewDidLoad() {
        super.viewDidLoad()

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userController

        userController.add(bridge, name: "bridge")
        bridge.jsEvalDelegate = self

        webview = WKWebView(frame: .zero, configuration: configuration)

        view.addSubview(webview)
        view.addSubview(todoContainer)

        setupModules()
        doConstraints()

        webview.load(URLRequest(url: URL(string: "http://localhost:8080/todo_app/web")!,
                                cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60))
    }

    func doConstraints() {
        webview.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.bottom.equalTo(view.snp.centerY)
        }

        todoContainer.snp.makeConstraints { (make) in
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.top.equalTo(view.snp.centerY)
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

        // Where a native component is created and given a module to communicate with
        let todoListVC = TodoListVC(module: todoModule)
        addViewContoller(UINavigationController(rootViewController: todoListVC), toView: todoContainer)
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
