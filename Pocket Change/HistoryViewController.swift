//
//  HistoryViewController.swift
//  Pocket Change
//
//  Created by Nathan Tsai on 12/20/16.
//  Copyright © 2016 Nathan Tsai. All rights reserved.
//

import UIKit
import CoreData

class HistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
    // Clean code
    var sharedDelegate: AppDelegate!
    
    // IBOutlet for components
    @IBOutlet var historyTable: UITableView!
    @IBOutlet weak var clearHistoryButton: UIBarButtonItem!
    
    // When the screen loads, display the table
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Set Navbar Color
        let color = UIColor.white
        self.navigationController?.navigationBar.tintColor = color
        
        self.navigationItem.title = "History"
        historyTable.dataSource = self
        historyTable.delegate = self
        
        // If there is no history, disable the clear history button
        if BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray.isEmpty == true
        {
            clearHistoryButton.isEnabled = false
        }
        else
        {
            clearHistoryButton.isEnabled = true
        }
        
        // So we don't need to type this out again
        let shDelegate = UIApplication.shared.delegate as! AppDelegate
        sharedDelegate = shDelegate
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(WithdrawalViewController.dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
    }
    
    // Function runs everytime the screen appears
    override func viewWillAppear(_ animated: Bool)
    {
        // Make sure the table is up to date
        super.viewWillAppear(animated)
        
        // Get data from CoreData
        BudgetVariables.getData()
        
        // Reload the budget table
        self.historyTable.reloadData()
    }
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard()
    {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    // When the clear history button gets pressed, clear the history and disable button
    @IBAction func clearHistoryButtonWasPressed(_ sender: AnyObject)
    {
        // Empty out arrays
        BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray = [String]()
        BudgetVariables.budgetArray[BudgetVariables.currentIndex].descriptionArray = [String]()
        
        // Zero out the spending's for this array per date and total
        for (key, _) in BudgetVariables.budgetArray[BudgetVariables.currentIndex].netAmountSpentOnDate
        {
            BudgetVariables.budgetArray[BudgetVariables.currentIndex].netAmountSpentOnDate[key] = 0.0
        }
        BudgetVariables.budgetArray[BudgetVariables.currentIndex].netTotalAmountSpent = 0.0
        
        // Save context and get data
        self.sharedDelegate.saveContext()
        BudgetVariables.getData()
        
        // Reload the table and disable the clear history button
        self.historyTable.reloadData()
        clearHistoryButton.isEnabled = false
    }
    
    // Functions that conform to UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray.count
    }
    
    // Determines what data goes in what cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let myCell:UITableViewCell = historyTable.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath)
        
        let str = BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray[indexPath.row]
        let index = str.index(str.startIndex, offsetBy: 0)
        
        if str[index] == "+"
        {
            myCell.textLabel?.textColor = UIColor.green
        }
        
        if str[index] == "–"
        {
            myCell.textLabel?.textColor = UIColor.red
        }
        
        myCell.textLabel?.text = BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray[indexPath.row]
        
        // The description string holds MM/dd/YYYY at the end of each description. Display everything but the year in the table
        let descripStr = BudgetVariables.budgetArray[BudgetVariables.currentIndex].descriptionArray[indexPath.row]
        let descripIndex = descripStr.index(descripStr.endIndex, offsetBy: -5)
        let detailText = descripStr.substring(to: descripIndex)
        myCell.detailTextLabel?.text = detailText
        
        return myCell
    }
    
    @objc(tableView:commitEditingStyle:forRowAtIndexPath:) func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        // Extract the key to the map in the format "MM/dd/YYYY" into the variable date
        let descripStr = BudgetVariables.budgetArray[BudgetVariables.currentIndex].descriptionArray[indexPath.row]
        let dateIndex = descripStr.index(descripStr.endIndex, offsetBy: -10)
        let date = descripStr.substring(from: dateIndex)
        
        // Extract the amount spent for this specific transaction into the variable amountSpent
        let historyStr = BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray[indexPath.row]
        let index1 = historyStr.index(historyStr.startIndex, offsetBy: 0) // Index spans the first character in the string
        let index2 = historyStr.index(historyStr.startIndex, offsetBy: 3) // Index spans the amount spent in that transaction
        let amountSpent = Double(historyStr.substring(from: index2))

        // If the deleting swipe motion happens, remove the budget from the budgetArray, decrement the currentIndex, and delete the row
        // Also update the values that directly correlate to the data in both the pie chart and the bar graph
        if editingStyle == .delete
        {
            // If this specific piece of history logged a deposit action, the total amount spent should increase after deletion
            if historyStr[index1] == "+"
            {
                let newSpentOnDateAmount = BudgetVariables.budgetArray[BudgetVariables.currentIndex].netAmountSpentOnDate[date]! + amountSpent!
                BudgetVariables.budgetArray[BudgetVariables.currentIndex].netAmountSpentOnDate[date] = newSpentOnDateAmount
                let newTotalAmount = BudgetVariables.budgetArray[BudgetVariables.currentIndex].netTotalAmountSpent + amountSpent!
                BudgetVariables.budgetArray[BudgetVariables.currentIndex].netTotalAmountSpent = newTotalAmount
            }
            // If this specific piece of history logged a withdraw action, the total amount spent should decrease after deletion
            else if historyStr[index1] == "–"
            {
                let newDateAmount = BudgetVariables.budgetArray[BudgetVariables.currentIndex].netAmountSpentOnDate[date]! - amountSpent!
                BudgetVariables.budgetArray[BudgetVariables.currentIndex].netAmountSpentOnDate[date] = newDateAmount
                let newTotalAmount = BudgetVariables.budgetArray[BudgetVariables.currentIndex].netTotalAmountSpent - amountSpent!
                BudgetVariables.budgetArray[BudgetVariables.currentIndex].netTotalAmountSpent = newTotalAmount
            }
            
            // Delete the row
            BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray.remove(at: indexPath.row)
            BudgetVariables.budgetArray[BudgetVariables.currentIndex].descriptionArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            self.sharedDelegate.saveContext()
            BudgetVariables.getData()
            
            // Disable the clear history button if the cell deleted was the last item
            if BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray.isEmpty == true
            {
                clearHistoryButton.isEnabled = false
            }
            else
            {
                clearHistoryButton.isEnabled = true
            }
        }
    }
}
