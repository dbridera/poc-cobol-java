-- POLICY table for module 1B (add-policy-db).
--
-- DB2 → SQLite/H2 type mapping (see CLAUDE.md cheatsheet + docs/glossary.yaml):
--   DB2 INTEGER       -> SQLite INTEGER / H2 INT
--   DB2 VARCHAR(N)    -> SQLite TEXT    / H2 VARCHAR(N)
--   DB2 DATE          -> SQLite TEXT    / H2 VARCHAR (ISO-8601 YYYY-MM-DD)
--   DB2 TIMESTAMP     -> SQLite TEXT    / H2 VARCHAR (ISO-8601 YYYY-MM-DD HH:MM:SS)
--
-- Column order MUST match the INSERT in src/ADDPOLDB.cbl and in the Java
-- PolicyEntity — byte-exact diff is sensitive to dump column order.

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
