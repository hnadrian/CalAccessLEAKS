-- Active: 1718224497967@@devdb.chzg5zpujwmo.us-west-2.rds.amazonaws.com@3306@HLProd
DROP PROCEDURE populate_orgs;
CREATE DEFINER=`HLobbyists1`@`%` PROCEDURE `populate_orgs`()
BEGIN
    -- Insert/copy data from DDDB2016Aug.bill to HLProd.bills
    INSERT IGNORE INTO HLProd.organizations (filer_id_old, filer_id_new, name)
    SELECT null, null, name
    FROM DDDB2016Aug.Organizations
    ON DUPLICATE KEY UPDATE 
        name = VALUES(name);
END