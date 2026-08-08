      ****************************************************************
      *      ________________                                        *
      *      |Vintage        |    R.P. Vintage LLC.                  *
      *      |   Software    |    4777 W. Daybreak Rim way.          *
      *      |      Solutions|    South Jordan, UT 84009             *
      *      |_______________|                                       *
      *                                                              *
      *            Program Name:  ITEMCAT                            *
      *                                                              *
      *     Program Description:  Utility: Maintain Category         *
      *                           for Stock'N Trade App              *
      *                                                              *
      *              Programmer:  Brian Lannoye                      *
      *              Date Coded:  07/27/2026                         *
      *             Description:  Controller for Inventory           *
      *                           Category Lookup Window (dItemCat)  *
      * ----------------------  Modifications  --------------------- *
      *                                                              *
      *   Date    Pgmr  Req     Description                          *
      ****************************************************************
**free
// Control Options
ctl-opt option(*srcstmt : *nodebugio) dftactgrp(*no) actgrp(*new);
ctl-opt cvtopt(*VARCHAR);

// File Declarations
dcl-f dItemCat workstn indds(dspfInds) sfile(SFLREC:rrn);

dcl-ds dspfInds len(99);
  exit         ind pos(03);
  add          ind pos(06);
  cancel       ind pos(12);
  sflDisplay   ind pos(31);
  sflDspCtl   ind pos(32);
  sflClear     ind pos(33);
  sflEnd       ind pos(34);
end-ds;

// Standalone Variables
dcl-s rrn    zoned(4:0);
dcl-s nextCatNum  char(4) dtaara('BRIANHD711/NEXTCAT');

exec sql SET OPTION COMMIT = *NONE;
//-------------------------------------------------------
//          /*         SQL Select            */
//-------------------------------------------------------
       exec sql declare cat1 cursor
            for select catnumber, category
                  from catlookup
              order by category
                for read only;

       exec sql declare cat2 cursor
            for select catnumber, category
                  from catlookup
                 where category like '%' || rtrim(:srchcat) || '%'
              order by category
                for read only;
//--------------------------------------------------------
//          /*       Main Processing       */
//--------------------------------------------------------
today = %char(%date(): *usa);

dow not exit;
  now = %char(%time(): *hms);
  initSubfile();

  write FOOTER;
  EXFMT SFLCTL;

  if exit;
    leave;
  endif;

  // Process any action options or search requests
  if sflDisplay;
    ProcessSubfileSelections();
  endif;
  if add;
    addItem();
  endif;

  if srchcat <> *blanks;
    InitSubfile();
  endif;
enddo;

*inlr = *on;
return;

// =================================================================*
// PROCEDURE: Add item to category lookup
// =================================================================*
dcl-proc AddItem;
  dcl-pi *n;
    // Add any parameters here if you want to pass data in/out
  end-pi;

  w1catdesc = '';

  in *lock nextCatNum;
  w1catnum = nextCatNum;

  exfmt catwin01;

  if not cancel and w1catdesc <> *blanks;
    exec sql
      insert into CatLookup (catnumber, category)
      values(:w1catnum, :w1catdesc);

    if sqlstate = '00000';
      evalr nextCatNum = %editc(%int(nextCatNum) + 1 : 'X');
    else;
      msg = 'New Category failed to execute... SQLSTATE: ' + sqlstate;
    endif;
  endif;

  out nextCatNum;
end-proc;

// =================================================================*
// Procedure: Initialize, Clear, and Load the Subfile List
// =================================================================*
dcl-proc InitSubfile;

  // 1. Clear the Subfile
  sflDisplay = *off;
  sflDspCtl = *off;
  sflEnd     = *off;
  sflClear   = *on;
  write SFLCTL;

  sflClear = *off;
  rrn = 0;

  // 2. Query/Read from Database Table
  if srchcat <> *blanks;
    exec sql close cat2;
    exec sql open cat2;
    exec sql fetch cat2 into :sflnum, :sflcat;
    dow SQLSTATE <> '02000' and %subst(SQLSTATE:1:2) < '03';
      sflopt = ' ';
      rrn += 1;

      write SFLREC;
      exec sql fetch cat2 into :sflnum, :sflcat;
    enddo;
    exec sql close cat2;
  else;
    exec sql close cat1;
    exec sql open cat1;
    exec sql fetch cat1 into :sflnum, :sflcat;
    dow SQLSTATE <> '02000' and %subst(SQLSTATE:1:2) < '03';
      sflopt = ' ';
      rrn += 1;

      write SFLREC;
      exec sql fetch cat1 into :sflnum, :sflcat;
    enddo;
    exec sql close cat1;
  endif;

  // 4. Reset indicators based on whether items were found
  if rrn > 0;
    sflDisplay = *on;
    sflDspCtl = *on;
    sflEnd     = *on;
  else;
    sflDspCtl = *on; // Keep header visible even if grid empty
  endif;

end-proc;

// =================================================================*
// PROCEDURE: Read Modified Rows to Route Actions into the Form
// =================================================================*
dcl-proc ProcessSubfileSelections;
  dcl-pi *n;
  end-pi;

  // Read next row changed by user entry
  readc SFLREC;

  dow not %eof;
    select;
      when sflopt = '2';
        exec sql
          select catnumber, category
            into :w1catnum, :w1catdesc
            from catlookup
           where catnumber = :sflnum;

        exfmt catwin01;


        if cancel;
          leave;
        endif;

        exec sql
          update catlookup
             set category = :w1catdesc
           where catnumber = :w1catnum;

        if sqlstate = '02000' or %subst(sqlstate:1:2) >= '03';
          msg = 'Update for category ' + %trim(w1catnum) + ' failed... SQLSTATE: ' + sqlstate;
        endif;
    endsl;

    // Reset option column and update row status buffer
    sflopt = ' ';
    update SFLREC;

    readc SFLREC;
  enddo;

end-proc;

