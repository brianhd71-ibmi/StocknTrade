      ****************************************************************
      *      ________________                                        *
      *      |Vintage        |    R.P. Vintage SS                    *
      *      |   Software    |    4777 W. Daybreak Rim way.          *
      *      |      Solutions|    South Jordan, UT 84009             *
      *      |_______________|                                       *
      *                                                              *
      *                                                              *
      *            Program Name:  CATLOOKUP                          *
      *                                                              *
      *     Program Description:  Lookup: Retrieve Category          *
      *                           for Stock'N Trade App              *
      *                                                              *
      *              Programmer:  Brian Lannoye                      *
      *              Date Coded:  07/29/2026                         *
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

dcl-pr main extpgm('CATLOOKUP');
  *n       char(4);
  *n       char(25);
end-pr;

dcl-pi main;
  inCatNum char(4);
  inCat    char(25);
end-pi;

// File Declarations
dcl-f dcatlookup workstn indds(dspfInds) sfile(LKPREC:rrn);

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
dow not cancel;
  initSubfile();
  //write LKPFOOTER;
  exfmt LKPCTL;

  if cancel;
    leave;
  endif;

  // Process any action options or search requests
  if sfldsp;
    ProcessSubfileSelections();
  endif;

  if srchcat <> *blanks;
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
  if srchcat <> *blanks;
    exec sql close cat2;
    exec sql open cat2;
    exec sql fetch cat2 into :lkpnum, :lkpcat;
    dow SQLSTATE <> '02000' and %subst(SQLSTATE:1:2) < '03';
      lkpopt = ' ';
      rrn += 1;

      write LKPREC;
      exec sql fetch cat2 into :lkpnum, :lkpcat;
    enddo;
    exec sql close cat2;
  else;
    exec sql close cat1;
    exec sql open cat1;
    exec sql fetch cat1 into :lkpnum, :lkpcat;
    dow SQLSTATE <> '02000' and %subst(SQLSTATE:1:2) < '03';
      lkpopt = ' ';
      rrn += 1;

      write LKPREC;
      exec sql fetch cat1 into :lkpnum, :lkpcat;
    enddo;
    exec sql close cat1;
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
        inCatNum = lkpnum;
        inCat = lkpcat;
        cancel = *on;
    endsl;
    // Reset option column and update row status buffer
    lkpopt = ' ';
    update LKPREC;

    readc LKPREC;
  enddo;

end-proc;

