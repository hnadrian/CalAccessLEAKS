-- Active: 1718224497967@@devdb.chzg5zpujwmo.us-west-2.rds.amazonaws.com@3306@HLProd
DROP PROCEDURE populate_lobbyists;
CREATE DEFINER=`HLobbyists1`@`%` PROCEDURE `populate_lobbyists`()
BEGIN
    DECLARE finished INT DEFAULT 0;
    DECLARE v_filer_id VARCHAR(200);
    DECLARE v_filer_id_new INT;
    DECLARE v_filer_id_old VARCHAR(255);
    DECLARE v_first_name VARCHAR(255);
    DECLARE v_last_name VARCHAR(255);
    DECLARE v_id INT;
    DECLARE v_ethics_date VARCHAR(255);
    DECLARE v_ethics_course BOOLEAN;

    -- FILERNAME Cursor
    DECLARE filername_cursor CURSOR FOR 
    SELECT DISTINCT FILER_ID, NAML, NAMF, ETHICS_DATE
    FROM CalAccess.`FILERNAME_CD` LEFT JOIN CalAccess.`FILER_ETHICS_CLASS_CD` USING (FILER_ID)
    WHERE FILER_TYPE='Lobbyist';

    -- CVR_REGISTRATION Cursor
    DECLARE registration_cursor CURSOR FOR 
    SELECT DISTINCT FILER_ID, FILER_NAML, FILER_NAMF, ETHICS_DATE
    FROM CalAccess.`CVR_REGISTRATION_CD` LEFT JOIN CalAccess.`FILER_ETHICS_CLASS_CD` USING(FILER_ID)
    WHERE ENTITY_CD='LBY';

    -- LOBBY_DISCLOSURE Cursor
    DECLARE lobby_disclosure_cursor CURSOR FOR
    SELECT DISTINCT FILER_ID, FILER_NAML, FILER_NAMF, ETHICS_DATE
    FROM CalAccess.`CVR_LOBBY_DISCLOSURE_CD` LEFT JOIN CalAccess.`FILER_ETHICS_CLASS_CD` USING(FILER_ID)
    WHERE ENTITY_CD='LBY';

    -- Declare continue handler
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
    
    -- Read from FILERNAME
    OPEN filername_cursor;
    filername_loop: LOOP
        FETCH filername_cursor INTO v_filer_id, v_last_name, v_first_name, v_ethics_date;
        IF finished THEN
            LEAVE filername_loop;
        END IF;

        -- Convert FILER_ID to SIGNED
        SET v_filer_id_new = CONVERT(v_filer_id, SIGNED);
        -- Check if conversion is successful
        IF v_filer_id_new = 0 THEN
            SET v_filer_id_old = v_filer_id;
            SET v_filer_id_new = NULL;
        END IF;

        -- Insert individual if not exists
        INSERT IGNORE INTO HLProd.individuals (filer_id_new, first_name, last_name)
        VALUES (v_filer_id_new, v_first_name, v_last_name);

        -- Get the individual id
        SELECT id INTO v_id FROM `HLProd`.individuals WHERE filer_id_new = v_filer_id;
        -- Debug: Check if individual id was found
        IF v_id IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Individual ID not found';
        END IF;

        -- Insert individual into candidates if not exists
        SET v_ethics_course = FALSE;
        IF v_ethics_date IS NOT NULL THEN
            SET v_ethics_course = TRUE;
            SET v_ethics_date = STR_TO_DATE(v_ethics_date, '%c/%e/%Y %r');
        END IF;

        INSERT INTO HLProd.lobbyists (individual_id, ethics_course_completed, last_ethics_course) 
        VALUES (v_id, v_ethics_course, v_ethics_date)
        ON DUPLICATE KEY UPDATE
            last_ethics_course = CASE
                WHEN VALUES(last_ethics_course) > last_ethics_course THEN VALUES(last_ethics_course)
                ELSE last_ethics_course
            END;
    END LOOP;
    CLOSE filername_cursor;

    SET finished = 1;

    -- Read from CVR_REGISTRATION
    OPEN registration_cursor;
    registration_loop: LOOP
        FETCH registration_cursor INTO v_filer_id, v_last_name, v_first_name, v_ethics_date;
        IF finished THEN
            LEAVE registration_loop;
        END IF;

        -- Convert FILER_ID to SIGNED
        SET v_filer_id_new = CONVERT(v_filer_id, SIGNED);
        -- Check if conversion is successful
        IF v_filer_id_new = 0 THEN
            SET v_filer_id_old = v_filer_id;
            SET v_filer_id_new = NULL;
        END IF;

        -- Insert individual if not exists
        INSERT IGNORE INTO HLProd.individuals (filer_id_new, first_name, last_name)
        VALUES (v_filer_id_new, v_first_name, v_last_name);

        -- Get the individual id
        SELECT id INTO v_id FROM `HLProd`.individuals WHERE filer_id_new = v_filer_id;
        -- Debug: Check if individual id was found
        IF v_id IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Individual ID not found';
        END IF;

        -- Insert individual into candidates if not exists
        SET v_ethics_course = FALSE;
        IF v_ethics_date IS NOT NULL THEN
            SET v_ethics_course = TRUE;
            SET v_ethics_date = STR_TO_DATE(v_ethics_date, '%c/%e/%Y %r');
        END IF;

        INSERT INTO HLProd.lobbyists (individual_id, ethics_course_completed, last_ethics_course) 
        VALUES (v_id, v_ethics_course, v_ethics_date)
        ON DUPLICATE KEY UPDATE
            last_ethics_course = CASE
                WHEN VALUES(last_ethics_course) > last_ethics_course THEN VALUES(last_ethics_course)
                ELSE last_ethics_course
            END;

        INSERT IGNORE INTO HLProd.lobbyists (individual_id, ethics_course_completed) VALUES (v_id, v_ethics_course);
    END LOOP;
    CLOSE registration_cursor;

    SET finished = 1;

    -- Read from CVR_LOBBY_DISCLOSURE
    OPEN lobby_disclosure_cursor;
    lobby_disclosure_loop: LOOP
        FETCH lobby_disclosure_cursor INTO v_filer_id, v_last_name, v_first_name, v_ethics_date;
        IF finished THEN
            LEAVE lobby_disclosure_loop;
        END IF;

        -- Convert FILER_ID to SIGNED
        SET v_filer_id_new = CONVERT(v_filer_id, SIGNED);
        -- Check if conversion is successful
        IF v_filer_id_new = 0 THEN
            SET v_filer_id_old = v_filer_id;
            SET v_filer_id_new = NULL;
        END IF;

        -- Insert individual if not exists
        INSERT IGNORE INTO HLProd.individuals (filer_id_new, first_name, last_name)
        VALUES (v_filer_id_new, v_first_name, v_last_name);

        -- Get the individual id
        SELECT id INTO v_id FROM `HLProd`.individuals WHERE filer_id_new = v_filer_id;
        -- Debug: Check if individual id was found
        IF v_id IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Individual ID not found';
        END IF;

        -- Insert individual into candidates if not exists
        SET v_ethics_course = FALSE;
        IF v_ethics_date IS NOT NULL THEN
            SET v_ethics_course = TRUE;
            SET v_ethics_date = STR_TO_DATE(v_ethics_date, '%c/%e/%Y %r');
        END IF;

        INSERT INTO HLProd.lobbyists (individual_id, ethics_course_completed, last_ethics_course) 
        VALUES (v_id, v_ethics_course, v_ethics_date)
        ON DUPLICATE KEY UPDATE
            last_ethics_course = CASE
                WHEN VALUES(last_ethics_course) > last_ethics_course THEN VALUES(last_ethics_course)
                ELSE last_ethics_course
            END;

        INSERT IGNORE INTO HLProd.lobbyists (individual_id, ethics_course_completed) VALUES (v_id, v_ethics_course);
    END LOOP;
    CLOSE lobby_disclosure_cursor;
END