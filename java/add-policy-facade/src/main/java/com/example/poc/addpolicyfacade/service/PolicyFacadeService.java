package com.example.poc.addpolicyfacade.service;

import com.example.poc.addpolicyfacade.domain.PolicyEntity;
import org.springframework.stereotype.Service;

/**
 * Mirror of lgapol01.cbl MAINLINE SECTION (lgapol01.cbl:80-126).
 *
 * <p>The original COBOL facade:
 * <ol>
 *   <li>validates the commarea (length check; if too short → CA-RETURN-CODE='98')</li>
 *   <li>{@code EXEC CICS LINK PROGRAM("LGAPDB01") COMMAREA(...)} — delegates
 *       the actual INSERT to the DB program</li>
 *   <li>{@code EXEC CICS RETURN} — returns the commarea (now mutated with
 *       the inserted policy number and a return code) to the caller</li>
 * </ol>
 *
 * <p>The Java translation maps the CICS LINK to an {@code @Autowired}
 * service-to-service call inside the same JVM (Spring DI). The
 * {@link PolicyInsertService} below carries the {@code @Transactional}
 * boundary, which gives us the same unit-of-work guarantees CICS gave
 * the original.
 *
 * <p>The batch-mode validation here corresponds to lgapol01.cbl:113-116
 * (RC=98 when the commarea is too short). In our PoC the "too-short
 * commarea" maps to "policy_num is zero" — see
 * [cobol/add-policy-facade/README.md] for why.
 */
@Service
public class PolicyFacadeService {

    /** Return code carried back to the batch driver. Matches CA-RETURN-CODE. */
    public enum Result { OK_00, TOO_SHORT_98, SQL_ERROR }

    private final PolicyInsertService inserter;

    public PolicyFacadeService(PolicyInsertService inserter) {
        this.inserter = inserter;
    }

    public Result add(PolicyEntity request) {
        if (request.getPolicyNumber() == null || request.getPolicyNumber() == 0L) {
            return Result.TOO_SHORT_98;
        }
        try {
            // Equivalent of EXEC CICS LINK PROGRAM("LGAPDB01") COMMAREA(...).
            inserter.insert(request);
            return Result.OK_00;
        } catch (RuntimeException e) {
            // Inner INSERT failed (constraint, FK, etc.). The COBOL facade
            // propagates the inner RC verbatim; we collapse all DB errors
            // to SQL_ERROR which maps to the shim's RC=1.
            return Result.SQL_ERROR;
        }
    }
}
