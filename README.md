# Pocket-Change
IOS App made from scratch that helps users manage their personal expenses and log their day-to-day transactions

# Features
‣ Create a budget with a name and starting balance <br />
‣ Withdraw or deposit money from the corresponding budget <br />
‣ Manage multiple budgets at once <br />
‣ View your entire, color-coded history log of how much money was spent and why it was spent <br />
‣ Delete one or all items of your transaction history <br />
‣ Rename and delete budgets <br />

# Design
‣ CoreData allows for pertinent information to be stored regardless of whether or not the app is running <br />
‣ Buttons enable and disable dynamically based on the validity of input: <br />
&nbsp;&nbsp;&nbsp;&nbsp;– Balance must be between $0 and $1,000,000 <br />
&nbsp;&nbsp;&nbsp;&nbsp;– Withdraw button only enables when your balance is enough based on current input <br />
&nbsp;&nbsp;&nbsp;&nbsp;– Renaming actions require the new name to be unique <br />
‣ History of transactions have a corresponding color: <br />
&nbsp;&nbsp;&nbsp;&nbsp;– Red for money spent <br />
&nbsp;&nbsp;&nbsp;&nbsp;– Green for money deposited <br />
‣ Creating names will add (a number) if the name already exists: <br />
&nbsp;&nbsp;&nbsp;&nbsp;– I.E. if "Mall" is already a budget name, naming a new one "Mall" automatically results in "Mall (1)", etc. <br />
‣ Number Formatter: <br />
&nbsp;&nbsp;&nbsp;&nbsp;– If we don't need commas, balance is shown with two decimal places <br />
&nbsp;&nbsp;&nbsp;&nbsp;– If we do need commas, balance has two decimal places only if needed <br />
&nbsp;&nbsp;&nbsp;&nbsp;– For instance 999 is displayed as $999.00, 1000 is displayed as $1,000, and 1000.27 is displayed as $1,000.27 <br /> 
‣ Programmatically utilized alerts to record user input <br />
‣ List of budgets and each budget's history is displayed using a UITableview <br />
‣ Used IBOutlets to programmatically interact with user interface elements <br />
‣ Defined an IBAction function that corrects button-enabling every time the user types or deletes a character <br /> 

# Screenshots
![alt tag](http://i.imgur.com/a7IUKVY.png) &nbsp;
![alt tag](http://i.imgur.com/a7IUKVY.png) &nbsp;
![alt tag](http://i.imgur.com/a7IUKVY.png)