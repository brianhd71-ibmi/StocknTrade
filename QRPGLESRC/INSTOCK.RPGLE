      ****************************************************************
      *      ________________                                        *
      *      |Vintage        |    R.P. Vintage SS                    *
      *      |   Software    |    4777 W. Daybreak Rim way.          *
      *      |      Solutions|    South Jordan, UT 84009             *
      *      |_______________|                                       *
      *                                                              *
      *            Program Name:  INVSTOCK                           *
      *                                                              *
      *     Program Description:  Utility: Maintain Inventory        *
      *                           for Terminal Transactions App      *
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

dcl-pr promptCatFields extpgm('CATLOOKUP');
  *n       char(4);
  *n       char(25);
end-pr;

dcl-pr promptOrgFields extpgm('ORGLOOKUP');
  *n       char(4);
  *n       char(25);
end-pr;


// Define Files
dcl-f dinstock workstn indds(dspfInds) sfile(SFLREC: rrn);
dcl-f instock01 disk(*ext) keyed usage(*input:*update:*output);
dcl-f instock02 disk(*ext) keyed usage(*input:*update:*output)
rename(INSTK:INVRCD);
dcl-f CatLookup usage(*input) keyed rename(CATLOOKUP:CATLKUP01) prefix(db_);
dcl-f OrgLookup usage(*input) keyed rename(ORGLOOKUP:ORGLKUP01) prefix(db_);

// Named Display Indicators Mapping (INDDS)
dcl-ds dspfInds len(99);
  exit         ind pos(03);
  save         ind pos(05);
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
dcl-s saveCategory char(25);
dcl-s saveCatNum   char(4);
dcl-s saveOrigin   char(25);
dcl-s saveOrgNum   char(4);
dcl-s wkSearch     char(45);

//--------------------------------------------------------
//          /*       Main Processing       */
//--------------------------------------------------------
today = %char(%date(): *usa);

dow not exit;
  exsr initSubfile;
  // Write the lower input/edit form, then EXFMT the upper Subfile Control
  write FOOTER;
  EXFMT SFLCTL;
  msg = '';

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
    out nextItemNum;

    dow cancel = *off and  save = *off;
      saveCatNum = w1CatNum;
      saveOrgNum = w1OrigNum;
      exfmt invwin01;
      itemnumber = w1item;

      if saveCatnum <> w1CatNum;
        getCategoryFields();
        iter;
      endif;

      if saveOrgnum <> w1OrigNum;
        getOriginFields();
        iter;
      endif;

      catnum = w1CatNum;
      itemdesc  = w1desc;
      itemcost = %dec(w1cost : 7 : 2);
      itemprice = %dec(w1price : 7 : 2);
      itemdisc = %dec(w1disc : 2 : 0);
      itemqty   = w1qty;
      ordthresh = w1thresh;
      origNum = w1OrigNum;
    enddo;

    if cancel = *off and w1Desc <> *blanks;
      write instk; // Best practice: use the Record Format name here
      in *lock nextItemNum;
      evalr nextItemNum = %editc(%int(nextItemNum) + 1 : 'X');
      out nextItemNum;
    endif;
endsr;

// =================================================================*
// SUBROUTINE: Clear fields to make way for new record
// =================================================================*
begsr clearFormFields;
    w1Item = '';
    w1desc = '';
    w1CatNum = '';
    w1cat = '';
    w1cost = '0.00';
    w1price = '0.00';
    w1disc = '00';
    w1qty = 0;
    w1thresh = 0;
    w1OrigNum = '';
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
    setll wkSearch instock02;
  else;
    setll *loval instock02;
  endif;
  read instock02;

  // 3. Populate up to SFLPAG size constraints (7 items maximum)
  dow not %eof(instock02);
    rrn += 1;
    // Map Db Table fields to display subfile grid row fields
    sflopt  = ' ';
    sflitem  = ItemNumber;
    sfldesc = %subst(ItemDesc: 1: %min(45: %len(ItemDesc))); // Safe extraction for truncated header
    sflqty = ItemQty;
    sflcost = itemcost;

    write sflrec;
    read instock02;
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
  readc sflrec;

  dow not %eof;
       // Evaluate chosen option: 1=View Record, 2=Add Record, 3=Edit Record
    select;
     when sflopt = '1';
       clear invwin00;
       chain sfldesc instock02;
       if %found(instock02);
         // Bind exact properties to the modal container fields
         w0item  = itemnumber;
         w0desc  = itemdesc;
         w0cost  = itemcost;
         w0price = itemprice;
         W0disc = itemdisc;
         w0qty   = itemqty;
         w0thresh = ordthresh;

         chain orignum OrgLookup;
         if %found(OrgLookup);
           w0Orig = db_origin;
         endif;

         chain catnum CatLookup;
         if %found(CatLookup);
           w0Cat = db_category;
         endif;

         exfmt invwin00;
       endif;
     when sflopt = '2';
       clear invwin01;
       w1header = 'Edit Item';
       chain sflitem instock01;
       if %found(instock01);
         // Bind exact properties to the modal container fields
         w1item  = itemnumber;
         w1desc  = itemdesc;
         evalr w1cost = %trim(%editc(itemcost : 'P'));
         evalr w1price = %trim(%editc(itemprice : 'P'));
         evalr w1disc = %trim(%editc(itemdisc : '3'));
         w1qty   = itemqty;
         w1thresh = ordthresh;

         chain orignum OrgLookup;
         if %found(OrgLookup);
           w1Orig = db_origin;
         endif;

         chain catnum CatLookup;
         if %found(CatLookup);
           w1Cat = db_category;
         endif;

           saveCatNum = w1CatNum;
           saveOrgNum = w1OrigNum;
         dow save = *off;
           exfmt invwin01;

           if cancel = *on;
             unlock instock01;
             leave;
           endif;

           chain w1Item instock01;
           if %found(instock01);
             itemdesc  = w1desc;
             itemcost = %dec(w1cost : 7 : 2);
             itemprice = %dec(w1price : 7 : 2);
             itemdisc = %int(w1disc);
             itemqty   = w1qty;
             ordthresh = w1thresh;
           endif;

           if saveCatnum <> w1CatNum;
             getCategoryFields();
             catnum = w1CatNum;
           endif;

           if saveOrgnum <> w1OrigNum;
              getOriginFields();
             origNum = w1OrigNum;
           endif;
         enddo;
         if save = *on;   // 3. Update the record in the database
           update instk; // Best practice: use the Record Format name here
         endif;
       endif;
    endsl;
    sflopt = ' ';
    update sflrec;
    readc sflrec;
  enddo;

endsr;

// =================================================================*
// PROCEDURE: returns the category description
// =================================================================*
dcl-proc getCategoryFields;

  if not cancel;
    if w1CatNum = '0000';
      promptCatFields(w1CatNum : w1Cat);
    else;
      chain w1catnum CatLookup;
      if %found(CatLookup);
        w1Cat = db_category;
      else;
        promptCatFields(w1CatNum : w1Cat);
      endif;
    endif;
  endif;

  //return w1Cat;
end-proc;

// =================================================================*
// PROCEDURE: returns the category description
// =================================================================*
dcl-proc getOriginFields;

  if not cancel;
    if w1OrigNum = '0000';
      promptOrgFields(w1OrigNum : w1Orig);
    else;
      chain w1OrigNum OrgLookup;
      if %found(OrgLookup);
        w1Orig = db_origin;
      else;
        promptOrgFields(w1OrigNum : w1Orig);
      endif;
    endif;
  endif;

  //return w1Orig;
end-proc;

