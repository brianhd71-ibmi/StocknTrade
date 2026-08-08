CREATE TABLE InStock (
    ItemNumber CHAR(5) NOT NULL,
    CatNum     VARCHAR(4),
    ItemDesc   VARCHAR(45) NOT NULL,
    ItemCost   DECIMAL(7, 2) NOT NULL,
    ItemPrice  DECIMAL(7, 2) NOT NULL,
    ItemDisc   NUMERIC(2),
    ItemQty    INTEGER NOT NULL DEFAULT 0,
    OrdThresh  INTEGER NOT NULL DEFAULT 0,
    OrigNum    CHAR(4), 
    PRIMARY KEY (ItemNumber)          
);

CREATE TABLE CatLookup (
    CatNumber  CHAR(4) NOT NULL,
    Category   VARCHAR(25) NOT NULL,
    PRIMARY KEY (CatNumber)          
);


CREATE TABLE OrgLookup (
    OrgNumber  CHAR(4) NOT NULL,
    Origin   VARCHAR(25) NOT NULL,
    PRIMARY KEY (OrgNumber)          
);