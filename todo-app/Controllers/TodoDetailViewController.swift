//
//  TodoDetailViewController.swift
//  todo-app
//
//  Created by Robert Daly on 11/29/17.
//  Copyright © 2017 DalyDevelopment. All rights reserved.
//

import UIKit
import Firebase

extension String
{
    func toDateString( inputDateFormat inputFormat  : String,  ouputDateFormat outputFormat  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = inputFormat
        let date = dateFormatter.date(from: self)
        dateFormatter.dateFormat = outputFormat
        return dateFormatter.string(from: date!)
    }
}

class TodoDetailViewController: UIViewController {

    var todo: String = ""
    var date: String = ""
    var id: String = ""
    
    @IBOutlet weak var completeBtn: UIButton!
    @IBOutlet weak var undoBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var dateText: UILabel!
    @IBOutlet weak var todoText: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let checkmarkImg = UIImage(named: "checkmark.png")
        let undoImg = UIImage(named: "undo.png")
        let deleteImage = UIImage(named: "trashcan.png")
        
        completeBtn.setImage(checkmarkImg, for: .normal)
        undoBtn.setImage(undoImg, for: .normal)
        deleteBtn.setImage(deleteImage, for: .normal)
        
        let displayDate = date.toDateString(inputDateFormat: "yyyy-MM-DD HH:mm:ss +zzzz", ouputDateFormat: "MMM d, yyyy")
        dateText.text = "Todo Added: \(displayDate)"
        todoText.text = todo
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func onComplete(_ sender: UIButton) {
        Database.database().reference().child("/todos/\(Auth.auth().currentUser?.uid ?? "Unknown")").child(id).updateChildValues(["isComplete": true]) {
            (error, reference) in
            if error != nil {
                print(error!)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func onUndo(_ sender: UIButton) {
        Database.database().reference().child("/todos/\(Auth.auth().currentUser?.uid ?? "Unknown")").child(id).updateChildValues(["isComplete": false]) {
            (error, reference) in
            if error != nil {
                print(error!)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func onDelete(_ sender: UIButton) {
        Database.database().reference().child("/todos/\(Auth.auth().currentUser?.uid ?? "Unknown")").child(id).removeValue {
            (error, reference) in
            if error != nil {
                print(error!)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

}
