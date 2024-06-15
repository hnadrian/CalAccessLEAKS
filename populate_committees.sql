-- Active: 1718224497967@@devdb.chzg5zpujwmo.us-west-2.rds.amazonaws.com@3306@HLProd
DROP PROCEDURE populate_committees;
CREATE DEFINER=`HLobbyists1`@`%` PROCEDURE `populate_committees`()
BEGIN
    INSERT INTO committees (filer_id_new, amendment_id, name, address)
    SELECT 
        FILER_ID AS filer_id_new,
        AMEND_ID, 
        FILER_NAML,
        CONCAT_WS(", ", CITY, ST, ZIP4) AS address
    FROM 
        CalAccess.CVR_SO_CD
    ON DUPLICATE KEY UPDATE
        amendment_id = VALUES(amendment_id),
        name = VALUES(name),
        address = VALUES(address);

    INSERT INTO committees (filer_id_new, amendment_id, name, address)
    SELECT
        RECIP_ID AS filer_id_new,
        AMEND_ID,
        RECIP_NamL AS name,
        CONCAT_WS(", ", RECIP_CITY, RECIP_ST, RECIP_ZIP4) AS address
    FROM 
        CalAccess.LCCM_CD
    ON DUPLICATE KEY UPDATE
        amendment_id = VALUES(amendment_id),
        name = VALUES(name),
        address = VALUES(address);

    INSERT INTO committees (filer_id_new, amendment_id, name, address)
    SELECT
        FILER_ID AS filer_id_new,
        AMEND_ID,
        FILER_NAML AS name,
        CONCAT_WS(", ", FILER_CITY, FILER_ST, FILER_ZIP4) AS address
    FROM 
        CalAccess.CVR_CAMPAIGN_DISCLOSURE_CD
    ON DUPLICATE KEY UPDATE
        amendment_id = VALUES(amendment_id),
        name = VALUES(name),
        address = VALUES(address);
END