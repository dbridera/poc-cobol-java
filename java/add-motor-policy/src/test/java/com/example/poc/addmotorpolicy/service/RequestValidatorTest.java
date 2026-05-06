package com.example.poc.addmotorpolicy.service;

import com.example.poc.addmotorpolicy.domain.MotorPolicyRequest;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

class RequestValidatorTest {

    private final RequestValidator v = new RequestValidator();

    @Test
    void unknownRequestId() {
        var f = v.validate(req("01XXXX", 1, 1500, 30000, "2025-01-01", "2026-01-01"));
        assertThat(f).isPresent();
        assertThat(f.get().returnCode()).isEqualTo(99);
        assertThat(f.get().reason()).isEqualTo("unknown request id");
    }

    @Test
    void zeroCustomerNumberFiresFirst() {
        // even when cc and value are also invalid, customer-num check fires first.
        var f = v.validate(req("01AMOT", 0, 0, 0, "2025-01-01", "2026-01-01"));
        assertThat(f).isPresent();
        assertThat(f.get().reason()).isEqualTo("customer number is zero");
    }

    @Test
    void zeroCcWhenCustomerOk() {
        var f = v.validate(req("01AMOT", 100, 0, 30000, "2025-01-01", "2026-01-01"));
        assertThat(f).isPresent();
        assertThat(f.get().reason()).isEqualTo("engine cc is zero");
    }

    @Test
    void zeroValueWhenCustomerAndCcOk() {
        var f = v.validate(req("01AMOT", 100, 1500, 0, "2025-01-01", "2026-01-01"));
        assertThat(f).isPresent();
        assertThat(f.get().reason()).isEqualTo("vehicle value is zero");
    }

    @Test
    void blankIssueDate() {
        var f = v.validate(req("01AMOT", 100, 1500, 30000, "          ", "2026-01-01"));
        assertThat(f).isPresent();
        assertThat(f.get().reason()).isEqualTo("issue date is blank");
    }

    @Test
    void blankExpiryDate() {
        var f = v.validate(req("01AMOT", 100, 1500, 30000, "2025-01-01", "          "));
        assertThat(f).isPresent();
        assertThat(f.get().reason()).isEqualTo("expiry date is blank");
    }

    @Test
    void allValidPasses() {
        Optional<RequestValidator.ValidationFailure> f =
                v.validate(req("01AMOT", 100, 1500, 30000, "2025-01-01", "2026-01-01"));
        assertThat(f).isEmpty();
    }

    private static MotorPolicyRequest req(String reqId, long customer, long cc, long value,
                                          String issue, String expiry) {
        return new MotorPolicyRequest(
                reqId, bd(customer), bd(0), issue, expiry,
                bd(0), "", bd(0), "", "", bd(value), "", "", bd(cc), "", bd(0));
    }
    private static BigDecimal bd(long n) { return new BigDecimal(n); }
}
