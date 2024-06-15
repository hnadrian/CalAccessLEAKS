-- Active: 1718224497967@@devdb.chzg5zpujwmo.us-west-2.rds.amazonaws.com@3306@HLProd
DROP PROCEDURE populate_lawmakers;
CREATE DEFINER=`HLobbyists1`@`%` PROCEDURE `populate_lawmakers`()
BEGIN
    DECLARE finished INT DEFAULT 0;
    DECLARE v_pid INT;
    DECLARE v_individual_id INT;
    -- Declare cursor for selecting unique pids from Legislator table
    DECLARE cur CURSOR FOR 
    SELECT DISTINCT Legislator.pid
    FROM DDDB2016Aug.Legislator
    JOIN HLProd.individuals ON individuals.pid = Legislator.pid;
    -- Declare continue handler
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_pid;
        IF finished THEN
            SELECT v_pid;
            LEAVE read_loop;
        END IF;
        -- Debug: Print the current pid value
        -- SELECT v_pid;
        -- Check if the pid exists in the individuals table
        SELECT id INTO v_individual_id
        FROM HLProd.individuals
        WHERE pid = v_pid
        LIMIT 1;
        -- If a match is found, insert into lawmakers table
        IF v_individual_id IS NOT NULL THEN
            -- Avoid duplicates in lawmakers table
            IF NOT EXISTS (
                SELECT 1 FROM HLProd.lawmakers WHERE individual_id = v_individual_id
            ) THEN
                INSERT INTO HLProd.lawmakers (individual_id)
                VALUES (v_individual_id);
            END IF;
        END IF;
    END LOOP;
    CLOSE cur;
END