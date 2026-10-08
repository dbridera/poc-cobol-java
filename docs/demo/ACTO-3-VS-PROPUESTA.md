# Acto 3 "Cierre nocturno" — qué se construyó frente a la propuesta

Para Esteban. Resumen de cómo quedó implementado el acto 3 del handoff *"Un día en el Banco"* (2026-10-01), qué se respetó tal cual, qué se cambió a propósito y qué sigue pendiente. Todo lo que figura como "hecho" está en la rama `feature/nightly-batch` y se verifica con un comando (sección 5).

---

## 1. Decisiones que se apartan de la propuesta

| Propuesta | Lo construido | Por qué |
|---|---|---|
| Mini core de **cuentas de depósito** escrito para la demo | **AWS CardDemo**, un core de **tarjetas** público (Apache-2.0), con los tres programas batch **sin tocar una línea** | Si escribimos el COBOL nosotros, la audiencia técnica pregunta "¿quién escribió el COBOL?" y la credibilidad se cae. CardDemo es conocido en el mundo de modernización y trae defectos reales de legado (sección 4). La narrativa "un día en el banco" se mantiene; cambia el producto. |
| Archivo EBCDIC **con COMP-3** | Datos con **signo overpunch zonado** (`{A-I}J-R`, el formato real de los dumps EBCDIC→ASCII); COMP-3 solo en contadores del reporte | Los layouts de CardDemo no usan COMP-3 en archivo. Hay que decirlo en escena: "formatos numéricos propios del mainframe", no "packed decimal". COMP-3 en archivo existe en otros programas de CardDemo (statements, online) y queda para un acto futuro. |
| Cursor DB2 en el batch | No incluido | El batch de CardDemo es 100 % VSAM. El cursor DB2 sigue cubierto por el shim SQLite de los módulos 1A/1B; extenderlo con cursores queda como pendiente. |
| JCL guardado como documento + runner shell | El JCL original se guarda en `cobol/nightly-batch/original/jcl/`; el runner es un **manifiesto `job.json`** que leen tanto el lado COBOL (`tools/run-job.py`) como el job de Spring Batch | Un solo origen de verdad para orden de pasos, mapeo DD→dataset, códigos de retorno y reinicio: no puede haber deriva entre los dos lados (ADR-14). |

---

## 2. Aristas COBOL del acto 3 — cobertura

| Arista de la propuesta | Estado | Dónde se ve |
|---|---|---|
| Job de 4 steps: extraer → ordenar → intereses → reporte | **Hecho** como POSTTRAN → INTCALC → COMBTRAN (sort + recarga) → TRANREPT (unload + sort + reporte); 16 pasos en el manifiesto contando cargas y capturas | `cobol/nightly-batch/job.json`, `README.md` §2 |
| VSAM KSDS | **Hecho**: siete KSDS (BDB en GnuCOBOL), dos de ellos **actualizados in situ** (REWRITE) y diffeados vía unload | `README.md` §4, ADR-14 |
| COMPUTE ROUNDED | **Hecho en su variante real**: el COMPUTE de interés **no** lleva ROUNDED y trunca hacia cero (0.09575 → 0.09, −11.4875 → −11.48); el control negativo cambia DOWN por HALF_UP y el semáforo se pone rojo en cuenta y centavo exactos | fixture `03-numeric-boundaries`, ADR-16 |
| ON SIZE ERROR | **Hecho en su variante real**: no hay ON SIZE ERROR y el ADD desborda silenciosamente (9999999999.00 + 5.00 = 4.00); un total de ciclo de 10 dígitos se trunca al validar límite y deja pasar una compra | fixture 03, spec §6.3 |
| SORT | **Hecho**: dos pasos DFSORT reemplazados por programas COBOL SORT (merge por TRAN-ID; filtro por fecha + orden por tarjeta) | `src/CBSORT01.cbl`, `src/CBSORT02.cbl` |
| Checkpoint / restart | **Hecho**: fixture `05-restart` mata el job después del paso 2 de 4 y lo reanuda; los bytes finales son idénticos a la corrida sin corte, en COBOL y en Java (Spring Batch `JobRepository` sobre H2) | `demo-commands.sh module-3` muestra el log |
| Header/trailer con totales de control | **Hecho**: reporte de 133 columnas con totales por cuenta, por página y general | `tranrept.dat` en cada golden master |
| Return codes / COND= | **Hecho**: RC 4 si hubo rechazos, RC 12 en abend, pasos posteriores `NOT RUN`, pasos de captura `always`; exit code = MAXRC | fixture `06-abend-discgrp`, ADR-14 |
| EBCDIC | **Parcial**: signos overpunch de punta a punta con `-fsign=EBCDIC`; los archivos EBCDIC reales de CardDemo se decodifican (cp037) y se comprueban contra los fixtures ASCII; `CODE-SET IS EBCDIC` verificado en GnuCOBOL. Falta un fixture cuya **entrada** sea EBCDIC en toda la corrida | SCALING.md §4 |
| COMP-3 | **Parcial**: solo contadores de working storage (`WS-LINE-COUNTER`, `WS-PAGE-SIZE`) | ver sección 1 |
| Cursor DB2 | **No** | ver sección 1 |

---

## 3. Los momentos clave, tal como quedaron

- **Restart.** `./tools/run-job.sh nightly-batch 05-restart --verbose` imprime los pasos en vivo: `ABEND AFTER INTCALC (injected)`, segunda corrida con `SKIPPED (COMPLETED IN RUN 1)`, `END MAXRC=0004`. El checker exige que las salidas sean idénticas a `01-happy-small`.
- **Control negativo.** `./tools/demo-commands.sh negative-control` cambia un token (`RoundingMode.DOWN` → `HALF_UP`), corre el fixture 03 y el diff marca `acctfile.unl` registro 1 columna 24, byte `E` contra `F`: un centavo. Luego revierte y vuelve a verde. Hay un segundo control, documentado: "arreglar" el bug del último cliente pone rojo el fixture 01.
- **Bug fiel (nuevo, no estaba en la propuesta).** CBACT04C nunca actualiza la última cuenta (`ELSE` inalcanzable, línea 219-221) y CBTRN03C infla el total general con el último importe. Se replican, se citan en el Java y van en el checklist del SME. Mensaje para la audiencia: *traducimos lo que el banco corre, con sus bugs, y le decimos dónde están.*
- **Opcional de rendimiento (100.000 cuentas, 8 particiones).** No hecho. El fixture completo son 50 cuentas y 300 transacciones; la comparación sería Java contra Java, como dice la sección 5 de tu handoff.

---

Agregado después de la nota original: la **traza de párrafos** (cada párrafo que GnuCOBOL ejecuta; el Java emite la misma traza y entra en el diff), la **matriz de cobertura generada** desde esas trazas (`cobol/nightly-batch/COVERAGE.md`, 82/86 párrafos), el **diff por campo** ("cuenta 1: `ACCT-CURR-BAL` COBOL 201.75, Java 201.76") y el **visor lado a lado** COBOL ↔ Java (`cobol/nightly-batch/traceability.html`). `./tools/demo-commands.sh module-3` los muestra como tercer momento.

## 4. Lo que hay que decir de frente

1. Los programas son públicos y verbatim; el runtime (JCL, IDCAMS, DFSORT, Language Environment) se reemplaza por stand-ins pequeños y documentados.
2. El restart prueba "misma salida final", no "mismo mecanismo de checkpoint".
3. No se modelan GDG, `COND=` selectivo, ni una corrida con entrada EBCDIC completa.
4. GnuCOBOL en x86 no es baseline de rendimiento (tu sección 5 queda intacta).

---

## 5. Cómo verlo

```bash
./tools/demo-commands.sh module-3           # acto 3 completo, con los dos momentos narrados (~2 min)
./tools/demo-commands.sh negative-control   # semáforo rojo → verde (~1 min)
./tools/demo-commands.sh all                # los cinco módulos + conformidad + prueba: 15/15 byte a byte
```

Documentos: [`cobol/nightly-batch/README.md`](../../cobol/nightly-batch/README.md) (proveniencia, job, fixtures, registro de defectos, spike log), [`specs/nightly-batch.md`](../../specs/nightly-batch.md) (contrato byte a byte y checklist SME), [`DEMO.md`](./DEMO.md) §3 (guion y Q&A), [`MODULE-3-REPORT.md`](../methodology/MODULE-3-REPORT.md) (informe de sesión), ADR-13 a ADR-16 en [`DECISIONS.md`](../methodology/DECISIONS.md).

---

## 6. Pendientes que siguen siendo tuyos

- Fecha de la demo y orden de construcción de los actos 1, 2 y 4 (la recomendación sigue siendo: acto 1 desde el programa de pago de factura de CardDemo; acto 2 con su módulo MQ de autorizaciones más el convertidor CCI; acto 4 con el programa de statements, 924 líneas con GO TO reales).
- Tablero web que lea `validation/reports/*.json`: cada entrada trae ahora `summary` con registros y bytes comparados, pensado para la cifra "N registros comparados, 0 bytes distintos".
- Slide de preguntas difíciles: las dos nuevas respuestas (JCL/restart y "¿tradujeron un bug a propósito?") están redactadas en `DEMO.md` §6.
