-- Active: 1718224497967@@devdb.chzg5zpujwmo.us-west-2.rds.amazonaws.com@3306@HLProd
DROP PROCEDURE parse_candidates;
CREATE DEFINER=`HLobbyists1`@`%` PROCEDURE `parse_candidates`()
BEGIN
    DECLARE finished INT DEFAULT 0;
    DECLARE v_filer_id_new VARCHAR(200);
    DECLARE v_converted_filer_id_new INT;
    DECLARE v_first_name VARCHAR(255);
    DECLARE v_middle_name VARCHAR(255);
    DECLARE v_last_name VARCHAR(255);
    DECLARE v_suffix VARCHAR(255);
    DECLARE v_dist_no VARCHAR(255);
    DECLARE v_offic_dscr VARCHAR(255);
    DECLARE v_agency_nam VARCHAR(255);
    DECLARE v_yr_of_elec VARCHAR(200);
    DECLARE v_individual_id INT;
    DECLARE v_office_id INT;
    DECLARE v_election_id INT;
    DECLARE v_office_election_id INT;
    -- Declare cursor
    DECLARE cur CURSOR FOR 
    SELECT FILER_ID, CAND_NAMF, CAN_NAMM, CAND_NAML, CAND_NAMS, DIST_NO, OFFIC_DSCR, AGENCY_NAM, YR_OF_ELEC 
    FROM CalAccess.F501_502_CD;
    -- Declare continue handler
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_filer_id_new, v_first_name, v_middle_name, v_last_name, v_suffix, v_dist_no, v_offic_dscr, v_agency_nam, v_yr_of_elec;
        IF finished THEN
            -- Debug: Print the final values
            -- SELECT v_filer_id_new, v_first_name, v_middle_name, v_last_name, v_suffix, v_dist_no, v_offic_dscr, v_agency_nam, v_yr_of_elec;
            LEAVE read_loop;
        END IF;
        -- Debug: Print the current values
        -- SELECT v_filer_id_new, v_first_name, v_middle_name, v_last_name, v_suffix, v_dist_no, v_offic_dscr, v_agency_nam, v_yr_of_elec;
        -- Convert FILER_ID to SIGNED
        SET v_converted_filer_id_new = CONVERT(v_filer_id_new, SIGNED);
        -- Check if conversion is successful
        IF v_converted_filer_id_new IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FILER_ID conversion failed';
        END IF;
        -- Insert individual if not exists
        INSERT IGNORE INTO HLProd.individuals (filer_id_new, first_name, middle_name, last_name, suffix)
        VALUES (v_converted_filer_id_new, v_first_name, v_middle_name, v_last_name, v_suffix);
        -- Get the individual id
        SELECT id INTO v_individual_id FROM HLProd.individuals WHERE filer_id_new = v_filer_id_new;
        -- Debug: Check if individual id was found
        IF v_individual_id IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Individual ID not found';
        END IF;
        -- Insert individual into candidates if not exists
        INSERT IGNORE INTO HLProd.candidates (individual_id) VALUES (v_individual_id);
        -- Insert or update offices
        INSERT IGNORE INTO HLProd.offices (name, chamber, district)
        VALUES (v_offic_dscr, v_agency_nam, v_dist_no);
        -- Get the office id
        SELECT id INTO v_office_id FROM HLProd.offices WHERE name = v_offic_dscr AND chamber = v_agency_nam AND district = v_dist_no;
        -- Debug: Check if office id was found
        IF v_office_id IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Office ID not found';
        END IF;
        -- Insert or update elections
        INSERT IGNORE INTO HLProd.elections (name, type, date)
        VALUES (v_offic_dscr, v_agency_nam, STR_TO_DATE(v_yr_of_elec, '%Y'));
        -- Get the election id
        SELECT id INTO v_election_id FROM HLProd.elections WHERE name = v_offic_dscr AND type = v_agency_nam AND date = STR_TO_DATE(v_yr_of_elec, '%Y');
        -- Debug: Check if election id was found
        IF v_election_id IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Election ID not found';
        END IF;
        -- Insert office_elections if not exists
        INSERT IGNORE INTO HLProd.office_elections (election_id, office_id) VALUES (v_election_id, v_office_id);
        -- Get the office election id
        SELECT id INTO v_office_election_id FROM HLProd.office_elections WHERE election_id = v_election_id AND office_id = v_office_id;
        -- Debug: Check if office election id was found
        IF v_office_election_id IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Office Election ID not found';
        END IF;
        -- Insert into run_for if not exists
        INSERT IGNORE INTO HLProd.run_for (candidate_id, office_election_id) VALUES (v_individual_id, v_office_election_id);
    END LOOP;
    CLOSE cur;
END