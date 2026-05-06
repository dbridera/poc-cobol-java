package com.example.poc.addmotorpolicy.service;

/**
 * Raised when a premium calculation cannot fit COBOL's PIC 9(6)V99 / PIC 9(6)
 * representations. Maps to RC=11 in the COBOL ADDMPOL semantics. The reason
 * string is preserved verbatim so that error.log byte-equivalence holds.
 */
public class PremiumOverflowException extends RuntimeException {
    public PremiumOverflowException(String reason) {
        super(reason);
    }
}
