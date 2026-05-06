package com.example.poc.addmotorpolicy.domain;

import java.math.BigDecimal;

/**
 * DTO mirroring REQUEST-RECORD in ADDMPOL.cbl FILE SECTION.
 *
 * <p>All COBOL numeric fields use {@link BigDecimal} (scale 0 here — these
 * are integer-valued counts/identifiers, not money). See spec §2.1.
 */
public record MotorPolicyRequest(
        String     requestId,
        BigDecimal customerNum,
        BigDecimal policyNum,
        String     issueDate,
        String     expiryDate,
        BigDecimal brokerId,
        String     brokersRef,
        BigDecimal payment,
        String     make,
        String     model,
        BigDecimal value,
        String     regnumber,
        String     colour,
        BigDecimal cc,
        String     manufactured,
        BigDecimal accidents
) {}
