package com.example.poc.addpolicyfacade.domain;

import org.springframework.data.jpa.repository.JpaRepository;

public interface PolicyRepository extends JpaRepository<PolicyEntity, Long> {}
