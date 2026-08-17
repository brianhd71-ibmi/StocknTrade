CREATE TABLE xmaster (
    xnum char(9) NOT NULL,
    storenum VARCHAR(9) NOT NULL,                       -- Constrained to 9 characters
    xdate DATE NOT NULL DEFAULT CURRENT_DATE,
    xtime TIME NOT NULL DEFAULT CURRENT_TIME,
    transaction_type VARCHAR(10) NOT NULL DEFAULT 'SALE',
    tax_rate NUMERIC(3, 2) NOT NULL DEFAULT 0.00,
    payment_method VARCHAR(20) NOT NULL DEFAULT 'CREDIT', -- e.g., 'CASH', 'CREDIT', 'CARD'
    is_processed CHARACTER(1) NOT NULL DEFAULT 'N',
    PRIMARY KEY (xnum)
);


CREATE TABLE xdetail (
    xnum char(9) NOT NULL,
    xlinenum NUMERIC(3, 0) NOT NULL,                    
    xitemnum VARCHAR(5) NOT NULL,                        -- Fixed strictly to 5 characters
    xitemDesc CHAR(45) NOT NULL,                     -- Aligned perfectly to match screen space
    xitemqty SMALLINT NOT NULL DEFAULT 1,               -- Clean integer representation 
    gross_amt NUMERIC(7, 2) NOT NULL DEFAULT 0.00,
    disc_amt NUMERIC(7, 2) NOT NULL DEFAULT 0.00
);
