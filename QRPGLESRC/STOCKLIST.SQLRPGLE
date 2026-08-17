      ****************************************************************
      *      ________________                                        *
      *      |Vintage        |    R.P. Vintage LLC.                  *
      *      |   Software    |    4777 W. Daybreak Rim way.          *
      *      |      Solutions|    South Jordan, UT 84009             *
      *      |_______________|                                       *
      *                                                              *
      *            Program Name:  StockList                          *
      *                                                              *
      *     Program Description:  Report: Stock Listing              *
      *                                for Stock'nTrade  App         *
      *                                                              *
      *              Programmer:  Brian Lannoye                      *
      *              Date Coded:  08/12/2026                         *
      *                 Request:  Avocation -  Stock 'N Trade app    *
      *                                                              *
      * ----------------------  Modifications  --------------------- *
      *                                                              *
      *   Date    Pgmr  Req     Description                          *
      ****************************************************************
**free
ctl-opt dftactgrp(*no) actgrp(*caller);

dcl-f PSTOCKLIST printer oflind(overflow);

dcl-s overflow ind;

exec sql set option commit = *none;
exsr WriteHeader;

exec sql declare c1 cursor for
  select itemnumber, itemdesc, itemcost, itemqty, ordthresh
  from InStock
  order by ItemNumber;

exec sql close c1;
exec sql open c1;
dow (1 = 1);
  exec sql fetch next from c1 into :PITEM, :PDESC, :PCOST, :PQTY, :PTHRESH;


  if (SQLSTATE = '02000' or SQLCODE < 0);
    leave;
  endif;

  if (overflow);
    exsr WriteHeader;
  endif;

  write DETREC;
enddo;

exec sql close c1;
write FTRREC;
*inlr = *on;
return;


//================================================================*
// SUBROUTINE: Write Header & Reset Overflow Indicator
//================================================================*
begsr WriteHeader;
  write HDRREC;
  overflow = *off;
endsr;
