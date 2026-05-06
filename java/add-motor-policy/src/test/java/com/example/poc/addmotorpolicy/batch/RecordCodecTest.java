package com.example.poc.addmotorpolicy.batch;

import com.example.poc.addmotorpolicy.domain.MotorEntity;
import com.example.poc.addmotorpolicy.domain.MotorPolicyRequest;
import com.example.poc.addmotorpolicy.domain.PolicyEntity;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

class RecordCodecTest {

    private final RecordCodec codec = new RecordCodec();

    @Test
    void parsesHappySmallRecord1() {
        // First record from fixtures/01-happy-small (regenerate via tools/make-fixture.py if changed).
        String line =
                "01AMOT" +              // request_id
                "1234567890" +          // customer_num
                "0000000000" +          // policy_num (input ignored)
                "2025-01-15" +
                "2026-01-15" +
                "0000000100" +          // broker_id
                "BR-A001   " +          // brokers_ref
                "000100" +              // payment
                "TOYOTA         " +     // make
                "YARIS          " +     // model
                "012000" +              // value
                "ABC1234" +             // regnumber
                "RED     " +            // colour
                "0998" +                // cc
                "2022      " +          // manufactured
                "000000";               // accidents
        MotorPolicyRequest r = codec.parseRequest(line);
        assertThat(r.requestId()).isEqualTo("01AMOT");
        assertThat(r.customerNum()).isEqualByComparingTo(new BigDecimal("1234567890"));
        assertThat(r.cc()).isEqualByComparingTo(new BigDecimal("998"));
        assertThat(r.value()).isEqualByComparingTo(new BigDecimal("12000"));
        assertThat(r.accidents()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(r.make()).isEqualTo("TOYOTA         ");
    }

    @Test
    void encodesPolicyRecordToExactly67Chars() {
        PolicyEntity p = new PolicyEntity(
                new BigDecimal("1"), new BigDecimal("1234567890"), "M",
                "2025-01-15", "2026-01-15",
                new BigDecimal("100"), "BR-A001   ", new BigDecimal("100"));
        String line = codec.encodePolicy(p);
        assertThat(line).hasSize(67);
        assertThat(line).isEqualTo("00000000011234567890M2025-01-152026-01-150000000100BR-A001   000100");
    }

    @Test
    void encodesMotorRecordToExactly87Chars() {
        MotorEntity m = new MotorEntity(
                new BigDecimal("1"), "TOYOTA         ", "YARIS          ", new BigDecimal("12000"),
                "ABC1234", "RED     ", new BigDecimal("998"), "2022      ",
                new BigDecimal("260"), BigDecimal.ZERO);
        String line = codec.encodeMotor(m);
        assertThat(line).hasSize(87);
        assertThat(line).isEqualTo(
                "0000000001TOYOTA         YARIS          012000ABC1234RED     09982022      000260000000");
    }
}
