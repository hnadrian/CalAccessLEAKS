-- Active: 1718224497967@@devdb.chzg5zpujwmo.us-west-2.rds.amazonaws.com@3306@HLProd
DROP PROCEDURE populate_bills;
CREATE DEFINER=`HLobbyists1`@`%` PROCEDURE `populate_bills`()
BEGIN
    -- Insert/copy data from DDDB2016Aug.bill to HLProd.bills
    INSERT INTO HLProd.bills (code, session_year, bill_prefix, bill_number)
    SELECT bid, sessionYear, type, number
    FROM DDDB2016Aug.Bill
    ON DUPLICATE KEY UPDATE 
        session_year = VALUES(session_year), 
        bill_prefix = VALUES(bill_prefix), 
        bill_number = VALUES(bill_number);
END