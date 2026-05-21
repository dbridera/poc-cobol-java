package com.example.poc.addpolicyfacade.batch;

import com.example.poc.addpolicyfacade.domain.PolicyEntity;
import org.springframework.stereotype.Component;

/**
 * Parses a 99-char fixed-width request line into a {@link PolicyEntity}.
 *
 * <p>Layout mirrors REQUEST-RECORD in [cobol/add-policy-db/src/ADDPOLDB.cbl:33-44]:
 * <pre>
 *   request_id    X(6)   0-6
 *   policy_num    9(10)  6-16
 *   customer_num  9(10)  16-26
 *   issue_date    X(10)  26-36
 *   expiry_date   X(10)  36-46
 *   policy_type   X(1)   46-47
 *   lastchanged   X(26)  47-73
 *   broker_id     9(10)  73-83
 *   brokers_ref   X(10)  83-93
 *   payment       9(6)   93-99
 * </pre>
 *
 * <p>Text fields are taken as-is (no trim) except {@code brokers_ref}, which
 * the COBOL inserts via {@code FUNCTION TRIM} — see
 * [cobol/add-policy-db/src/ADDPOLDB.cbl:144]. We trim here for byte-exact diff.
 */
@Component
public class RecordCodec {

    static final int RECORD_LENGTH = 99;

    public PolicyEntity parseRequest(String line) {
        if (line.length() != RECORD_LENGTH) {
            throw new IllegalArgumentException(
                "expected " + RECORD_LENGTH + "-char record, got " + line.length());
        }
        // request_id at 0-6 is currently 01APOL only; parsed but not stored
        // (no per-request dispatch in module 1B yet).
        long   policyNumber    = Long.parseLong(line.substring(6, 16));
        long   customerNumber  = Long.parseLong(line.substring(16, 26));
        String issueDate       = line.substring(26, 36);
        String expiryDate      = line.substring(36, 46);
        String policyType      = line.substring(46, 47);
        String lastChanged     = line.substring(47, 73);
        long   brokerId        = Long.parseLong(line.substring(73, 83));
        String brokersRef      = line.substring(83, 93).stripTrailing();
        long   payment         = Long.parseLong(line.substring(93, 99));

        return new PolicyEntity(policyNumber, customerNumber,
                issueDate, expiryDate, policyType, lastChanged,
                brokerId, brokersRef, payment);
    }
}
