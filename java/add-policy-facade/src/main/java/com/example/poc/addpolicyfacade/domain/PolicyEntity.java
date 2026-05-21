package com.example.poc.addpolicyfacade.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Maps to the POLICY row inserted by INSERT-POLICY (cobol/add-policy-db/src/ADDPOLDB.cbl:113-150).
 *
 * <p>Column order matches the COBOL CREATE TABLE; byte-exact diff depends on
 * the dump rendering columns in the same order on both sides.
 */
@Entity
@Table(name = "POLICY")
public class PolicyEntity {

    @Id
    @Column(name = "POLICYNUMBER")
    private Long policyNumber;

    @Column(name = "CUSTOMERNUMBER", nullable = false)
    private Long customerNumber;

    @Column(name = "ISSUEDATE", nullable = false, length = 10)
    private String issueDate;

    @Column(name = "EXPIRYDATE", nullable = false, length = 10)
    private String expiryDate;

    @Column(name = "POLICYTYPE", nullable = false, length = 1)
    private String policyType;

    @Column(name = "LASTCHANGED", nullable = false, length = 26)
    private String lastChanged;

    @Column(name = "BROKERID", nullable = false)
    private Long brokerId;

    @Column(name = "BROKERSREFERENCE", nullable = false, length = 10)
    private String brokersReference;

    @Column(name = "PAYMENT", nullable = false)
    private Long payment;

    protected PolicyEntity() {}

    public PolicyEntity(Long policyNumber, Long customerNumber,
                        String issueDate, String expiryDate, String policyType,
                        String lastChanged, Long brokerId,
                        String brokersReference, Long payment) {
        this.policyNumber = policyNumber;
        this.customerNumber = customerNumber;
        this.issueDate = issueDate;
        this.expiryDate = expiryDate;
        this.policyType = policyType;
        this.lastChanged = lastChanged;
        this.brokerId = brokerId;
        this.brokersReference = brokersReference;
        this.payment = payment;
    }

    public Long getPolicyNumber()     { return policyNumber; }
    public Long getCustomerNumber()   { return customerNumber; }
    public String getIssueDate()      { return issueDate; }
    public String getExpiryDate()     { return expiryDate; }
    public String getPolicyType()     { return policyType; }
    public String getLastChanged()    { return lastChanged; }
    public Long getBrokerId()         { return brokerId; }
    public String getBrokersReference() { return brokersReference; }
    public Long getPayment()          { return payment; }
}
