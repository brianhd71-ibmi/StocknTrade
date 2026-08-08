## Stock'n Trade (INVSTOCK) — User Operations Manual
This guide outlines how to navigate and manage inventory using the Stock'n Trade green-screen terminal interface. Note: see section Set lookup data for categories and origins to create standardized data before you begin
------------------------------
## 🖥️ Screen Layout Overview
The terminal dashboard is broken down into three functional zones:

* Header Zone: Displays the current date, time, and global searching utility.
* Subfile Grid (Body): Shows up to 8 real-time inventory rows displaying ITEM ID, DESCRIPTION, stock quantities (QTY), and operational COST.
* Footer Toolbar: Provides dynamic function key indicators mapping to system actions.

------------------------------
## 🔍 Searching Items
Filter or locate records rapidly from the database list using the global index search:

   1. Use your cursor to target the entry field next to SEARCH ITEM..:.
   2. Type in your search text (e.g., partial brand names like FENDER or item numbers).
   3. Press [Enter] to refresh the grid layout with matching results.

------------------------------
## 🛠️ Item Actions & Grid Navigation
Manage existing row entities by typing action codes directly into the O (Option) selection column located on the far left side of the data grid:

* View Details: Type 1 next to an item and press [Enter] to open the descriptive summary model window.
* Edit Record: Type 2 next to an item and press [Enter] to update quantities, pricing schemas, or thresholds.
* Scroll Data Pages: Look for the bottom-right status text indicator. If it reads More... instead of Bottom, press your [Page Down] key to reveal subsequent pages of stock records.

------------------------------
## ⌨️ Function Key Mapping

| Function Key | Command | Description |
|---|---|---|
| F3 | EXIT | Safely terminates the execution cycle and unlocks system data areas. |
| F6 | Add New | Launches a clean database insertion window to assign a new inventory product. |
| [Enter] | Process | Submits your row selections (1 or 2) or commits search text criteria. |

------------------------------
## 📝 Using the Add or Edit Item Window
When selecting 2=Edit on a grid item or pressing F6=Add New, a dedicated modal window overlays your terminal screen. Use this workspace to maintain precise record details.
## 🔍 Interactive Category & Origin Lookups
To prevent manual data entry errors and speed up processing, both the Category and Origin input fields feature automated subprogram lookups:

* Forced Lookup: Key in 0000 into the code field and press [Enter] to intentionally trigger a lookup search list window.
* Direct Entry: Key in a known 4-digit code directly into the target field.
* Automatic Error Recovery: If you enter an invalid or unrecognized code, the system will not crash or send a disruptive hard error message. Instead, it gracefully intercepts the input and automatically opens the lookup helper so you can pick the correct assignment.

## ⌨️ Window Controls & Navigation

* [Tab] / Arrow Keys: Navigate sequentially down through entry fields (Cost, Price, Quantity, etc.).
* [Enter] then F5=Save: Validates your modifications or new entry fields, clears the transaction log, and commits the records safely to the master physical tables.
* F12=Cancel: Closes the modal window immediately without saving, safely releasing file tracking locks (unlock instock01).

## Set lookup data for categories and origins
 For these two standardized fields you will want to set up date for the user to choose from rather than keying in whatever they think is appropriate.  To add data to these two simple applications: 
 * call itemcat - click F6 to add a category, or place a 2 on an existing category to edit
 * call itemorig - click F6 to add an origin , or place a 2 on an existing origin to edit


