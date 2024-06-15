-- Active: 1718224497967@@devdb.chzg5zpujwmo.us-west-2.rds.amazonaws.com@3306@HLProd
DROP PROCEDURE populate_committee_expenditures;
CREATE DEFINER=`HLobbyists1`@`%` PROCEDURE `populate_committee_expenditures`()
BEGIN
    DECLARE finished INT DEFAULT 0;
    DECLARE v_filing_id INT;
    DECLARE v_line_item INT;
    DECLARE v_payee_naml VARCHAR(255);
    DECLARE v_payee_namf VARCHAR(255);
    DECLARE v_amount DECIMAL(10, 2);
    DECLARE v_expn_dscr VARCHAR(255);
    DECLARE v_filer_naml VARCHAR(255);
    DECLARE v_filer_namf VARCHAR(255);
    DECLARE v_tres_naml VARCHAR(255);
    DECLARE v_tres_namf VARCHAR(255);
    DECLARE v_cmtte_type VARCHAR(255);
    DECLARE v_cand_naml VARCHAR(255);
    DECLARE v_cand_namf VARCHAR(255);
    DECLARE v_expn_date VARCHAR(255);
    DECLARE v_committee_id INT;
    DECLARE v_individual_id INT;
    DECLARE v_organization_id INT;
    DECLARE v_candidate_id INT;
    DECLARE v_expense_id INT;
    -- Declare cursor for selecting data from the joined query
    DECLARE cur CURSOR FOR
    SELECT CONVERT(EXPN_CD.FILING_ID, UNSIGNED), CONVERT(LINE_ITEM, UNSIGNED), PAYEE_NAML, PAYEE_NAMF, CONVERT(AMOUNT,DECIMAL(10, 2)), EXPN_DSCR, CD.FILER_NAML, CD.FILER_NAMF, CD.TRES_NAML, CD.TRES_NAMF, CD.CMTTE_TYPE, CD.CAND_NAML, CD.CAND_NAMF, `EXPN_CD`.EXPN_DATE
    FROM CalAccess.EXPN_CD
    JOIN CalAccess.CVR_CAMPAIGN_DISCLOSURE_CD AS CD ON CD.FILING_ID = EXPN_CD.FILING_ID;
    -- Declare continue handler
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_filing_id, v_line_item, v_payee_naml, v_payee_namf, v_amount, v_expn_dscr, v_filer_naml, v_filer_namf, v_tres_naml, v_tres_namf, v_cmtte_type, v_cand_naml, v_cand_namf, v_expn_date;
        IF finished THEN
            LEAVE read_loop;
        END IF;
        -- Debug: Print the current line item for tracking
        -- SELECT v_line_item;    
        -- Ensure v_filer_naml is not null or empty
        IF v_filer_naml IS NOT NULL AND v_filer_naml != '' THEN
            -- Find the committee_id from the committees table with trimmed and case-insensitive comparison
            SELECT id INTO v_committee_id
            FROM HLProd.committees
            WHERE name LIKE v_filer_naml
            LIMIT 1;
            -- -- Skip if the committee is not found
            -- IF v_committee_id IS NULL THEN
            --     ITERATE read_loop;
            -- END IF;
            -- Determine if the payee is an individual or organization
            IF v_payee_namf IS NOT NULL AND v_payee_namf != '' THEN
                -- Payee is an individual, find the individual_id
                SELECT id INTO v_individual_id
                FROM HLProd.individuals
                WHERE first_name LIKE v_payee_namf AND last_name LIKE v_payee_naml
                LIMIT 1;
                -- If the individual is not found, insert into the individuals table
                IF v_individual_id IS NULL THEN
                    INSERT INTO HLProd.individuals (first_name, last_name)
                    VALUES (v_payee_namf, v_payee_naml);
                    SET v_individual_id = LAST_INSERT_ID();
                END IF;
                -- Insert into committee_expends_to_individual if individual_id is found
                IF v_individual_id IS NOT NULL THEN
                    INSERT IGNORE INTO HLProd.committee_expends_to_individual (committee_id, individual_id, money_amount, date, purpose, expenditure_code)
                    VALUES (v_committee_id, v_individual_id, v_amount, DATE(STR_TO_DATE(v_expn_date, '%c/%e/%Y %r')), v_expn_dscr, v_line_item);
                    -- Get the newly inserted expense_id
                    SET v_expense_id = LAST_INSERT_ID();
                    -- If CMTTE_TYPE is 'C' and candidate names are provided, insert into independent_expenditures_individual_candidate
                    IF v_cmtte_type = 'C' AND v_cand_naml IS NOT NULL AND v_cand_namf IS NOT NULL AND v_cand_naml != '' AND v_cand_namf != '' THEN
                        -- Find the candidate_id from the individuals table
                        SELECT id INTO v_candidate_id
                        FROM HLProd.individuals
                        WHERE first_name LIKE v_cand_namf AND last_name LIKE v_cand_naml
                        LIMIT 1;
                        IF v_candidate_id IS NOT NULL THEN
                            INSERT IGNORE INTO HLProd.independent_expenditures_individual_candidate (expense_id, candidate_id, stance)
                            VALUES (v_expense_id, v_candidate_id, v_expn_dscr);
                        END IF;
                    END IF;
                END IF;
            ELSE
                -- Payee is an organization, find the organization_id
                SELECT id INTO v_organization_id
                FROM HLProd.organizations
                WHERE name LIKE v_payee_naml
                LIMIT 1;
                -- If the individual is not found, insert into the individuals table
                IF v_organization_id IS NULL THEN
                    INSERT INTO HLProd.organizations (name)
                    VALUES (v_payee_naml);
                    SET v_organization_id = LAST_INSERT_ID();
                END IF;
                -- Insert into committee_expends_to_organization if organization_id is found
                IF v_organization_id IS NOT NULL THEN
                    INSERT IGNORE INTO HLProd.committee_expends_to_organization (committee_id, organization_id, money_amount, date, purpose, expenditure_code)
                    VALUES (v_committee_id, v_organization_id, v_amount, DATE(STR_TO_DATE(v_expn_date, '%c/%e/%Y %r')), v_expn_dscr, v_line_item);
                    -- Get the newly inserted expense_id
                    SET v_expense_id = LAST_INSERT_ID();
                    -- If CMTTE_TYPE is 'C' and candidate names are provided, insert into independent_expenditures_individual_candidate
                    IF v_cmtte_type = 'C' AND v_cand_naml IS NOT NULL AND v_cand_namf IS NOT NULL AND v_cand_naml != '' AND v_cand_namf != '' THEN
                        -- Find the candidate_id from the individuals table
                        SELECT id INTO v_candidate_id
                        FROM HLProd.individuals
                        WHERE first_name LIKE v_cand_namf AND last_name LIKE v_cand_naml
                        LIMIT 1;
                        IF v_candidate_id IS NOT NULL THEN
                            INSERT IGNORE INTO HLProd.independent_expenditures_organization_candidate (expense_id, candidate_id, stance)
                            VALUES (v_expense_id, v_candidate_id, v_expn_dscr);
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    END LOOP;
    CLOSE cur;
END