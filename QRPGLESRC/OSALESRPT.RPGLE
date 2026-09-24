      ****************************************************************
      *      ________________                                        *
      *      |Vintage        |    R.P. Vintage LLC.                  *
      *      |   Software    |    4777 W. Daybreak Rim way.          *
      *      |      Solutions|    South Jordan, UT 84009             *
      *      |_______________|                                       *
      *                                                              *
      *            Program Name:  OSalesRPT                          *
      *                                                              *
      *     Program Description:  Options: Sales by date or          *
      *                                transaction                   *
      *                                                              *
      *              Programmer:  Brian Lannoye                      *
      *              Date Coded:  09/05/2026                         *
      *                 Request:  Avocation -  Stock 'N Trade app    *
      *                                                              *
      * ----------------------  Modifications  --------------------- *
      *                                                              *
      *   Date    Pgmr  Req     Description                          *
      ****************************************************************
**free
ctl-opt dftactgrp(*no) actgrp(*caller);

dcl-pr runReport extpgm('SALESRPT');
  *n       ind;
  *n       ind;
  *n       char(9);
  *n       char(10);
  *n       char(10);
  *n       char(10);
end-pr;

dcl-f dsalesrpt workstn indds(dspfInds);

dcl-ds dspfInds len(99);
  summary      ind pos(02);
  exit         ind pos(03);
  detail       ind pos(05);
  nonProc      ind pos(07);
end-ds;

//--------------------------------------------------------
//          /*       Main Processing       */
//--------------------------------------------------------
pStore = '8271971';
today = %char(%date(): *usa);

dow (1 = 1);
  now = %char(%time(): *hms);
  exfmt salopt;


  if (exit = *on);
    leave;
  endif;
  if (summary = *on);
    leave;
  endif;
  if (detail = *on);
    leave;
  endif;
  if (nonProc = *on);
    leave;
  endif;
enddo;

if not exit;
  runReport(summary : nonProc : dXNum : dXDate : dFrDate : dToDate);
endif;

*inlr = *on;
return;

