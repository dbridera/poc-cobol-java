-- Mirror of cobol/add-policy-db/schema/policy.sql. Both sides reset the
-- table on every run for byte-exact reproducibility.
DROP TABLE IF EXISTS POLICY;

CREATE TABLE POLICY (
    POLICYNUMBER     BIGINT  PRIMARY KEY,
    CUSTOMERNUMBER   BIGINT  NOT NULL,
    ISSUEDATE        VARCHAR(10) NOT NULL,
    EXPIRYDATE       VARCHAR(10) NOT NULL,
    POLICYTYPE       VARCHAR(1)  NOT NULL,
    LASTCHANGED      VARCHAR(26) NOT NULL,
    BROKERID         BIGINT  NOT NULL,
    BROKERSREFERENCE VARCHAR(10) NOT NULL,
    PAYMENT          INTEGER NOT NULL
);
