      ****************************************************************
      *      ________________                                        *
      *      |               |    Wicked Smaht! Technologies         *
      *      | Brian L Inc.  |    4777 W. Daybreak Rim way.          *
      *      |               |    South Jordan, UT 84009             *
      *      |_______________|                                       *
      *                                                              *
      *            Program Name:  INVMASTER                          *
      *                                                              *
      *     Program Description:  Utility: Maintain Inventory        *
      *                           for Cash Register App              *
      *                                                              *
      *              Programmer:  Brian Lannoye                      *
      *              Date Coded:  07/03/2026                         *
      *                 Request:  Avocation - Create an inventory    *
      *                           app to support the POS app         *
      * ----------------------  Modifications  --------------------- *
      *                                                              *
      *   Date    Pgmr  Req     Description                          *
      ****************************************************************
**FREE
ctl-opt dftactgrp(*no) actgrp(*caller);

// Define Files
dcl-f dinvmaster workstn indds(dspfInds) sfile(SFLREC: rrn);
dcl-f invmast01 disk(*ext) keyed usage(*input:*update:*output);
dcl-f invmast02 disk(*ext) keyed usage(*update)
rename(INVRF:INVRCD);

// Named Display Indicators Mapping (INDDS)
dcl-ds dspfInds len(99);
  exit         ind pos(03);
  add          ind pos(06);
  cancel       ind pos(12);
  sflDisplay   ind pos(31);
  sflCtlDisp   ind pos(32);
  sflClear     ind pos(33);
  sflEnd       ind pos(34);
  altclr       ind pos(40);
end-ds;

// Standalone Variables
dcl-s rrn          int(5);
dcl-s nextItemNum  char(5) dtaara('BRIANHD711/NEXTITEM');
dcl-s wkSearch char(45);

// Main Program Entry

dow not exit;
  exsr initSubfile;
  // Write the lower input/edit form, then EXFMT the upper Subfile Control
  write FOOTER;
  EXFMT SFLCTL;

  if exit;
    leave;
  endif;

  // Process any action options or search requests
  if sflDisplay;
    exsr ProcessSubfileSelections;
  endif;
  if add;
    exsr clearFormFields;
    exsr addItem;
  endif;

  if SRCHITEM <> *blanks;
    exsr InitSubfile;
  endif;
enddo;

*inlr = *on;
return;
// =================================================================*
// SUBROUTINE: Add item to inventory master
// =================================================================*
begsr AddItem;
    w1header = 'Add Item';
    in *lock nextItemNum;
    w1item = nextItemNum;
    exfmt invwin01;

    if not cancel and w1desc <> *blanks and w1price > 0;
      itemnumber = w1item;
      itemdesc  = w1desc;
      category = w1cat;
      itemcost  = w1cost;
      itemprice = w1price;
      itemqty   = w1qty;
      ordthresh = w1thresh;
      itemorig = w1orig;

      // 3. Write \Z\Zrecord in the database
      write invrf; // Best practice: use the Record Format name here
      evalr nextItemNum = %editc(%int(nextItemNum) + 1 : 'X');
    endif;
    out nextItemNum;
endsr;
// =================================================================*
// SUBROUTINE: Clear fields to make way for new record
// =================================================================*
begsr clearFormFields;
    w1Item = '';
    w1desc = '';
    w1cat = '';
    w1cost = 0.00;
    w1price = 0.00;
    w1qty = 0;
    w1thresh = 0;
    w1orig = '';
endsr;
// =================================================================*
// SUBROUTINE: Initialize, Clear, and Load the Subfile List
// =================================================================*
begsr InitSubfile;

  // 1. Clear the Subfile
  sflDisplay = *off;
  sflCtlDisp = *off;
  sflEnd     = *off;
  sflClear   = *on;
  write SFLCTL;

  sflClear   = *off;
  rrn        = 0;

  // 2. Query/Read from Database Table
  if SRCHITEM <> *blanks;
    wkSearch = SRCHITEM;
    setll wkSearch invmast02;
  else;
    setll *loval invmast02;
  endif;
  read invmast02;

  // 3. Populate up to SFLPAG size constraints (7 items maximum)
  dow not %eof(invmast02);
    rrn += 1;
    // Map Db Table fields to display subfile grid row fields
    SFLOPT   = ' ';
    SFLITEM  = ItemNumber;
    SFLDESC = %subst(ItemDesc: 1: %min(45: %len(ItemDesc))); // Safe extraction for truncated header
    SFLQTY   = ItemQty;

    write SFLREC;
    read invmast02;
  enddo;


  // 4. Reset indicators based on whether items were found
  if rrn > 0;

    sflDisplay = *on;
    sflCtlDisp = *on;
    sflEnd     = *on;
  else;
    sflCtlDisp = *on; // Keep header visible even if grid empty
    MSG = 'No inventory items found matching selection.';
  endif;

endsr;

// =================================================================*
// SUBROUTINE: Read Modified Rows to Route Actions into the Form
// =================================================================*
begsr ProcessSubfileSelections;

  // Read next row changed by user entry
  readc SFLREC;

  dow not %eof;

       // Evaluate chosen option: 1=View Record, 2=Add Record, 3=Edit Record
    select;
     when sflopt = '1';
       chain sfldesc invmast02;
       if %found(invmast02);
         // Bind exact properties to the modal container fields
         w0item  = itemnumber;
         w0cat = category;
         w0desc  = itemdesc;
         w0cost  = itemcost;
         w0price = itemprice;
         w0qty   = itemqty;
         w0thresh = ordthresh;
         w0orig = itemorig;
         exfmt invwin00;
       endif;
     when sflopt = '2';
       chain sflitem invmast01;
       w1header = 'Edit Item';
       if %found(invmast01);
         // Bind exact properties to the modal container fields
         w1item  = itemnumber;
         w1cat = category;
         w1desc  = itemdesc;
         w1cost  = itemcost;
         w1price = itemprice;
         w1qty   = itemqty;
         w1thresh = ordthresh;
         w1orig = itemorig;
         exfmt invwin01;

         chain w1item invmast01;
         if %found(invmast01);
           itemdesc  = w1desc;
           category = w1cat;
           itemcost  = w1cost;
           itemprice = w1price;
           itemqty   = w1qty;
           ordthresh = w1thresh;
           itemorig = w1orig;

           // 3. Update the record in the database
           update invrf; // Best practice: use the Record Format name here
        endif;
       endif;
    endsl;

    // Reset option column and update row status buffer
    SFLOPT = ' ';
    update SFLREC;
    readc SFLREC;
  enddo;

endsr;

