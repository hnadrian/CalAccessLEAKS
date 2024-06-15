-- Active: 1718224497967@@devdb.chzg5zpujwmo.us-west-2.rds.amazonaws.com@3306@HLProd
DROP PROCEDURE populate_individuals_pid;
CREATE DEFINER=`HLobbyists1`@`%` PROCEDURE `populate_individuals_pid`()
BEGIN
    DECLARE finished INT DEFAULT 0;
    DECLARE v_pid INT;
    DECLARE v_first VARCHAR(255);
    DECLARE v_last VARCHAR(255);
    DECLARE v_middle VARCHAR(255);
    DECLARE v_suffix VARCHAR(255);
    DECLARE v_individual_id INT;
    DECLARE count_matches INT;
    -- Declare cursor for selecting from Person table
    DECLARE cur CURSOR FOR 
    SELECT pid, first, last, middle, suffix
    FROM DDDB2016Aug.Person;
    -- Declare continue handler
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_pid, v_first, v_last, v_middle, v_suffix;
        IF finished THEN
            LEAVE read_loop;
        END IF;
        -- Debug: Print the current values
        -- SELECT v_pid, v_first, v_last, v_middle, v_suffix;
        -- Check for matching individuals and count matches
        SELECT COUNT(*) INTO count_matches
        FROM HLProd.individuals 
        WHERE first_name = v_first AND last_name = v_last AND 
              (middle_name = v_middle OR v_middle IS NULL) AND 
              (suffix = v_suffix OR v_suffix IS NULL);
        -- If there is exactly one match, update the pid
        IF count_matches = 1 THEN
            SELECT id INTO v_individual_id
            FROM HLProd.individuals 
            WHERE first_name = v_first AND last_name = v_last AND 
                  (middle_name = v_middle OR v_middle IS NULL) AND 
                  (suffix = v_suffix OR v_suffix IS NULL);
            UPDATE HLProd.individuals
            SET pid = v_pid
            WHERE id = v_individual_id;
        END IF;
    END LOOP;
    CLOSE cur;
END