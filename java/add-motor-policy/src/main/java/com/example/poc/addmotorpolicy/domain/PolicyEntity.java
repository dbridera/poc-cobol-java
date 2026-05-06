package com.example.poc.addmotorpolicy.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;

/**
 * Parent policy row. Mirrors the DB2-POLICY group in {@code lgpolicy.cpy} and
 * the {@code POUT-*} layout in ADDMPOL.cbl FILE SECTION.
 *
 * <p>COBOL: ADDMPOL.cbl:60-72 (POLICY-OUT-RECORD)
 */
@Entity
@Table(name = "policy")
public class PolicyEntity {

    @Id
    @Column(name = "policynumber", nullable = false)
    private BigDecimal policyNumber;        // PIC 9(10)

    @Column(name = "customernumber", nullable = false)
    private BigDecimal customerNumber;      // PIC 9(10)

    @Column(name = "policytype", length = 1, nullable = false)
    private String policyType;              // PIC X        ('M' for module zero)

    @Column(name = "issuedate", length = 10)
    private String issueDate;               // PIC X(10)

    @Column(name = "expirydate", length = 10)
    private String expiryDate;              // PIC X(10)

    @Column(name = "brokerid")
    private BigDecimal brokerId;            // PIC 9(10)

    @Column(name = "brokersref", length = 10)
    private String brokersRef;              // PIC X(10)

    @Column(name = "payment")
    private BigDecimal payment;             // PIC 9(6)

    public PolicyEntity() {}

    public PolicyEntity(BigDecimal policyNumber, BigDecimal customerNumber, String policyType,
                        String issueDate, String expiryDate, BigDecimal brokerId,
                        String brokersRef, BigDecimal payment) {
        this.policyNumber = policyNumber;
        this.customerNumber = customerNumber;
        this.policyType = policyType;
        this.issueDate = issueDate;
        this.expiryDate = expiryDate;
        this.brokerId = brokerId;
        this.brokersRef = brokersRef;
        this.payment = payment;
    }

    public BigDecimal getPolicyNumber() { return policyNumber; }
    public BigDecimal getCustomerNumber() { return customerNumber; }
    public String getPolicyType() { return policyType; }
    public String getIssueDate() { return issueDate; }
    public String getExpiryDate() { return expiryDate; }
    public BigDecimal getBrokerId() { return brokerId; }
    public String getBrokersRef() { return brokersRef; }
    public BigDecimal getPayment() { return payment; }
}
