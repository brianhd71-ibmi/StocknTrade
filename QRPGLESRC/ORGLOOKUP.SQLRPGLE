      ****************************************************************
      *      ________________                                        *
      *      |               |    RP Vintage Technologies            *
      *      |  RP Vintage   |    4777 W. Daybreak Rim way.          *
      *      |     Inc       |    South Jordan, UT 84009             *
      *      |_______________|                                       *
      *                                                              *
      *            Program Name:  ORGLOOKUP                          *
      *                                                              *
      *     Program Description:  Lookup: Retrieve Origin            *
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

dcl-pr main extpgm('ORGLOOKUP');
  *n       char(4);
  *n       char(25);
end-pr;

dcl-pi main;
  inOrgNum char(4);
  inOrg    char(25);
end-pi;

// File Declarations
dcl-f dorglookup workstn indds(dspfInds) sfile(LKPREC:rrn);

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
       exec sql declare org1 cursor
            for select orgnumber, origin
                  from orglookup
              order by origin
                for read only;

       exec sql declare org2 cursor
            for select orgnumber, origin
                  from orglookup
                 where origin like '%' || rtrim(:srchOrg) || '%'
              order by origin
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

  if srchorg <> *blanks;
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
  if srchorg <> *blanks;
    exec sql close org2;
    exec sql open org2;
    exec sql fetch org2 into :lkpnum, :lkpOrg;
    dow SQLSTATE <> '02000' and %subst(SQLSTATE:1:2) < '03';
      lkpopt = ' ';
      rrn += 1;

      write LKPREC;
      exec sql fetch org2 into :lkpnum, :lkpOrg;
    enddo;
    exec sql close org2;
  else;
    exec sql close org1;
    exec sql open org1;
    exec sql fetch org1 into :lkpnum, :lkpOrg;
    dow SQLSTATE <> '02000' and %subst(SQLSTATE:1:2) < '03';
      lkpopt = ' ';
      rrn += 1;

      write LKPREC;
      exec sql fetch org1 into :lkpnum, :lkpOrg;
    enddo;
    exec sql close org1;
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
        inOrgNum = lkpnum;
        inOrg = lkporg;
        cancel = *on;
    endsl;
    // Reset option column and update row status buffer
    lkpopt = ' ';
    update LKPREC;

    readc LKPREC;
  enddo;

end-proc;

