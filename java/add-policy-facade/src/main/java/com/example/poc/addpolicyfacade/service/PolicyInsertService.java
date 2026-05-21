package com.example.poc.addpolicyfacade.service;

import com.example.poc.addpolicyfacade.domain.PolicyEntity;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Mirror of INSERT-POLICY in lgapdb01.cbl:261-322.
 *
 * <p>See [java/add-policy-db/.../PolicyInsertService.java] for the full
 * rationale on {@link EntityManager#persist} + {@link Propagation#REQUIRES_NEW}
 * + caller-catches-RuntimeException pattern. The empirical finding from
 * module 1B's fixture 02-sql-errors (JpaRepository.save is MERGE not INSERT)
 * applies identically here.
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
