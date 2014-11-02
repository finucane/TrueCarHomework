For the TrueCar Mobile Challenge Assignment I wrote an iOS app called "TrueCar". 

The app loads the csv file on a background thread and feeds a UITableViewController with data as it's being read. The parsing notifies the rest of the app that new data has been read by means of a notification. The code for that is Model/TCCars.[mh] It uses underscores in instance variables/class members because I thought that the TrueCar people would care about that superstition.

For simplicity the top level table view is reloaded as each new make is read from the file, a better implementation might just add new rows. The app uses a 3rd party library called CHCSVParser to do the csv parsing.

The data is shown in a hierarchy of table views and at the 2nd level, there's a list of models arranged in sections where each section is a year. When the user selects a model, then the app uses the model information to run a craigslist search for used cars, for sale by owner only.

Since craigslist doesn't have an API, the data is scraped from the site. This is a toy app, so scraping is OK, in a real app if there had to be scraping, it would be done on a server.

The lowest table view controller is a list of matching cars for sale on craigslist. If the user selects a car in the list, the app displays the craigslist page itself in a web view.

The craigslist querying is done in serial (one network request for each page of results) out of simplicity. The networking and scraping is done in a background thread and a callback tells the table view controller that new data has arrived.

The UI is bare-bones. The app doesn't try to do the cool thing the actual TrueCar app does, where lower "screens" in the hierarchy are displayed in place, rather than popped onto a navigation controller.

Errors are reported to the user in a UIAlertView. Feedback that a craigslist query is underway, and that a page itself is being loaded, is shown by the network activity thing, this was out of simplicity. There's no indication of the underlying app data (the csv file) read being done, this was out of simplicity as well.

If this were a real app, the first change that might be made to it would be taking more care about the cell heights in the table view that shows the list of craigslist results. Depending on how many lines the title has, the cell should be less tall. 

The code is arranged in 4 folders:
Library -- categories and stuff I stole from previous apps I wrote.
Model - classes that have nothing to do with UI
View - UIKit classes (view controllers mainly)
CHCSVParser - the 3rd party csv parser.

There's no unit testing and even though human readable strings are wrapped in NSLocalizedString there's not any localized string table.
