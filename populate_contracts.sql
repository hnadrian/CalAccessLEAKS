-- Active: 1718224497967@@devdb.chzg5zpujwmo.us-west-2.rds.amazonaws.com@3306@HLProd
DROP PROCEDURE populate_contracts;
CREATE DEFINER=`HLobbyists1`@`%` PROCEDURE `populate_contracts`()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE org_id INT;
    DECLARE firm_id INT;
    DECLARE org_name VARCHAR(200);
    DECLARE firm VARCHAR(200);
    DECLARE start_date VARCHAR(200);
    DECLARE end_date VARCHAR(200);
    DECLARE dur INT;
    DECLARE star DATE;
    DECLARE billprefix VARCHAR(2);
    DECLARE billnumber Int;
    DECLARE lby_activity VARCHAR(200); 
    DECLARE bill_code VARCHAR(255);
    DECLARE debug_msg VARCHAR(255); -- Variable for debug messages

    DECLARE cur CURSOR FOR 
            SELECT FIRM_NAME, EMPLOYER_NAME, RPT_START, RPT_END, LBY_ACTVTY
            FROM CalAccess.LOBBYIST_FIRM_EMPLOYER1_CD;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;

    read_loop: LOOP

        FETCH cur INTO firm, org_name, start_date, end_date, lby_activity;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Find organization_id based on EMPLOYER_NAME
        SELECT id INTO org_id FROM HLProd.organizations WHERE name = org_name limit 1;

        -- Find lobbying_firm_id based on FIRM_NAME
        SELECT id INTO firm_id FROM HLProd.lobbying_firms WHERE name = firm limit 1;

        SET dur = DATEDIFF(STR_TO_DATE(end_date, '%m/%d/%Y'), STR_TO_DATE(start_date, '%m/%d/%Y'));

        SET star = STR_TO_DATE(start_date, '%m/%d/%Y');


        SET debug_msg = CONCAT('Processing row: org_id=', org_id, ', org_name=', org_name, ', firm_id=', firm_id, ', firm_name=', firm, ', start_date=', star, ', duration=', dur);
        SELECT debug_msg;

        INSERT INTO HLProd.lobbying_contracts (organization_id, lobbying_firm_id, contract_start_date, duration)
        VALUES (org_id, firm_id, star, dur);

/*
        WHILE LENGTH(lby_activity) > 0 DO
            -- Find position of next space or end of string
            SET @next_space = LOCATE(' ', lby_activity);
            
            IF @next_space = 0 THEN
                SET billprefix = lby_activity; -- Last segment of lby_activity
                SET lby_activity = ''; -- Clear lby_activity to exit loop
            ELSE
                SET billprefix = SUBSTRING(lby_activity, 1, @next_space - 1); -- Extract first word (prefix)
                SET lby_activity = TRIM(SUBSTRING(lby_activity, @next_space + 1)); -- Remove first word and trim
            END IF;
            -- Check if there's another word available
            IF LENGTH(lby_activity) > 0 THEN
                -- Extract second word (number)
                SET @next_space = LOCATE(' ', lby_activity);
                IF @next_space = 0 THEN
                    SET billnumber = lby_activity; -- Last segment of lby_activity
                    SET lby_activity = ''; -- Clear lby_activity to exit loop
                ELSE
                    SET billnumber = SUBSTRING(lby_activity, 1, @next_space - 1); -- Extract second word (number)
                    SET lby_activity = TRIM(SUBSTRING(lby_activity, @next_space + 1)); -- Remove second word and trim
                END IF;
                -- Debugging: Print extracted prefix and number
                select billprefix;
                -- Find corresponding bill_code in bills table
                SELECT code INTO bill_code
                FROM HLProd.bills
                WHERE billprefix = billprefix
                AND billnumber = billnumber
                limit 1;
                -- Debugging: Print found bill_code
                -- Insert into bill_influence if found
                    INSERT IGNORE INTO HLProd.bill_influence (organization_id, lobbying_firm_id, contract_start_date, bill_code)
                    VALUES (org_id, firm_id, star, bill_code);
                    -- Debugging: Print message if no bill_code found
                END IF;
        END WHILE;
*/
    END LOOP;

    CLOSE cur;
END