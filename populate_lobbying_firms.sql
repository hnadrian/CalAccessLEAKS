-- Active: 1718224497967@@devdb.chzg5zpujwmo.us-west-2.rds.amazonaws.com@3306@HLProd
DROP PROCEDURE populate_lobbying_firms;
CREATE DEFINER=`HLobbyists1`@`%` PROCEDURE `populate_lobbying_firms`()
BEGIN
    DECLARE finished INT DEFAULT 0;
    DECLARE v_filer_id VARCHAR(200);
    DECLARE v_filer_id_new INT;
    DECLARE v_filer_id_old VARCHAR(200);
    DECLARE v_firm_name VARCHAR(255);
    
    -- FILERNAME Cursor
    DECLARE filername_cursor CURSOR FOR 
    SELECT DISTINCT FILER_ID, NAML
    FROM CalAccess.`FILERNAME_CD`
    WHERE FILER_TYPE='Firm';

    -- CVR_REGISTRATION Cursor
    DECLARE registration_cursor CURSOR FOR 
    SELECT DISTINCT FILER_ID, FILER_NAML
    FROM CalAccess.`CVR_REGISTRATION_CD`
    WHERE ENTITY_CD='FRM';

    -- Declare continue handler
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;

    OPEN filername_cursor;
    filername_loop: LOOP
        FETCH filername_cursor INTO v_filer_id, v_firm_name;
        IF finished THEN
            LEAVE filername_loop;
        END IF;

        -- Convert FILER_ID to SIGNED
        SET v_filer_id_new = CONVERT(v_filer_id, SIGNED);
        -- Check if conversion is successful
        IF v_filer_id_new IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FILER_ID conversion failed';
        END IF;

        INSERT IGNORE INTO HLProd.lobbying_firms (filer_id_new, name)
        VALUES (v_filer_id_new, v_firm_name);
    END LOOP;
    CLOSE filername_cursor;

    SET finished = 0;

    OPEN registration_cursor;
    registration_loop: LOOP
        FETCH registration_cursor INTO v_filer_id, v_firm_name;
        IF finished THEN
            LEAVE registration_loop;
        END IF;

        SET v_filer_id_old = NULL;
        -- Convert FILER_ID to SIGNED
        SET v_filer_id_new = CONVERT(v_filer_id, SIGNED);
        -- Check if conversion is successful
        IF v_filer_id_new = 0 THEN
            -- Assume old filer id
            SET v_filer_id_old = v_filer_id;
            SET v_filer_id_new = NULL;
        END IF;

        INSERT IGNORE INTO HLProd.lobbying_firms (filer_id_new, filer_id_old, name)
        VALUES (v_filer_id_new, v_filer_id_old, v_firm_name);
    END LOOP;
    CLOSE registration_cursor;
    
END