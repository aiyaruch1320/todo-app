//
//  ViewController.swift
//  TodoApp2
//
//  Created by อัยรัช เพ็งทอง on 27/7/2565 BE.
//

import UIKit

class TodoListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ItemDetailViewControllerDelegate, TodoItemTableViewCellDelegate, UITableViewDragDelegate, UITableViewDropDelegate {

    @IBOutlet weak var tableView: UITableView?
    var todo = Todo()

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todo.totalItems
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "todoItemCell", for: indexPath) as! TodoItemTableViewCell
        let item = todo.item(at: indexPath.row)
        cell.configure(item: item, delegate: self)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "openEditItemSegue", sender: todo.item(at: indexPath.row))
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath){
        if editingStyle == .delete {
            todo.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            saveTodo()
        }
    }
    
    func makeTodoFileURL(fileManager: FileManager) throws -> URL {
        var destinationURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        destinationURL.appendPathComponent("todo")
        destinationURL.appendPathExtension("plist")
        return destinationURL
    }
    
    func saveTodo() {
        do {
            let destinationURL = try makeTodoFileURL(fileManager: FileManager.default)

            let encoder = PropertyListEncoder()
            let data = try encoder.encode(todo)
            
            try data.write(to: destinationURL)
        } catch {
            print("Cannot save todo to file, Error: \(error)")
        }
    }
    
    func loadTodo() {
        do {
            let fileManager = FileManager.default
            let destinationURL = try makeTodoFileURL(fileManager: fileManager)

            if fileManager.fileExists(atPath: destinationURL.path) {
                let data = try Data(contentsOf: destinationURL)
                let decoder = PropertyListDecoder()
                todo = try decoder.decode(Todo.self, from: data)
                tableView?.reloadData()
            }
        } catch {
            print("Cannot load todo from file, Error: \(error)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView?.dragDelegate = self
        tableView?.dragInteractionEnabled = true
        tableView?.dropDelegate = self
        loadTodo()
    }

    func itemDetailViewController(controller: ItemDetailViewController, didAdd item: TodoItem) {
        todo.add(item: item)
        if let index = todo.index(of: item) {
            tableView?.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            saveTodo()
        }
        controller.dismiss(animated: true, completion: nil)
    }

    func itemDetailViewController(controller: ItemDetailViewController, didEdit item: TodoItem) {
        if let index = todo.index(of: item) {
            tableView?.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            saveTodo()
        }
        navigationController?.popViewController(animated: true)
    }
    
    func itemDetailViewControllerDidCancel(controller: ItemDetailViewController) {
        if controller.isInEditMode {
            navigationController?.popViewController(animated: true)
        } else {
            controller.dismiss(animated: true, completion: nil)
        }
    }
    
    func todoItemTableViewCellDidTapCheckboxButton(cell: TodoItemTableViewCell) {
        if let indexPath = tableView?.indexPath(for: cell) {
            todo.item(at: indexPath.row).isDone.toggle()
            saveTodo()
            tableView?.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        [UIDragItem(itemProvider: NSItemProvider())]
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {}
    
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        session.localDragSession != nil
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        true
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        todo.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
        saveTodo()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "openAddItemSegue" {
            if let nav = segue.destination as? UINavigationController,
                let controller = nav.topViewController as? ItemDetailViewController {
                controller.delegate = self
            }
        } else if segue.identifier == "openEditItemSegue" {
            if let controller = segue.destination as? ItemDetailViewController {
                controller.todoItem = sender as? TodoItem
                controller.delegate = self
            }
        }
    }
}
