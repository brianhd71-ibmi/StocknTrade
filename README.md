## Stock'n Trade (INVSTOCK) — User Operations Manual
This guide outlines how to navigate and manage inventory using the Stock'n Trade green-screen terminal interface. 
Note: See section - Setup located below before you begin
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
* Automatic Error Recovery: If you enter an invalid or unrecognized code, the system will not crash or send a disruptive hard error message. Instead, it gracefully intercepts the input and automatically opens the lookup helper so you can pick the correct selection.

## ⌨️ Window Controls & Navigation

* [Tab] / Arrow Keys: Navigate sequentially down through entry fields (Cost, Price, Quantity, etc.).
* [Enter] then F5=Save: Validates your modifications or new entry fields, clears the transaction log, and commits the records safely to the master physical tables.
* F12=Cancel: Closes the modal window immediately without saving, safely releasing file tracking locks (unlock instock01).

## Create Data Areas to assign new ID numbers
The way Stock 'N Trade assigns new ID numbers for each major application is through data areas. The general syntax is:
* CRTDTAARA DTAARA(MYLIBRARY/MYDATAARA) TYPE(*CHAR) LEN({Length of ID number}) VALUE('Initial Value')TEXT('My Data Area Description')

You must seed the data area with a starting number and your application will automatically increment the number for a new item, category, transaction etc.. ID number data areas are: 
* NEXTITEM  char(5)
* NEXTCAT   char(4)
* NEXTORG   char(4)
* XACTION   char(9)

You must modifiy the source code in InStock, ItemCat, ItemOrg and Terminal respectively to point to your library.

## Create tables and compile objects
* Table definitions located in SQL folder
* Download and save DDS and RPGLE members to appropriate folders and compile
* Optional to download menu objects
  
## Set lookup data for categories and origins
 For these two standardized fields you will want to set up date for the user to choose from rather than keying in whatever they think is appropriate.  To add data to these two simple applications: 
 * call itemcat - click F6 to add a category, or place a 2 on an existing category to edit
 * call itemorg - click F6 to add an origin , or place a 2 on an existing origin to edit


## New files added (reports, terminal UI, and print files)
The following new source members were added to the repository. Quick descriptions, repository paths, and example compile/run commands are listed below.

- [QRPGLESRC/TERMINAL.SQLRPGLE](/Users/brianlannoye/Desktop/Pub400/TT/StocknTrade/QRPGLESRC/TERMINAL.SQLRPGLE)
  - Terminal Transactions program (POS terminal UI). Uses the display file [QDDSSRC/DTERMINAL.DSPF] to render the subfile-based transaction screen and function keys.

- [QDDSSRC/DTERMINAL.DSPF](/Users/brianlannoye/Desktop/Pub400/TT/StocknTrade/QDDSSRC/DTERMINAL.DSPF)
  - Display file for the terminal UI. Contains subfile layout (9 line slots), function-key indicators (F2/F3/F6/F12 etc.), and right-side transaction entry/totals area.

- [QRPGLESRC/STOCKLIST.SQLRPGLE](/Users/brianlannoye/Desktop/Pub400/TT/StocknTrade/QRPGLESRC/STOCKLIST.SQLRPGLE)
  - Stock listing report program. Produces output via printer file [QDDSSRC/PSTOCKLIST.PRTF].

- [QDDSSRC/PSTOCKLIST.PRTF](/Users/brianlannoye/Desktop/Pub400/TT/StocknTrade/QDDSSRC/PSTOCKLIST.PRTF)
  - Printer file definition used by the StockList report.

- [QRPGLESRC/SALESRPT.SQLRPGLE](/Users/brianlannoye/Desktop/Pub400/TT/StocknTrade/QRPGLESRC/SALESRPT.SQLRPGLE)
  - Sales report generator (detail and header processing). Queries XMASTER/XDETAIL for processed sales and prints to [QDDSSRC/PSALESRPT.PRTF].

- [QDDSSRC/PSALESRPT.PRTF](/Users/brianlannoye/Desktop/Pub400/TT/StocknTrade/QDDSSRC/PSALESRPT.PRTF)
  - Printer file definition used by the SalesRPT program. Includes header/detail formats for transactions and transaction line items.

- [QRPGLESRC/OSALESRPT.RPGLE](/Users/brianlannoye/Desktop/Pub400/TT/StocknTrade/QRPGLESRC/OSALESRPT.RPGLE)
  - Options/menu program that displays a small screen (summary vs detail) and launches the SalesRPT report program accordingly.

### Example compile/install commands (IBM i)
Replace MYLIB with the target library where you keep source and objects.

- Compile display and printer file members (DDS -> file objects):
  - CRTDSPF FILE(MYLIB/DTERMINAL) SRCFILE(MYLIB/QDDSSRC) SRCMBR(DTERMINAL)
  - CRTPRTF FILE(MYLIB/PSTOCKLIST) SRCFILE(MYLIB/QDDSSRC) SRCMBR(PSTOCKLIST)
  - CRTPRTF FILE(MYLIB/PSALESRPT) SRCFILE(MYLIB/QDDSSRC) SRCMBR(PSALESRPT)

- Compile SQLRPGLE programs (uses embedded SQL):
  - CRTSQLRPGI OBJ(MYLIB/TERMINAL) SRCFILE(MYLIB/QRPGLESRC) SRCMBR(TERMINAL)
  - CRTSQLRPGI OBJ(MYLIB/STOCKLIST) SRCFILE(MYLIB/QRPGLESRC) SRCMBR(STOCKLIST)
  - CRTSQLRPGI OBJ(MYLIB/SALESRPT) SRCFILE(MYLIB/QRPGLESRC) SRCMBR(SALESRPT)
  - CRTPGM OBJ(MYLIB/OSALESRPT) SRCFILE(MYLIB/QRPGLESRC) SRCMBR(OSALESRPT)

Notes:
- If your environment requires different compile options (debug, activation group, or service program linkage), add those options to the CRTSQLRPGI/CRTDSPF/CRTPRTF commands as appropriate.
- The SQLRPGLE programs use embedded SQL; ensure your library list and commitment level are set correctly when compiling and running.

### How to run
- Terminal UI: CALL PGM(MYLIB/TERMINAL) — opens the terminal transactions UI (requires the DTERMINAL display file to be available in MYLIB).
  - F6 to begin a new sale.  Enter item ID or 00000 to search for an item.  F7 to void an item and F2 to complete the sale.  F3 to exit the terminal.
- Stock list report: CALL PGM(MYLIB/STOCKLIST) — writes to the PSTOCKLIST printer file (ensure a printer device is configured or the file is directed to an SPOOL file you can view).
- Sales report:
  - CALL PGM(MYLIB/OSALESRPT) — this program presents options (summary or detail). Choose the option to run [MYLIB/SALESRPT].
  - Note: The SalesRPT program accepts optional parameters when called directly: a scope flag (summary vs detail) and an optional transaction number to filter to a single transaction.
    - Parameter 1 (scope flag): pass '1' to request summary-only output, pass '0' to request detail output (including transaction line items). If omitted, SalesRPT defaults to detail output.
    - Parameter 2 (transaction number): pass a 9-character transaction number (e.g., '000001234') to restrict the report to a single transaction. If omitted or blank, the report includes all processed sales.

    Examples (IBM i CALL usage):
    - Summary for a single transaction: CALL PGM(MYLIB/SALESRPT) PARM('1' '000001234')
    - Detail for a single transaction:  CALL PGM(MYLIB/SALESRPT) PARM('0' '000001234')
    - All processed sales (detail, default):  CALL PGM(MYLIB/SALESRPT)
