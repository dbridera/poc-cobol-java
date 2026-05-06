package com.example.poc.addmotorpolicy.batch;

import com.example.poc.addmotorpolicy.domain.MotorEntity;
import com.example.poc.addmotorpolicy.domain.MotorPolicyRequest;
import com.example.poc.addmotorpolicy.domain.PolicyEntity;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.BigInteger;

/**
 * Fixed-width record codec.
 *
 * <p>Parses {@code requests.dat} input lines and serializes
 * {@link PolicyEntity} / {@link MotorEntity} into the byte-exact format that
 * COBOL ADDMPOL writes to {@code policy.dat} / {@code motor.dat}. See spec §6.
 *
 * <p>Encoding contract:
 * <ul>
 *   <li>numeric PIC 9(n) → zero-padded decimal string, exactly n chars</li>
 *   <li>alphanumeric PIC X(n) → right-padded with spaces, exactly n chars</li>
 * </ul>
 */
@Component
public class RecordCodec {

    public MotorPolicyRequest parseRequest(String line) {
        // Pad/truncate the line to 143 chars so off-by-one short lines don't crash —
        // COBOL would also accept short LINE-SEQUENTIAL records and pad with spaces.
        String s = line.length() >= 143 ? line.substring(0, 143)
                : padRight(line, 143);
        Cursor c = new Cursor(s);
        return new MotorPolicyRequest(
                c.takeStr(6),                // request_id
                c.takeNum(10),               // customer_num
                c.takeNum(10),               // policy_num
                c.takeStr(10),               // issue_date
                c.takeStr(10),               // expiry_date
                c.takeNum(10),               // broker_id
                c.takeStr(10),               // brokers_ref
                c.takeNum(6),                // payment
                c.takeStr(15),               // make
                c.takeStr(15),               // model
                c.takeNum(6),                // value
                c.takeStr(7),                // regnumber
                c.takeStr(8),                // colour
                c.takeNum(4),                // cc
                c.takeStr(10),               // manufactured
                c.takeNum(6)                 // accidents
        );
    }

    /** Encode policy.dat record (67 chars). */
    public String encodePolicy(PolicyEntity p) {
        return num(p.getPolicyNumber(), 10)
             + num(p.getCustomerNumber(), 10)
             + padRight(p.getPolicyType(), 1)
             + padRight(p.getIssueDate(), 10)
             + padRight(p.getExpiryDate(), 10)
             + num(p.getBrokerId(), 10)
             + padRight(p.getBrokersRef(), 10)
             + num(p.getPayment(), 6);
    }

    /** Encode motor.dat record (87 chars). */
    public String encodeMotor(MotorEntity m) {
        return num(m.getPolicyNumber(), 10)
             + padRight(m.getMake(), 15)
             + padRight(m.getModel(), 15)
             + num(m.getValue(), 6)
             + padRight(m.getRegnumber(), 7)
             + padRight(m.getColour(), 8)
             + num(m.getCc(), 4)
             + padRight(m.getManufactured(), 10)
             + num(m.getPremium(), 6)
             + num(m.getAccidents(), 6);
    }

    // ---- helpers ----

    static String num(BigDecimal v, int width) {
        BigInteger bi = v.toBigInteger();
        String s = bi.signum() < 0 ? bi.negate().toString() : bi.toString();
        if (s.length() > width) {
            // COBOL would silently truncate from the left in some cases or trigger
            // size error elsewhere. Module zero never produces over-width values
            // (validated upstream), so failing loudly is the right behavior.
            throw new IllegalArgumentException(
                    "value " + v + " does not fit PIC 9(" + width + ")");
        }
        return "0".repeat(width - s.length()) + s;
    }

    static String padRight(String s, int width) {
        String t = (s == null) ? "" : s;
        if (t.length() >= width) return t.substring(0, width);
        return t + " ".repeat(width - t.length());
    }

    private static final class Cursor {
        private final String s;
        private int pos = 0;
        Cursor(String s) { this.s = s; }
        String takeStr(int n) {
            String out = s.substring(pos, pos + n);
            pos += n;
            return out;
        }
        BigDecimal takeNum(int n) {
            String raw = s.substring(pos, pos + n);
            pos += n;
            String trimmed = raw.trim();
            if (trimmed.isEmpty()) return BigDecimal.ZERO;
            return new BigDecimal(new BigInteger(trimmed));
        }
    }
}
