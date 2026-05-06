package com.example.poc.addmotorpolicy.service;

import com.example.poc.addmotorpolicy.domain.MotorPolicyRequest;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.Optional;

/**
 * Mirror of CHECK-REQUEST-ID + VALIDATE-REQUEST in ADDMPOL.cbl:199-225.
 *
 * <p>Rules are evaluated in order and the FIRST failing rule is returned —
 * matching COBOL's EVALUATE TRUE short-circuit. See spec §4.
 */
@Component
public class RequestValidator {

    private static final BigDecimal ZERO = BigDecimal.ZERO;

    /**
     * @return empty if valid, otherwise the failure with the COBOL-equivalent
     *         return code and reason text.
     */
    public Optional<ValidationFailure> validate(MotorPolicyRequest req) {
        if (!"01AMOT".equals(req.requestId())) {
            return Optional.of(new ValidationFailure(99, "unknown request id"));
        }
        // Order is load-bearing — preserves COBOL EVALUATE TRUE short-circuit.
        if (req.customerNum().compareTo(ZERO) == 0) {
            return Optional.of(new ValidationFailure(10, "customer number is zero"));
        }
        if (req.cc().compareTo(ZERO) == 0) {
            return Optional.of(new ValidationFailure(10, "engine cc is zero"));
        }
        if (req.value().compareTo(ZERO) == 0) {
            return Optional.of(new ValidationFailure(10, "vehicle value is zero"));
        }
        if (isBlank(req.issueDate())) {
            return Optional.of(new ValidationFailure(10, "issue date is blank"));
        }
        if (isBlank(req.expiryDate())) {
            return Optional.of(new ValidationFailure(10, "expiry date is blank"));
        }
        return Optional.empty();
    }

    private static boolean isBlank(String s) {
        return s == null || s.isBlank();
    }

    public record ValidationFailure(int returnCode, String reason) {}
}
