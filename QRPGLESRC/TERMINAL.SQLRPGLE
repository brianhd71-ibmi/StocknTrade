      ****************************************************************
      *      ________________                                        *
      *      |Vintage        |    R.P. Vintage LLC.                  *
      *      |   Software    |    4777 W. Daybreak Rim way.          *
      *      |      Solutions|    South Jordan, UT 84009             *
      *      |_______________|                                       *
      *                                                              *
      *            Program Name:  Terminal Transactions              *
      *                                                              *
      *     Program Description:  POS: Transaction Terminal          *
      *                                for Stock'nTrade              *
      *                                                              *
      *              Programmer:  Brian Lannoye                      *
      *              Date Coded:  07/17/2026                         *
      *                 Request:  Avocation -  Point of Sale app     *
      *                                                              *
      * ----------------------  Modifications  --------------------- *
      *                                                              *
      *   Date    Pgmr  Req     Description                          *
      ****************************************************************
**FREE
ctl-opt dftactgrp(*no) actgrp(*caller);

dcl-pr promptStkFields extpgm('STKLOOKUP');
  *n       char(5);
end-pr;

// Define Files
dcl-f dterminal workstn indds(dspfInds);
dcl-f xDetail disk(*ext) keyed usage(*input) rename(XDETAIL:XREC);


// Named Display Indicators Mapping (INDDS)
dcl-ds dspfInds len(99);
  pay          ind pos(02);
  exit         ind pos(03);
  newxAction   ind pos(06);
  voidItem     ind pos(07);
  scrollup     ind pos(08);
  scrolldown   ind pos(09);
  cancel       ind pos(12);
  active       ind pos(40);
  itemVoid     ind pos(50);
  *n           ind pos(81);
  *n           ind pos(82);
  *n           ind pos(83);
  *n           ind pos(84);
end-ds;

dcl-ds itemFieldsDs inz;
  ITEMLINE01 zoned(3:0);
  ITEMLINE02 zoned(3:0);
  ITEMLINE03 zoned(3:0);
  ITEMLINE04 zoned(3:0);
  ITEMLINE05 zoned(3:0);
  ITEMLINE06 zoned(3:0);
  ITEMLINE07 zoned(3:0);
  ITEMLINE08 zoned(3:0);
  ITEMLINE09 zoned(3:0);
  itemLines zoned(3:0) dim(9) pos(1);
end-ds;

dcl-ds itemNumDs;
  ITEMNUM01 char(5);
  ITEMNUM02 char(5);
  ITEMNUM03 char(5);
  ITEMNUM04 char(5);
  ITEMNUM05 char(5);
  ITEMNUM06 char(5);
  ITEMNUM07 char(5);
  ITEMNUM08 char(5);
  ITEMNUM09 char(5);
  itemNums char(5) dim(9) pos(1);
end-ds;

dcl-ds itemDescDs;
  ITEMDESC01 char(45);
  ITEMDESC02 char(45);
  ITEMDESC03 char(45);
  ITEMDESC04 char(45);
  ITEMDESC05 char(45);
  ITEMDESC06 char(45);
  ITEMDESC07 char(45);
  ITEMDESC08 char(45);
  ITEMDESC09 char(45);
  itemDescs char(45) dim(9) pos(1);
end-ds;

dcl-ds itemQtyDs inz;
  ITEMQTY01 zoned(3:0);
  ITEMQTY02 zoned(3:0);
  ITEMQTY03 zoned(3:0);
  ITEMQTY04 zoned(3:0);
  ITEMQTY05 zoned(3:0);
  ITEMQTY06 zoned(3:0);
  ITEMQTY07 zoned(3:0);
  ITEMQTY08 zoned(3:0);
  ITEMQTY09 zoned(3:0);
  itemQtys zoned(3:0) dim(9) pos(1);
end-ds;

dcl-ds itemPriceDs inz;
  ITEMPRIC01 zoned(7:2);
  ITEMPRIC02 zoned(7:2);
  ITEMPRIC03 zoned(7:2);
  ITEMPRIC04 zoned(7:2);
  ITEMPRIC05 zoned(7:2);
  ITEMPRIC06 zoned(7:2);
  ITEMPRIC07 zoned(7:2);
  ITEMPRIC08 zoned(7:2);
  ITEMPRIC09 zoned(7:2);
  itemPrices zoned(7:2) dim(9) pos(1);
end-ds;

dcl-ds dspVoidDs;
  DSPVOID01 char(8);
  DSPVOID02 char(8);
  DSPVOID03 char(8);
  DSPVOID04 char(8);
  DSPVOID05 char(8);
  DSPVOID06 char(8);
  DSPVOID07 char(8);
  DSPVOID08 char(8);
  DSPVOID09 char(8);
  dspVoids char(8) dim(9) pos(1);
end-ds;

dcl-ds itemDiscountDs inz;
  ITEMDISC01 zoned(7:2);
  ITEMDISC02 zoned(7:2);
  ITEMDISC03 zoned(7:2);
  ITEMDISC04 zoned(7:2);
  ITEMDISC05 zoned(7:2);
  ITEMDISC06 zoned(7:2);
  ITEMDISC07 zoned(7:2);
  ITEMDISC08 zoned(7:2);
  ITEMDISC09 zoned(7:2);
  itemDiscs zoned(7:2) dim(9) pos(1);
end-ds;

// Constants
dcl-c ADD   'add';
dcl-c LIST_SIZE 9;
dcl-c SQL_FOUND '00000';
dcl-c TAX_RATE .05;
dcl-c VOID '**VOID**';

// Standalone Variables
dcl-s nextTransactionNum char(9) dtaara('BRIANHD711/XACTION');

exec sql SET OPTION COMMIT = *NONE;
//--------------------------------------------------------
//          /*       Main Processing       */
//--------------------------------------------------------
storenum = '8271971';
today = %char(%date(): *usa); // Adjust date format (*USA, *eur, etc.) as needed

dow not exit;
  now = %char(%time(): *hms);
  clearDisplayData();
  if active;
    buildSaleList();
    addTotals();
  endif;
   //msg = *in(81) + ' ' + *in(82) + ' ' + *in(83) + ' ' + *in84;
  exfmt xterminal;

  select;
    when pay;
      closeSale();

    when exit;
      leave;

    when newxAction and not active;
      crtNewXaction();

    when itemVoid;
      if e_itemid <> *blanks;
        addItem(VOID);
        itemVoid = *off;
      endif;

    when voidItem;
      msg = 'Enter Item Number to void...';
      itemVoid = *on;

    when cancel;
      msg = 'Transaction voided....';
      xnum = '';
      active = *off;

    when active;
      if e_itemid <> *blanks;
        addItem(ADD);
      endif;

    other;
      msg = 'You must first create a new sale - F6';
      e_itemid = '';
  endsl;
enddo;

*inlr = *on;
return;

// -------------------------------------------------------------
//  Adds Item to  xDetail
// -------------------------------------------------------------
dcl-proc addItem;
  dcl-pi *n;
    mode   char(8) value;
  end-pi;

  dcl-s discount packed(7 : 2);
  dcl-s itemDisc Packed(2 : 0);
  dcl-s stkNum   like(e_itemid) inz('     ');

  exec sql select itemdesc, itemprice, itemdisc
       into :xItemdesc, :gross_amt, :ItemDisc
       from instock01
       where itemnumber = :e_itemid;

  if sqlstate = SQL_FOUND;
    xLineNum += 1;
    if itemDisc > 0;
      discount = %dech(gross_amt * (itemDisc / 100) : 7 : 2);
    endif;

    if mode = VOID;
      gross_amt = gross_amt * -1;
      discount = discount * -1;
    endif;

    exec sql
      INSERT INTO XDetail ( xnum, xlinenum , xitemnum, xitemdesc, gross_amt, disc_amt )
      VALUES ( :xnum, :xLineNum, :e_itemid, :xItemdesc, :gross_amt, :discount );

    if sqlstate = SQL_FOUND;
      if mode = ADD;
        msg = 'Item ' + e_itemID + ' added to sale...';
      else;
        msg = 'Item ' + e_itemID + ' voided...';
      endif;
      e_itemId = '';
    else;
      msg = 'Failed to ' + mode + ' item - SQLERROR Code: ' + sqlstate;
    endif;
  else;
    promptStkFields(stkNum);
    e_itemid = stkNum;
    addItem(mode);
  endif;

end-proc;

// -------------------------------------------------------------
//  Adds Totals to display
// -------------------------------------------------------------
dcl-proc addTotals;
  dcl-s i int(10);

  t_subtotal = 0.00;
  t_discount = 0;
  t_tax = 0.00;
  t_total = 0.00;

  for i = 1 to LIST_SIZE;
    t_subtotal += itemPrices(i);
    t_discount += itemdiscs(i);   //itemdiscs(i) should be negative value here
  endfor;

  t_tax = t_subtotal * TAX_RATE;
  t_total = t_subtotal + t_discount + t_tax;

end-proc;

// -------------------------------------------------------------
//  Populates the sale items fields
// -------------------------------------------------------------
dcl-proc buildSaleList;
  dcl-s count  like(xLineNum);
  dcl-s pos    like(xLineNum);
  dcl-s i      uns(5);

  exec sql select count(xnum) into :count
                  from xDetail where (xNum = :xnum);

  if sqlstate = SQL_FOUND;
    pos = count - LIST_SIZE + 1;
    if pos < 1;
      pos = 1;
    endif;
  endif;

  // Start reading from the database pointer position
  setll (xnum:pos) XREC;
  reade xnum XREC; // Read by key (xnum) only to fetch sequential items

  i = 1; // Start array insertion at the first element index slot

  dow not %eof(xdetail) and i <= LIST_SIZE;
    itemLines(i) = xlinenum;
    itemNums(i)  = xitemnum;
    itemDescs(i) = xitemdesc;
    itemQtys(i)  = xitemqty;
    itemPrices(i) = gross_amt;
    itemDiscs(i) = disc_amt * -1;

    if gross_amt < 0;
      dspVoids(i) = VOID;
    endif;

    i += 1;
    pos += 1;
    reade xnum XREC;
  enddo;

end-proc;

// -------------------------------------------------------------
//  Clears display Data
// -------------------------------------------------------------
dcl-proc clearDisplayData;

  dcl-s i int(10);

  for i = 1 to LIST_SIZE;
    itemLines(i) = 0;
    itemNums(i) =  '';
    itemDescs(i) = '';
    itemQtys(i) = 0;
    itemPrices(i) = 0.00;
    dspVoids(i) = '';
    itemDiscs(i) = 0.00;
  endfor;

  t_subtotal = 0.00;
  t_tax = 0.00;
  t_total = 0.00;

end-proc;
// -------------------------------------------------------------
//  Finalizes the transaction
// -------------------------------------------------------------
dcl-proc closeSale;

  exec sql update xmaster set is_processed = 'Y' where xnum = :xNum;

  if sqlstate = SQL_FOUND;
    in *lock nextTransactionNum;
    evalr nextTransactionNum = %editc(%int(nextTransactionNum) + 1 : 'X');  //Increment
    out nextTransactionNum;
    msg = 'Sale Complete...';
    xnum = '';
    active = *off;
  else;
    msg = 'Failed to close sale... - SQLERROR Code: ' + sqlstate;
  endif;

end-proc;
// -------------------------------------------------------------
//  Sets up a new transaction
// -------------------------------------------------------------
dcl-proc crtNewXaction;
  dcl-pi *n;
    // Define input/output parameters here
  end-pi;

  in *lock nextTransactionNum;
  xnum = nextTransactionNum;
  exec sql
    INSERT INTO XMaster (xnum, storenum, xdate, xtime, tax_rate)
    VALUES (:nextTransactionNum, :storenum, :today, :now, :TAX_RATE);

  if sqlstate = SQL_FOUND;
    active = *on;
    evalr nextTransactionNum = %editc(%int(nextTransactionNum) + 1 : 'X');  //Increment
    msg = 'Transaction in process...';
  else;
    msg = 'Failed to create sale SQLSTATE: ' + SQLSTATE;
  endif;

  out nextTransactionNum;
  t_subtotal = 0.00;
  t_tax = 0.00;
  t_total = 0.00;

end-proc;


