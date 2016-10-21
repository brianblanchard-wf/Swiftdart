//
//  TodoModule.swift
//  Swiftdart
// An example implementation of the Dart Todo w_module in swift

import UIKit

var todoIdCounter = 0

class Todo {
    var id: Int
    var description: String
    var completed: Bool

    init(description: String, completed: Bool) {
        todoIdCounter += 1
        self.id = todoIdCounter
        self.description = description
        self.completed = completed
    }

    init(json: [String: Any]) {
        self.id = json["id"] as! Int
        self.description = json["description"] as! String
        self.completed = json["completed"] as! Bool
        todoIdCounter = self.id
    }

    func toJson() -> [String: Any] {
        return [
            "description": description,
            "completed": completed,
            "id": id
        ]
    }
}

// These correspond one to one of events that are fired by the Dart w_module
class TodoEvents: ModuleEvents {
    let todoCreated = Event<[String: Any]>()
    let todoDeleted = Event<[String: Any]>()
    let todoCompleted = Event<[String: Any]>()
    let todoListCleared = Event<Any>()
}

// These correspond one to one to api methods in the Dart w_module
class TodoApi: ModuleApi {
    func deleteTodo(todo: Todo) {
        delegate?.sendApiCall(TodoApiMethods.DeleteTodo, data: [todo.toJson()])
    }

    func createTodo(todo: Todo) {
        delegate?.sendApiCall(TodoApiMethods.CreateTodo, data: [todo.toJson()])
    }

    func completeTodo(todo: Todo) {
        delegate?.sendApiCall(TodoApiMethods.CompleteTodo, data: [todo.toJson()])
    }

    func clearTodoList() {
        delegate?.sendApiCall(TodoApiMethods.ClearTodoList, data: [])
    }
}

// These correspond the actual string name of the Dart api methods
enum TodoApiMethods: String {
    case CompleteTodo = "completeTodo"
    case DeleteTodo = "deleteTodo"
    case CreateTodo = "createTodo"
    case ClearTodoList = "clearTodoList"
}

// An example of a native Todo list
// This will stay in sync with the corresponding web component using
// w_module events and api calls
class TodoListVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    let reuseId = "todoCell"
    var todos = [Todo]()
    let createTodoField = UITextField()
    var tableView = UITableView()

    var api: TodoApi?
    var events: TodoEvents?

    init(module: Module<TodoEvents, TodoApi>) {
        super.init(nibName: nil, bundle: nil)
        api = module.api
        events = module.events

        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func commonInit() {
        registerForEvents()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Native Todo List"
        navigationController?.navigationBar.isTranslucent = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(TodoListVC.clearTodoList))
        setupTableView()
    }

    func registerForEvents() {
        _ = events?.todoCreated.addHandler(self, handler: TodoListVC.onTodoCreated)
        _ = events?.todoDeleted.addHandler(self, handler: TodoListVC.onTodoDeleted)
        _ = events?.todoCompleted.addHandler(self, handler: TodoListVC.onTodoCompleted)
        _ = events?.todoListCleared.addHandler(self, handler: TodoListVC.onTodoListCleared)
    }

    func setupTableView() {
        tableView.register(TodoCell.self, forCellReuseIdentifier: reuseId)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        view.addSubview(createTodoField)

        createTodoField.delegate = self
        createTodoField.placeholder = "Add a new todo..."
        createTodoField.layer.borderColor = UIColor.lightGray.cgColor
        createTodoField.layer.borderWidth = 1.0
        createTodoField.clipsToBounds = true
        createTodoField.layer.cornerRadius = 5
        createTodoField.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0);

        createTodoField.snp.makeConstraints { (make) in
            make.left.equalTo(30)
            make.top.equalTo(1)
            make.right.equalTo(-30)
            make.height.equalTo(30)
        }

        tableView.snp.makeConstraints { (make) in
            make.left.equalTo(view)
            make.right.equalTo(view)
            make.top.equalTo(createTodoField.snp.bottom);
            make.bottom.equalTo(view)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        api?.createTodo(todo: Todo(description: textField.text ?? "", completed: false))
        textField.text = ""
        return false
    }

    func clearTodoList() {
        api?.clearTodoList()
    }

    func todoCompleteValueChanged(sender: UISwitch) {
        let todo = todos[sender.tag]
        todo.completed = sender.isOn
        api?.completeTodo(todo: todo)
    }

    // MARK: Event Handlers
    func onTodoCreated(todoJson: [String: Any]) {
        todos.append(Todo(json: todoJson))
        tableView.reloadData()
    }

    func onTodoDeleted(todoJson: [String: Any]) {
        todos = todos.filter { $0.id != Todo(json: todoJson).id }
        tableView.reloadData()
    }

    func onTodoListCleared(_: Any) {
        todos.removeAll()
        tableView.reloadData()
    }

    func onTodoCompleted(todoJson: [String: Any]) {
        let completedTodo = Todo(json: todoJson)
        todos.first { (todo) -> Bool in
            completedTodo.id == todo.id
            }?.completed = true

        tableView.reloadData()
    }

    // MARK: UITableView
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath) as! TodoCell
        cell.todo = todos[indexPath.row]
        cell.completeSwitch.tag = indexPath.row
        cell.completeSwitch.addTarget(self, action: #selector(TodoListVC.todoCompleteValueChanged(sender:)), for: .valueChanged)

        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todos.count
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            api?.deleteTodo(todo: todos.remove(at: indexPath.row))
        }
    }
}

// Table view cell subclass for a Todo object
class TodoCell: UITableViewCell {
    let todoLabel = UILabel()
    let completeSwitch = UISwitch()
    let divider = UIView()

    var todo: Todo? {
        didSet {
            updateUI()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        commonInit()
    }

    func updateUI() {
        if let todo = todo {
            todoLabel.text = todo.description
            todoLabel.textColor = todo.completed ? .lightGray : .black
            completeSwitch.isOn = todo.completed
        }
    }

    func commonInit() {
        addSubview(todoLabel)
        addSubview(divider)
        addSubview(completeSwitch)

        divider.backgroundColor = UIColor.groupTableViewBackground

        todoLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.height.equalTo(24)
            make.right.equalTo(-80)
            make.centerY.equalTo(self)
        }

        completeSwitch.snp.makeConstraints { (make) in
            make.left.equalTo(todoLabel.snp.right).offset(10)
            make.centerY.equalTo(self)
        }

        divider.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.right.equalTo(self)
            make.bottom.equalTo(self)
            make.height.equalTo(1)
        }
    }
}
