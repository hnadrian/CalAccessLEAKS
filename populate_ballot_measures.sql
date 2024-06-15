-- Active: 1718224497967@@devdb.chzg5zpujwmo.us-west-2.rds.amazonaws.com@3306@HLProd
DROP PROCEDURE populate_ballot_measures;
CREATE DEFINER=`HLobbyists1`@`%` PROCEDURE `populate_ballot_measures`()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE b_election_date VARCHAR(200);
    DECLARE b_measure_no VARCHAR(200);
    DECLARE b_measure_name VARCHAR(200);
    DECLARE b_measure_short_name VARCHAR(200);
    DECLARE b_jurisdiction VARCHAR(200);
    DECLARE b_year INT;
    DECLARE election_id INT;
    DECLARE prop_ballot_measures_id INT;

    -- Declare a cursor to iterate over the BALLOT_MEASURES_CD table
    DECLARE ballot_cursor CURSOR FOR
        SELECT ELECTION_DATE, MEASURE_NO, MEASURE_NAME, MEASURE_SHORT_NAME, JURISDICTION
        FROM CalAccess.BALLOT_MEASURES_CD;

    -- Declare a handler for the end of the cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN ballot_cursor;

    read_loop: LOOP
        FETCH ballot_cursor INTO b_election_date, b_measure_no, b_measure_name, b_measure_short_name, b_jurisdiction;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Debug: Print fetched values
        SELECT CONCAT('Fetched: ELECTION_DATE=', b_election_date, ', MEASURE_NO=', b_measure_no, ', MEASURE_NAME=', b_measure_name, ', MEASURE_SHORT_NAME=', b_measure_short_name, ', JURISDICTION=', b_jurisdiction) AS debug_fetched_values;

        -- Extract year from ELECTION_DATE
        SET b_year = YEAR(STR_TO_DATE(b_election_date, '%c/%e/%Y %r'));

        -- Extract date from ELECTION_DATE
        SET @date = STR_TO_DATE(b_election_date, '%c/%e/%Y %r');

            INSERT IGNORE INTO HLProd.prop_ballot_measures (number, year, title, description)
            VALUES (b_measure_no, b_year, b_measure_short_name, b_measure_name);

            SELECT id into prop_ballot_measures_id
            FROM HLProd.prop_ballot_measures
            WHERE b_measure_no = number and b_year = year;

            INSERT IGNORE INTO HLProd.elections (`name`, `type`, `date`)
            VALUES ("Prop/Ballot Measures", b_jurisdiction, @date);

            -- Get the last inserted ID for elections
            SELECT id into election_id
            FROM HLProd.elections
            WHERE name = "Prop/Ballot Measures" and type = b_jurisdiction and date = @date;

            INSERT IGNORE INTO HLProd.prop_ballot_measures_elections (election_id, prop_ballot_measures_id)
            VALUES (election_id, prop_ballot_measures_id);
            
    END LOOP;

    CLOSE ballot_cursor;
END