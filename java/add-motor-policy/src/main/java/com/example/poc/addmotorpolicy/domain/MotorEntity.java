package com.example.poc.addmotorpolicy.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;

/**
 * Child motor row. Mirrors the DB2-MOTOR group in {@code lgpolicy.cpy} and
 * the {@code MOUT-*} layout in ADDMPOL.cbl FILE SECTION.
 *
 * <p>COBOL: ADDMPOL.cbl:75-86 (MOTOR-OUT-RECORD)
 */
@Entity
@Table(name = "motor")
public class MotorEntity {

    @Id
    @Column(name = "policynumber", nullable = false)
    private BigDecimal policyNumber;        // PIC 9(10)

    @Column(name = "make", length = 15)
    private String make;                    // PIC X(15)

    @Column(name = "model", length = 15)
    private String model;                   // PIC X(15)

    @Column(name = "value")
    private BigDecimal value;               // PIC 9(6)

    @Column(name = "regnumber", length = 7)
    private String regnumber;               // PIC X(7)

    @Column(name = "colour", length = 8)
    private String colour;                  // PIC X(8)

    @Column(name = "cc")
    private BigDecimal cc;                  // PIC 9(4)

    @Column(name = "manufactured", length = 10)
    private String manufactured;            // PIC X(10)

    @Column(name = "premium")
    private BigDecimal premium;             // PIC 9(6) — output of MotorPremiumCalculator

    @Column(name = "accidents")
    private BigDecimal accidents;           // PIC 9(6)

    public MotorEntity() {}

    public MotorEntity(BigDecimal policyNumber, String make, String model, BigDecimal value,
                       String regnumber, String colour, BigDecimal cc, String manufactured,
                       BigDecimal premium, BigDecimal accidents) {
        this.policyNumber = policyNumber;
        this.make = make;
        this.model = model;
        this.value = value;
        this.regnumber = regnumber;
        this.colour = colour;
        this.cc = cc;
        this.manufactured = manufactured;
        this.premium = premium;
        this.accidents = accidents;
    }

    public BigDecimal getPolicyNumber() { return policyNumber; }
    public String getMake() { return make; }
    public String getModel() { return model; }
    public BigDecimal getValue() { return value; }
    public String getRegnumber() { return regnumber; }
    public String getColour() { return colour; }
    public BigDecimal getCc() { return cc; }
    public String getManufactured() { return manufactured; }
    public BigDecimal getPremium() { return premium; }
    public BigDecimal getAccidents() { return accidents; }
}
