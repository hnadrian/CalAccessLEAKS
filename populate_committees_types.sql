-- Active: 1718224497967@@devdb.chzg5zpujwmo.us-west-2.rds.amazonaws.com@3306@HLProd
DROP PROCEDURE populate_committees_types;
CREATE DEFINER=`HLobbyists1`@`%` PROCEDURE `populate_committees_types`()
BEGIN
INSERT INTO controlled_committees(committee_id, candidate_id)
    SELECT DISTINCT
        c.id AS committee_id,
        can.individual_id AS candidate_id
    FROM 
        CalAccess.CVR_CAMPAIGN_DISCLOSURE_CD cd
    INNER JOIN 
        committees c ON cd.FILER_ID = c.filer_id_new
    LEFT JOIN 
        individuals i ON (cd.CAND_NAML = i.last_name AND cd.CAND_NAMF = i.first_name)
    LEFT JOIN 
        candidates can ON i.id = can.individual_id
    WHERE 
        ((cd.CMTTE_TYPE = "C" AND cd.CONTROL_YN = "Y") OR (cd.ENTITY_CD = "CTL"))
        AND can.individual_id IS NOT NULL
    ON DUPLICATE KEY UPDATE
        candidate_id = VALUES(candidate_id);

    INSERT INTO general_purpose_committees(committee_id, formed_by_org)
    SELECT DISTINCT
        c.id AS committee_id,
        NULL AS formed_by_org
    FROM 
        CalAccess.CVR_CAMPAIGN_DISCLOSURE_CD cd
    INNER JOIN 
        committees c ON cd.FILER_ID = c.filer_id_new
    WHERE 
        cd.CMTTE_TYPE = "G"
    ON DUPLICATE KEY UPDATE
        formed_by_org = VALUES(formed_by_org);

    INSERT INTO ballot_measure_committees(committee_id, props_ballot_measures_id, position)
    SELECT DISTINCT
        c.id AS committee_id,
        pbm.id AS props_ballot_measures_id,
        COALESCE(cd.SUP_OPP_CD, NULL) AS position
    FROM 
        CalAccess.CVR_CAMPAIGN_DISCLOSURE_CD cd
    INNER JOIN 
        committees c ON cd.FILER_ID = c.filer_id_new
    INNER JOIN
        prop_ballot_measures pbm ON pbm.number = cd.BAL_NUM AND pbm.title = cd.BAL_NAME
    WHERE 
        (cd.CMTTE_TYPE = "B" OR cd.ENTITY_CD = "BMC") 
        AND cd.FILER_ID IS NOT NULL
        AND cd.BAL_NAME IS NOT NULL
        AND cd.BAL_NUM IS NOT NULL;

    INSERT INTO third_party_committees(committee_id, candidate_id, position)
    SELECT DISTINCT
        c.id AS committee_id,
        can.individual_id AS candidate_id,
        COALESCE(cd.SUP_OPP_CD, "") AS position
    FROM 
        CalAccess.CVR_CAMPAIGN_DISCLOSURE_CD cd
    INNER JOIN 
        committees c ON cd.FILER_ID = c.filer_id_new
    LEFT JOIN 
        individuals i ON (cd.CAND_NAML = i.last_name AND cd.CAND_NAMF = i.first_name)
    LEFT JOIN
        candidates can ON i.id = can.individual_id
    WHERE
        cd.ENTITY_CD NOT IN ("BMC", "CAO", "SMO")
        AND cd.CMTTE_TYPE <> "B"
        AND cd.CONTROL_YN <> "Y"
        AND can.individual_id IS NOT NULL
    ON DUPLICATE KEY UPDATE
        candidate_id = VALUES(candidate_id),
        position = VALUES(position);
END