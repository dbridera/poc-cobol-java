package com.example.poc.addpolicydb.service;

import com.example.poc.addpolicydb.domain.PolicyEntity;
import jakarta.persistence.EntityExistsException;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Mirror of INSERT-POLICY in lgapdb01.cbl:261-322.
 *
 * <p>The COBOL paragraph executes {@code EXEC SQL INSERT INTO POLICY ...} and
 * evaluates {@code SQLCODE}:
 * <ul>
 *   <li>0   → CA-RETURN-CODE = '00'</li>
 *   <li>-530 (FK violation) → CA-RETURN-CODE = '70', WRITE-ERROR-MESSAGE,
 *         EXEC CICS RETURN (rolls back the unit-of-work)</li>
 *   <li>other → CA-RETURN-CODE = '90', WRITE-ERROR-MESSAGE, RETURN</li>
 * </ul>
 *
 * <p><b>Empirical finding from fixture 02-sql-errors:</b>
 * {@code JpaRepository.save()} is <em>INSERT-OR-UPDATE</em> (MERGE semantics).
 * When the supplied entity has an ID that already exists, Hibernate silently
 * overwrites the row. {@code EXEC SQL INSERT} on DB2 always attempts an
 * INSERT and returns a constraint-violation SQLCODE on a duplicate PK. A
 * naive {@code save()} translation silently miscounts inserts and corrupts
 * data — caught by the byte-exact diff.
 *
 * <p>{@link EntityManager#persist} gives true INSERT semantics: throws
 * {@link EntityExistsException} on a duplicate, wrapped by Spring as
 * {@link DataIntegrityViolationException}. We let the exception propagate
 * so Spring rolls back this inner unit of work cleanly; the caller catches
 * and converts to a per-request return code.
 *
 * <p>{@link Propagation#REQUIRES_NEW} ensures each request gets its own
 * transaction — the COBOL pattern is "one CICS transaction per request",
 * not one transaction wrapping the whole batch.
 */
@Service
public class PolicyInsertService {

    @PersistenceContext
    private EntityManager em;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void insert(PolicyEntity policy) {
        em.persist(policy);
        em.flush();
    }
}
