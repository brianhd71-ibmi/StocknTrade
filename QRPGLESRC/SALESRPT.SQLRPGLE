      ****************************************************************
      *      ________________                                        *
      *      |Vintage        |    R.P. Vintage LLC.                  *
      *      |   Software    |    4777 W. Daybreak Rim way.          *
      *      |      Solutions|    South Jordan, UT 84009             *
      *      |_______________|                                       *
      *                                                              *
      *            Program Name:  SalesRPT                           *
      *                                                              *
      *     Program Description:  Report: Sales by date or           *
      *                                transaction                   *
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

dcl-pr main extpgm('ORGLOOKUP');
  *n       ind     options(*nopass);
  *n       char(9) options(*nopass);
end-pr;

dcl-pi main;
  scope   ind     options(*nopass);
  inXnum  char(9) options(*nopass);
end-pi;

dcl-f psalesrpt printer oflind(overflow);

dcl-c TAX 0.05;
dcl-s overflow ind;
exec sql set option commit = *none;
//--------------------------------------------------------
//          /*       Main Processing       */
//--------------------------------------------------------
pStore = '8271971';
today = %char(%date(): *usa);
now = %char(%time(): *hms);
exsr WriteHeader;

exec sql declare c1 cursor for
  select xnum, VARCHAR_FORMAT(xdate, 'MM/DD/YYYY'), xtime, tax_rate, payment_method
  from xmaster
  where transaction_type = 'SALE' AND is_processed = 'Y'
  order by xnum;

exec sql close c1;
exec sql open c1;
dow (1 = 1);
  ptotqty = 0;
  psubtotal = 0;
  ptotdisc = 0;
  exec sql fetch next from c1 into :PXNUM, :PXDATE, :PXTIME, :PTAX, :PXPAY;


  if (SQLSTATE = '02000' or SQLCODE < 0);
    leave;
  endif;

  processXTotal(pxnum);
  ptax = (psubtotal - ptotdisc) * TAX;
  ptotal = psubtotal - ptotdisc + ptax;

  if (overflow);
    exsr WriteHeader;
  endif;

  if %parms < 2 or inXnum = *blanks or inXnum = pxnum;
    write detail1;

    if %parms = 0 or scope = *off;
      processXDetail(pxnum);
    endif;
  endif;
enddo;

exec sql close c1;
write FOOTER;
*inlr = *on;
return;


//================================================================*
// SUBROUTINE: Write Header & Reset Overflow Indicator
//================================================================*
begsr WriteHeader;
  write HEADER;
  overflow = *off;
endsr;

//================================================================*
// SUBPROCEDURE: Process transaction details
//================================================================*
dcl-proc processXDetail;
  dcl-pi *n;
    pXNUM char(9);
  end-pi;

  exec sql declare c3 cursor for
    select xlinenum, xitemnum, xitemdesc, xitemqty, gross_amt, disc_amt
    from xdetail
    where xnum = :pXNUM
    order by xlinenum;

  exec sql close c3;
  exec sql open c3;
  exec sql fetch next from c3 into :PLINE, :PITEM, :PDESC, :PQTY, :PPRICE, :PDISC;
  if (SQLSTATE <> '02000' and SQLCODE >= 0);
    write header2;
  endif;
  dow not (SQLSTATE = '02000' or SQLCODE < 0);
    write detail2;
    exec sql fetch next from c3 into :PLINE, :PITEM, :PDESC, :PQTY, :PPRICE, :PDISC;
  enddo;
  exec sql close c3;

  end-proc;

//================================================================*
// SUBPROCEDURE: Process subtotal and discount of each transaction
//================================================================*
dcl-proc processXTotal;
  dcl-pi *n;
    pXNUM char(9);
  end-pi;

  exec sql declare c2 cursor for
    select  xitemqty, gross_amt, disc_amt
    from xdetail
    where xnum = :pXNUM
    order by xlinenum;

  exec sql close c2;
  exec sql open c2;
  dow (1 = 1);
    exec sql fetch next from c2 into :PQTY, :PPRICE, :PDISC;

    if (SQLSTATE = '02000' or SQLCODE < 0);
      leave;
    endif;
    if  pprice >  0;
      ptotqty -= 1;
    else;
      ptotqty += 1;
    endif;
    psubtotal += PPRICE;
    ptotdisc += PDISC;
  enddo;
  exec sql close c2;

  end-proc;
