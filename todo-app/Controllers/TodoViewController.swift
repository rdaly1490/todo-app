//
//  TodoViewController.swift
//  todo-app
//
//  Created by Robert Daly on 11/27/17.
//  Copyright © 2017 DalyDevelopment. All rights reserved.
//

import UIKit
import Firebase
import ChameleonFramework
import MGSwipeTableCell

class TodoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    var todoArray: [Todo] = [Todo]()
    var isKeyboardActive: Bool = false
    var tappedTodoText: String = ""
    var tappedTodoDate: String = ""
    var tappedTodoId: String = ""
    
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var todoTextField: UITextField!
    @IBOutlet weak var todoTableView: UITableView!
    @IBOutlet weak var saveBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        todoTableView.delegate = self
        todoTableView.dataSource = self
        todoTextField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewTapped))
        todoTableView.addGestureRecognizer(tapGesture)
        
        instantiateSocketObservers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // protocol required methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoArray.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isKeyboardActive == true {
            return
        }
        
        let tappedTodo = todoArray[indexPath.row]
        
        tappedTodoText = tappedTodo.todoText
        tappedTodoDate = tappedTodo.date
        tappedTodoId = tappedTodo.id
        
        performSegue(withIdentifier: "todoDetail", sender: self)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "todoDetail" {
            let todoDetailVC = segue.destination as! TodoDetailViewController
            todoDetailVC.todo = tappedTodoText
            todoDetailVC.date = tappedTodoDate
            todoDetailVC.id = tappedTodoId
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let reuseIdentifier = "tableCell"
        let currentTodo = todoArray[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! MGSwipeTableCell
        
        cell.rightButtons = [MGSwipeButton(title: "", icon: UIImage(named:"trashcan.png"), backgroundColor: .red) {
                                (sender: MGSwipeTableCell!) -> Bool in
                                self.deleteTodo(currentTodo: currentTodo)
                                return true
                             },
                             MGSwipeButton(title: "", icon: UIImage(named:"undo.png"), backgroundColor: .blue) {
                                (sender: MGSwipeTableCell!) -> Bool in
                                self.updateTodoCompletionStatus(currentTodo: currentTodo, isComplete: false)
                                return true
                             },
                             MGSwipeButton(title: "", icon: UIImage(named:"checkmark.png"), backgroundColor: .green) {
                                (sender: MGSwipeTableCell!) -> Bool in
                                self.updateTodoCompletionStatus(currentTodo: currentTodo, isComplete: true)
                                return true
                             }]
        cell.rightSwipeSettings.transition = .drag
        
        let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: currentTodo.todoText)
        
        if currentTodo.isComplete == true {
            attributeString.addAttribute(NSAttributedStringKey.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
            cell.backgroundColor = UIColor.flatWhite()
            cell.textLabel?.attributedText = attributeString
        } else {
            attributeString.removeAttribute(NSAttributedStringKey.strikethroughStyle, range: NSMakeRange(0, attributeString.length))
            cell.backgroundColor = UIColor.white
            cell.textLabel?.attributedText = attributeString
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0;
    }

    
    // optional protocol methods
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        // animate the height constraint changing then update the view
        UIView.animate(withDuration: 0.5) {
            let keyBoardheight = 258
            let viewHeight = 55
            self.textViewHeight.constant = CGFloat(keyBoardheight + viewHeight)
            self.view.layoutIfNeeded()
            self.isKeyboardActive = true
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.5) {
            self.textViewHeight.constant = 55
            self.view.layoutIfNeeded()
            self.isKeyboardActive = false
        }
    }
    
    // actions
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        do {
            try Auth.auth().signOut()
            self.navigationController?.popToRootViewController(animated: true)
        } catch {
            print("Error signing out")
        }
    }
    
    @IBAction func onTodoSave(_ sender: UIButton) {
        // disable while saving is in progress
        todoTextField.isEnabled = false
        saveBtn.isEnabled = false
        
        let todosDB = Database.database().reference().child("todos/\(Auth.auth().currentUser?.uid ?? "Unknown")")
        
        let todoDictionary: [String: Any] = ["user": Auth.auth().currentUser?.uid ?? "Unknown", "isComplete": false, "todoText": todoTextField.text!, "date": "\(Date())"]
        todosDB.childByAutoId().setValue(todoDictionary) {
            (error, reference) in
            
            if error != nil {
                print(error!)
            } else {
                print("message saved successfully")
                self.todoTextField.text = ""
                self.todoTextField.isEnabled = true
                self.saveBtn.isEnabled = true
            }
        }
    }
    
    @objc func tableViewTapped() {
        todoTextField.endEditing(true)
    }
    
    func instantiateSocketObservers() {
        let todosDB = Database.database().reference().child("/todos/\(Auth.auth().currentUser?.uid ?? "Unknown")")
        
        todosDB.observe(.childAdded) {
            (snapshot) in
            let snapshotValue = snapshot.value as! Dictionary<String, Any>
            
            let todo = Todo()
            todo.id = snapshot.key
            todo.isComplete = snapshotValue["isComplete"] as! Bool
            todo.todoText = snapshotValue["todoText"] as! String
            todo.date = snapshotValue["date"] as! String
            todo.user = snapshotValue["user"] as! String
            
            self.todoArray.append(todo)
            self.todoTableView.reloadData()
        }
        
        todosDB.observe(.childChanged) {
            (snapshot) in
            let snapshotValue = snapshot.value as! Dictionary<String, Any>
            
            for (index, todo) in self.todoArray.enumerated() {
                if todo.id == snapshot.key {
                    let updatedTodo = Todo()
                    updatedTodo.id = snapshot.key
                    updatedTodo.isComplete = snapshotValue["isComplete"] as! Bool
                    updatedTodo.todoText = snapshotValue["todoText"] as! String
                    updatedTodo.date = snapshotValue["date"] as! String
                    updatedTodo.user = snapshotValue["user"] as! String
                    
                    self.todoArray[index] = updatedTodo
                    self.todoTableView.reloadData()
                }
            }
        }
        
        todosDB.observe(.childRemoved) {
            (snapshot) in
            for (index, todo) in self.todoArray.enumerated() {
                if todo.id == snapshot.key {
                    self.todoArray.remove(at: index)
                    self.todoTableView.reloadData()
                }
            }
        }
    }
    
    func updateTodoCompletionStatus(currentTodo: Todo, isComplete: Bool) {
        Database.database().reference().child("/todos/\(Auth.auth().currentUser?.uid ?? "Unknown")").child(currentTodo.id).updateChildValues(["isComplete": isComplete]) {
            (error, reference) in
            if error != nil {
                print(error!)
            }
        }
    }
    
    func deleteTodo(currentTodo: Todo) {
        Database.database().reference().child("/todos/\(Auth.auth().currentUser?.uid ?? "Unknown")").child(currentTodo.id).removeValue {
            (error, reference) in
            if error != nil {
                print(error!)
            }
        }
    }
}
