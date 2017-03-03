//
//  HistoryAndMapViewController.swift
//  Pocket Change
//
//  Created by Nathan Tsai on 3/2/17.
//  Copyright © 2017 Nathan Tsai. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps
import CoreData

class HistoryAndMapViewController: UIViewController, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, GMSMapViewDelegate
{
    // Clean code
    var sharedDelegate: AppDelegate!
    
    // IBOutlet for components
    @IBOutlet var historyTable: UITableView!
    @IBOutlet weak var clearHistoryButton: UIBarButtonItem!
    
    // IB Outlet for the current view
    @IBOutlet weak var myMapView: UIView!
    
    // Location manager for finding the current location
    let locationManager = CLLocationManager()
    
    // Global variables for manipulating the map
    var mapView = GMSMapView()
    var camera = GMSCameraPosition()
    
    // When the screen loads, display the table
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Set up the map
        mapView.delegate = self
        mapView.isMyLocationEnabled = true
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
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
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SpendViewController.dismissKeyboard))
        
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
    
    // Only refresh when the subviews have been set
    override func viewDidLayoutSubviews()
    {
        self.refreshMarkers()
    }
    
    // When the location is updated, show the current location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        self.locationManager.stopUpdatingLocation()
    }
    
    // Show the current location on the Google Map
    func refreshMarkers()
    {
        // If there are no latitudes and longitudes, center the camera around the current location
        if BudgetVariables.budgetArray[BudgetVariables.currentIndex].markerLatitude.isEmpty == true
        {
            // If the current location cannot be found, set the default camera to be centered at UCLA
            if self.locationManager.location?.coordinate.latitude == nil || self.locationManager.location?.coordinate.longitude == nil
            {
                camera = GMSCameraPosition.camera(withLatitude: 34.068921, longitude: -118.44518110000001, zoom: 15)
            }
                
            // Otherwise if the current location can be found, center the map at the current location
            else
            {
                camera = GMSCameraPosition.camera(withLatitude: (self.locationManager.location?.coordinate.latitude)!, longitude: (self.locationManager.location?.coordinate.longitude)!, zoom: 15)
            }
        }
        
        // If the marker array is not empty, center the camera around the first transaction's location
        else
        {
            camera = GMSCameraPosition.camera(withLatitude: BudgetVariables.budgetArray[BudgetVariables.currentIndex].markerLatitude[0], longitude: BudgetVariables.budgetArray[BudgetVariables.currentIndex].markerLongitude[0], zoom: 15)
        }
        
        // Create a map view using the current width and height of the view
        mapView = GMSMapView.map(withFrame: CGRect(x: 0, y: 0, width: self.myMapView.frame.size.width, height: self.myMapView.frame.size.height), camera: camera)
        
        // Clear all markers before loading the new markers
        mapView.clear()
        
        // Create markers for all the locations in the array
        for i in 0..<BudgetVariables.budgetArray[BudgetVariables.currentIndex].markerLatitude.count
        {
            let latitude = BudgetVariables.budgetArray[BudgetVariables.currentIndex].markerLatitude[i]
            let longitude = BudgetVariables.budgetArray[BudgetVariables.currentIndex].markerLongitude[i]
            
            // If the latitude and longitude are valid, add a corresponding marker to the map
            if latitude != 360 && longitude != 360
            {
                let marker = GMSMarker()
                marker.position.latitude = latitude
                marker.position.longitude = longitude
                marker.snippet = BudgetVariables.getDetailFromDescription(descripStr: BudgetVariables.budgetArray[BudgetVariables.currentIndex].descriptionArray[i])
                
                // If the action is a "+", add a green marker instead
                let str = BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray[i]
                let index = str.index(str.startIndex, offsetBy: 0)
                
                if str[index] == "+"
                {
                    marker.icon = GMSMarker.markerImage(with: BudgetVariables.hexStringToUIColor(hex: "00B22C"))
                }
                
                marker.tracksInfoWindowChanges = true
                mapView.selectedMarker = marker
                marker.map = mapView
            }
        }
        
        // Add the map to the map view
        self.myMapView.addSubview(mapView)
    }
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard()
    {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    // When the clear history button gets pressed, clear the history and disable button
    @IBAction func clearHistoryButtonWasPressed(_ sender: Any)
    {
        // Empty out arrays
        BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray.removeAll()
        BudgetVariables.budgetArray[BudgetVariables.currentIndex].descriptionArray.removeAll()
        
        // Revert the balance to its original value, and reset the variables
        let totalAmtAdded = BudgetVariables.budgetArray[BudgetVariables.currentIndex].totalAmountAdded
        let totalAmtSpent = BudgetVariables.budgetArray[BudgetVariables.currentIndex].totalAmountSpent
        let myBalance = BudgetVariables.budgetArray[BudgetVariables.currentIndex].balance
        let newBalanceAndBudgetAmount = myBalance - totalAmtAdded + totalAmtSpent
        BudgetVariables.budgetArray[BudgetVariables.currentIndex].balance = newBalanceAndBudgetAmount
        BudgetVariables.budgetArray[BudgetVariables.currentIndex].totalBudgetAmount = newBalanceAndBudgetAmount
        BudgetVariables.budgetArray[BudgetVariables.currentIndex].totalAmountAdded = 0.0
        BudgetVariables.budgetArray[BudgetVariables.currentIndex].totalAmountSpent = 0.0
        BudgetVariables.budgetArray[BudgetVariables.currentIndex].markerLatitude.removeAll()
        BudgetVariables.budgetArray[BudgetVariables.currentIndex].markerLongitude.removeAll()
        BudgetVariables.budgetArray[BudgetVariables.currentIndex].amountSpentOnDate.removeAll()
        
        // Zero out the total amount spent
        BudgetVariables.budgetArray[BudgetVariables.currentIndex].totalAmountSpent = 0.0
        
        // Save context and get data
        self.sharedDelegate.saveContext()
        BudgetVariables.getData()
        
        // Reload the table, refresh the markers, and disable the clear history button
        self.historyTable.reloadData()
        self.refreshMarkers()
        clearHistoryButton.isEnabled = false
    }
    
    // Functions that conform to UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // represents the number of rows the UITableView should have
        return BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray.count + 1
    }
    
    // Determines what data goes in what cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let myCell:UITableViewCell = historyTable.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath)
        let count = BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray.count
        
        // If it's the last cell, customize the message
        if indexPath.row == count
        {
            myCell.textLabel?.textColor = UIColor.lightGray
            myCell.detailTextLabel?.textColor = UIColor.lightGray
            myCell.textLabel?.text = "Swipe left to edit"
            myCell.detailTextLabel?.text = "Tap to locate"
        }
        else
        {
            myCell.textLabel?.textColor = UIColor.black
            myCell.detailTextLabel?.textColor = UIColor.black
            
            let str = BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray[indexPath.row]
            let index = str.index(str.startIndex, offsetBy: 0)
            
            if str[index] == "+"
            {
                myCell.textLabel?.textColor = BudgetVariables.hexStringToUIColor(hex: "00B22C")
            }
            
            if str[index] == "–"
            {
                myCell.textLabel?.textColor = BudgetVariables.hexStringToUIColor(hex: "FF0212")
            }
            
            myCell.textLabel?.text = BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray[indexPath.row]
            
            // String of the description
            let descripStr = BudgetVariables.budgetArray[BudgetVariables.currentIndex].descriptionArray[indexPath.row]
            
            // Create Detail Text
            let detailText = BudgetVariables.getDetailFromDescription(descripStr: descripStr)
            
            // Create Date Text
            let dateText = BudgetVariables.createDateText(descripStr: descripStr)
            
            // Display text
            let displayText = detailText + dateText
            myCell.detailTextLabel?.text = displayText
        }
        
        return myCell
    }
    
    // User cannot delete the last cell which contains information
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        // If it is the last cell which contains information, user cannot delete this cell
        if indexPath.row == BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray.count
        {
            return false
        }
        
        // Extract the amount spent for this specific transaction into the variable amountSpent
        let historyStr = BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray[indexPath.row]
        let index1 = historyStr.index(historyStr.startIndex, offsetBy: 0) // Index spans the first character in the string
        let index2 = historyStr.index(historyStr.startIndex, offsetBy: 3) // Index spans the amount spent in that transaction
        let amountSpent = Double(historyStr.substring(from: index2))
        
        // If after the deletion of a spend action the new balance is over 1M, user cannot delete this cell
        if historyStr[index1] == "–"
        {
            let newBalance = BudgetVariables.budgetArray[BudgetVariables.currentIndex].balance + amountSpent!
            if newBalance > 1000000
            {
                return false
            }
        }
        else if historyStr[index1] == "+"
        {
            let newBalance = BudgetVariables.budgetArray[BudgetVariables.currentIndex].balance - amountSpent!
            if newBalance < 0
            {
                return false
            }
        }
        
        return true
    }
    
    // Generates an array of custom buttons that appear after the swipe to the left
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        // Title is the text of the button
        let undo = UITableViewRowAction(style: .normal, title: " Undo")
        { (action, indexPath) in
            
            // Undo item at indexPath
            
            // Extract the key to the map in the format "MM/dd/YYYY" into the variable date
            let descripStr = BudgetVariables.budgetArray[BudgetVariables.currentIndex].descriptionArray[indexPath.row]
            let dateIndex = descripStr.index(descripStr.endIndex, offsetBy: -10)
            let date = descripStr.substring(from: dateIndex)
            
            // Extract the month and year from description so we can undo how much we spend a month
            let monthBegin = descripStr.index(descripStr.endIndex, offsetBy: -10)
            let monthEnd = descripStr.index(descripStr.endIndex, offsetBy: -9)
            let monthString = descripStr[monthBegin...monthEnd]
            let yearBegin = descripStr.index(descripStr.endIndex, offsetBy: -4)
            let yearString = descripStr.substring(from: yearBegin)
            let monthKey = monthString + "/" + yearString
            
            // Extract the amount spent for this specific transaction into the variable amountSpent
            let historyStr = BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray[indexPath.row]
            let index1 = historyStr.index(historyStr.startIndex, offsetBy: 0) // Index spans the first character in the string
            let index2 = historyStr.index(historyStr.startIndex, offsetBy: 3) // Index spans the amount spent in that transaction
            let historyValue = Double(historyStr.substring(from: index2))
            
            // If this specific piece of history logged a "Spend" action, the total amount spent should decrease after deletion
            if historyStr[index1] == "–"
            {
                let newAmtSpentOnDate = BudgetVariables.budgetArray[BudgetVariables.currentIndex].amountSpentOnDate[date]! - historyValue!
                BudgetVariables.budgetArray[BudgetVariables.currentIndex].amountSpentOnDate[date] = newAmtSpentOnDate
                let newAmtSpentInMonth = BudgetVariables.budgetArray[BudgetVariables.currentIndex].amountSpentOnDate[monthKey]! - historyValue!
                BudgetVariables.budgetArray[BudgetVariables.currentIndex].amountSpentOnDate[monthKey] = newAmtSpentInMonth
                let newTotalAmountSpent = BudgetVariables.budgetArray[BudgetVariables.currentIndex].totalAmountSpent - historyValue!
                BudgetVariables.budgetArray[BudgetVariables.currentIndex].totalAmountSpent = newTotalAmountSpent
                let newBalance = BudgetVariables.budgetArray[BudgetVariables.currentIndex].balance + historyValue!
                BudgetVariables.budgetArray[BudgetVariables.currentIndex].balance = newBalance
            }
                
            // If this action was an "Added to Budget" action
            else if historyStr[index1] == "+"
            {
                let newTotalAmountAdded = BudgetVariables.budgetArray[BudgetVariables.currentIndex].totalAmountAdded - historyValue!
                BudgetVariables.budgetArray[BudgetVariables.currentIndex].totalAmountAdded = newTotalAmountAdded
                let newBalance = BudgetVariables.budgetArray[BudgetVariables.currentIndex].balance - historyValue!
                BudgetVariables.budgetArray[BudgetVariables.currentIndex].balance = newBalance
                let newBudgetAmount = BudgetVariables.budgetArray[BudgetVariables.currentIndex].totalBudgetAmount - historyValue!
                BudgetVariables.budgetArray[BudgetVariables.currentIndex].totalBudgetAmount = newBudgetAmount
            }
            
            // Remove the latitude and longitude for the current row
            BudgetVariables.budgetArray[BudgetVariables.currentIndex].markerLatitude.remove(at: indexPath.row)
            BudgetVariables.budgetArray[BudgetVariables.currentIndex].markerLongitude.remove(at: indexPath.row)
            
            // Delete the row
            BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray.remove(at: indexPath.row)
            BudgetVariables.budgetArray[BudgetVariables.currentIndex].descriptionArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            self.sharedDelegate.saveContext()
            BudgetVariables.getData()
            
            // Refresh the map
            self.refreshMarkers()
            
            // Disable the clear history button if the cell deleted was the last item
            if BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray.isEmpty == true
            {
                self.clearHistoryButton.isEnabled = false
            }
            else
            {
                self.clearHistoryButton.isEnabled = true
            }
        }
        
        // Change the color of the undo button
        undo.backgroundColor = BudgetVariables.hexStringToUIColor(hex: "E74C3C")
        
        // Edit item at indexPath
        let edit = UITableViewRowAction(style: .normal, title: "Edit   ")
        { (action, indexPath) in
            
            // If it is not the last row
            if indexPath.row != BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray.count
            {
                let descripStr = BudgetVariables.budgetArray[BudgetVariables.currentIndex].descriptionArray[indexPath.row]
                let index = descripStr.index(descripStr.endIndex, offsetBy: -14)
                self.oldDescription = descripStr.substring(to: index)
                self.showEditDescriptionAlert(indexPath: indexPath)
            }
        }
        
        // Change the color of the edit button
        edit.backgroundColor = BudgetVariables.hexStringToUIColor(hex: "BBB7B0")
        
        return [undo, edit]
    }
    
    // When a cell is selected, focus the camera on the associated marker
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        // If it is not the last row
        if indexPath.row != BudgetVariables.budgetArray[BudgetVariables.currentIndex].historyArray.count
        {
            // Create a map view using the current width and height of the view
            let latitude = BudgetVariables.budgetArray[BudgetVariables.currentIndex].markerLatitude[indexPath.row]
            let longitude = BudgetVariables.budgetArray[BudgetVariables.currentIndex].markerLongitude[indexPath.row]
            
            // If the latitude and longitude are valid, animate the camera to that location, otherwise do nothing
            if latitude != 360 && longitude != 360
            {
                mapView.animate(toLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            }
        }
    }
    
    // Use this variable to enable and disable the Save button
    weak var saveButton : UIAlertAction?
    
    // Shows the alert pop-up
    func showEditDescriptionAlert(indexPath: IndexPath)
    {
        let alert = UIAlertController(title: "Edit Description", message: "", preferredStyle: UIAlertControllerStyle.alert)
        alert.addTextField(configurationHandler: {(textField: UITextField) in
            textField.placeholder = "New Description"
            
            // Grab old description and put it into the initial textfield
            let oldDescription = BudgetVariables.budgetArray[BudgetVariables.currentIndex].descriptionArray[indexPath.row]
            textField.text = BudgetVariables.getDetailFromDescription(descripStr: oldDescription)
            
            textField.delegate = self
            textField.autocapitalizationType = .sentences
            textField.addTarget(self, action: #selector(self.inputDescriptionDidChange(_:)), for: .editingChanged)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (_) -> Void in
        })
        
        let save = UIAlertAction(title: "Save", style: UIAlertActionStyle.default, handler: { (_) -> Void in
            var inputDescription = alert.textFields![0].text
            
            // Trim the inputName first
            inputDescription = inputDescription?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            // Get old description
            let oldDescription = BudgetVariables.budgetArray[BudgetVariables.currentIndex].descriptionArray[indexPath.row]
            
            // Change the current description
            let date = BudgetVariables.getDateFromDescription(descripStr: oldDescription)
            BudgetVariables.budgetArray[BudgetVariables.currentIndex].descriptionArray[indexPath.row] = inputDescription! + "    " + date
            self.historyTable.reloadRows(at: [indexPath], with: .fade)
            
            // Save and get data to coredata
            self.sharedDelegate.saveContext()
            BudgetVariables.getData()
            
            // Reload the table
            self.historyTable.reloadData()
            
            // Refresh the map
            self.refreshMarkers()
        })
        
        alert.addAction(save)
        alert.addAction(cancel)
        
        self.saveButton = save
        save.isEnabled = false
        self.present(alert, animated: true, completion: nil)
    }
    
    // Holds the old description of cell pressed
    var oldDescription: String = ""
    
    // Enable save button if the description doesn't equal current description
    func inputDescriptionDidChange(_ textField: UITextField)
    {
        let inputDescription = textField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if inputDescription != self.oldDescription
        {
            self.saveButton?.isEnabled = true
        }
        else
        {
            self.saveButton?.isEnabled = false
        }
    }
    
    // This function limits the maximum character count for a textField
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
        var maxLength = 0
        
        if textField.placeholder == "New Description"
        {
            maxLength = 22
        }
        
        let currentString = textField.text as NSString?
        let newString = currentString?.replacingCharacters(in: range, with: string)
        return newString!.characters.count <= maxLength
    }
}