      ****************************************************************
      *      ________________                                        *
      *      |Vintage        |    R.P. Vintage SS                    *
      *      |   Software    |    4777 W. Daybreak Rim way.          *
      *      |      Solutions|    South Jordan, UT 84009             *
      *      |_______________|                                       *
      *                                                              *
      *            Program Name:  ITEMORG                            *
      *                                                              *
      *     Program Description:  Utility: Maintain Origin           *
      *                           for Stock'N Trade App              *
      *                                                              *
      *              Programmer:  Brian Lannoye                      *
      *              Date Coded:  07/27/2026                         *
      *             Description:  Controller for Inventory           *
      *                           Origin Lookup Window (dItemOrg)    *
      * ----------------------  Modifications  --------------------- *
      *                                                              *
      *   Date    Pgmr  Req     Description                          *
      ****************************************************************
**free
// Control Options
ctl-opt option(*srcstmt : *nodebugio) dftactgrp(*no) actgrp(*new);
ctl-opt cvtopt(*VARCHAR);

// File Declarations
dcl-f dItemOrg workstn indds(dspfInds) sfile(SFLREC:rrn);

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
dcl-s nextOrgNum  char(4) dtaara('BRIANHD711/NEXTORIGIN');

exec sql SET OPTION COMMIT = *NONE;
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
                 where origin like '%' || rtrim(:srchorg) || '%'
              order by origin
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

  if srchorg <> *blanks;
    InitSubfile();
  endif;
enddo;

*inlr = *on;
return;

// =================================================================*
// PROCEDURE: Add item to origin lookup
// =================================================================*
dcl-proc AddItem;
  dcl-pi *n;
    // Add any parameters here if you want to pass data in/out
  end-pi;

  w1Orgdesc = '';

  in *lock nextOrgNum;
  w1Orgnum = nextOrgNum;
  out nextOrgNum;

  exfmt Orgwin01;

  if not cancel and w1Orgdesc <> *blanks;
    exec sql
      insert into OrgLookup (orgnumber, origin)
      values(:w1Orgnum, :w1Orgdesc);

    if sqlstate = '00000';
      in *lock nextOrgNum;
      evalr nextOrgNum = %editc(%int(nextOrgNum) + 1 : 'X');
      out nextOrgNum;
    else;
      msg = 'New Origin failed to execute... SQLSTATE: ' + sqlstate;
    endif;
  endif;

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
  if srchorg <> *blanks;
    exec sql close org2;
    exec sql open org2;
    exec sql fetch org2 into :sflnum, :sflOrg;
    dow SQLSTATE <> '02000' and %subst(SQLSTATE:1:2) < '03';
      sflopt = ' ';
      rrn += 1;

      write SFLREC;
      exec sql fetch org2 into :sflnum, :sflOrg;
    enddo;
    exec sql close org2;
  else;
    exec sql close org1;
    exec sql open org1;
    exec sql fetch org1 into :sflnum, :sflOrg;
    dow SQLSTATE <> '02000' and %subst(SQLSTATE:1:2) < '03';
      sflopt = ' ';
      rrn += 1;

      write SFLREC;
      exec sql fetch org1 into :sflnum, :sflOrg;
    enddo;
    exec sql close org1;
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
          select orgnumber, origin
            into :w1Orgnum, :w1Orgdesc
            from orglookup
           where orgnumber = :sflnum;

        exfmt orgwin01;


        if cancel;
          leave;
        endif;

        exec sql
          update orglookup
             set origin = :w1Orgdesc
           where orgnumber = :w1Orgnum;

        if sqlstate = '02000' or %subst(sqlstate:1:2) >= '03';
          msg = 'Update for origin ' + %trim(w1Orgnum) + ' failed... SQLSTATE: ' + sqlstate;
        endif;
    endsl;

    // Reset option column and update row status buffer
    sflopt = ' ';
    update SFLREC;

    readc SFLREC;
  enddo;

end-proc;

