      ****************************************************************
      *      ________________                                        *
      *      |Vintage        |    R.P. Vintage LLC.                  *
      *      |   Software    |    4777 W. Daybreak Rim way.          *
      *      |      Solutions|    South Jordan, UT 84009             *
      *      |_______________|                                       *
      *                                                              *
      *            Program Name:  STKLOOKUP                          *
      *                                                              *
      *     Program Description:  Lookup: Retrieve Inventory         *
      *                           for Terminal Transactions App      *
      *                                                              *
      *              Programmer:  Brian Lannoye                      *
      *              Date Coded:  08/12/2026                         *
      *                                                              *
      *                                                              *
      * ----------------------  Modifications  --------------------- *
      *                                                              *
      *   Date    Pgmr  Req     Description                          *
      ****************************************************************
**free
// Control Options
ctl-opt option(*srcstmt : *nodebugio) dftactgrp(*no) actgrp(*new);
ctl-opt cvtopt(*VARCHAR);

dcl-pr main extpgm('STKLOOKUP');
  *n       char(5);
end-pr;

dcl-pi main;
  inStkNum char(5);
end-pi;

// File Declarations
dcl-f dstklookup workstn indds(dspfInds) sfile(LKPREC:rrn);

dcl-ds dspfInds len(99);
  cancel       ind pos(12);
  sfldsp       ind pos(31);
  sflDspCtl    ind pos(32);
  sflclr       ind pos(33);
  sflEnd       ind pos(34);
end-ds;

// Standalone Variables
dcl-s rrn    zoned(4:0);

//-------------------------------------------------------
//          /*         SQL Select            */
//-------------------------------------------------------
       exec sql declare stk1 cursor
            for select itemnumber, itemdesc
                  from instock
              order by itemdesc
                for read only;

       exec sql declare stk2 cursor
            for select itemnumber, itemdesc
                  from instock
                 where itemdesc like '%' || rtrim(:srchstk) || '%'
              order by itemdesc
                for read only;
//--------------------------------------------------------
//          /*       Main Processing       */
//--------------------------------------------------------
dow not cancel;
  initSubfile();
  exfmt LKPCTL;

  if cancel;
    leave;
  endif;

  // Process any action options or search requests
  if sfldsp;
    ProcessSubfileSelections();
  endif;

  if srchstk <> *blanks;
    InitSubfile();
  endif;
enddo;

*inlr = *on;
return;

// =================================================================*
// Procedure: Initialize, Clear, and Load the Subfile List
// =================================================================*
dcl-proc InitSubfile;

  // 1. Clear the Subfile
  sfldsp = *off;
  sflDspCtl = *off;
  sflEnd     = *off;
  sflclr   = *on;
  write LKPCTL;

  sflclr = *off;
  rrn = 0;

  // 2. Query/Read from Database Table
  if srchstk <> *blanks;
    exec sql close stk2;
    exec sql open stk2;
    exec sql fetch stk2 into :lkpnum, :lkpstk;
    dow SQLSTATE <> '02000' and %subst(SQLSTATE:1:2) < '03';
      lkpopt = ' ';
      rrn += 1;

      write LKPREC;
      exec sql fetch stk2 into :lkpnum, :lkpstk;
    enddo;
    exec sql close stk2;
  else;
    exec sql close stk1;
    exec sql open stk1;
    exec sql fetch stk1 into :lkpnum, :lkpstk;
    dow SQLSTATE <> '02000' and %subst(SQLSTATE:1:2) < '03';
      lkpopt = ' ';
      rrn += 1;

      write LKPREC;
      exec sql fetch stk1 into :lkpnum, :lkpstk;
    enddo;
    exec sql close stk1;
  endif;

  // 4. Reset indicators based on whether items were found
  if rrn > 0;
    sfldsp = *on;
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
  readc LKPREC;

  dow not %eof;
    select;
      when lkpopt = '1';
        inStkNum = lkpnum;
        cancel = *on;
    endsl;
    // Reset option column and update row status buffer
    lkpopt = ' ';
    update LKPREC;

    readc LKPREC;
  enddo;

end-proc;
