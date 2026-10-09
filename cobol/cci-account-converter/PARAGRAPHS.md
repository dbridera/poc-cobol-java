# cci-account-converter — Guía de párrafos (qué hace cada parte)

Explicación de negocio, párrafo por párrafo, del conversor de cuentas CCI ↔ cuenta comercial
del BCP. La lee `tools/render-traceability.py` y la muestra en el visor COBOL ↔ Java
(`traceability.html`) debajo de cada párrafo y en la barra del medio al seleccionarlo. La fuente
de verdad sigue siendo el COBOL (regla 3); la columna *Spec* apunta a la sección de
`specs/cci-account-converter.md` donde está el contrato exacto.

Qué es un CCI: el Código de Cuenta Interbancario peruano, 20 dígitos que identifican una cuenta
para transferencias entre bancos: banco (3) + oficina (3) + tipo de producto (1) + número de
cuenta (8) + moneda (1) + dígitos de control del banco (2) + dos dígitos de chequeo
interbancarios (1 + 1). El programa convierte en las dos direcciones: de un CCI recibido a la
cuenta interna (IMPACS / SAVING / CTS) donde el core puede contabilizar, o de una cuenta
interna al CCI que se envía a otro banco, calculando los dos dígitos de chequeo módulo 10.

Formato (lo parsea el renderer): un título `## PROGRAMA[, PROGRAMA…] — qué hace el programa`,
un párrafo de resumen, y una tabla `| Párrafo | Qué hace | Spec |`.

---

## DRIVER-BCTITSCV — Lanzador del conversor (agregado, reemplaza a CICS)

En el banco este programa corre dentro de CICS y recibe sus parámetros en un área de
comunicación de 200 bytes. Para correrlo solo, este lanzador lee `requests.dat` línea por
línea, parte cada línea en seis campos separados por espacios (dirección de conversión, código
de interfaz, familia, producto, subproducto y la cuenta de 20 caracteres), los carga en esa
misma área, llama a BCTITSCV y muestra el resultado en un bloque de cinco líneas más `---`.
No escribe archivos ni base de datos; el código de salida es 0 salvo que no pueda abrir la
entrada (1).

| Párrafo | Qué hace | Spec |
|---|---|---|
| MAIN-DRIVER | Abre el archivo de solicitudes (si falla muestra "ERR OPEN requests.dat" y termina con código 1). Lee la primera línea y, hasta el fin del archivo, repite: llamar al conversor, mostrar el resultado, leer la siguiente. Cierra y termina con código 0, haya o no errores de conversión. | §3, §7.1 |
| READ-INPUT | Lee la siguiente línea de solicitudes; al fin de archivo marca la bandera. | §2.1 |
| CALL-BCTITSCV | Pone en blanco los 200 bytes del área de parámetros (para que no quede nada de la solicitud anterior), separa los seis campos de la línea y llama a BCTITSCV. Ojo: borra el área de parámetros, pero no la memoria de trabajo interna de BCTITSCV, que persiste entre llamadas (ver 2000-CALCULA-DIGCHEQ-BANOFI). | §2.1, §8 |
| DISPLAY-RESULT | Muestra "RC:" (código de retorno, 2 caracteres), "MSG:" (mensaje sin espacios finales, vacío si todo fue bien), "FAM-RET:" (familia detectada, 3), "BCP-EDIT:" (vista de cuenta comercial, 20) y "CUENTA-ITE:" (CCI generado, 20), siempre al ancho completo con espacios, y una línea `---`. | §7 |

---

## BCTITSCV — Convertir CCI ↔ cuenta comercial (programa real del BCP, feb. 2015)

Recibe una solicitud en el área de parámetros, valida la familia de cuenta (004/007 IMPACS,
005 SAVING, 009 CTS), que el producto sea numérico y que la cuenta tenga dígitos donde
corresponde, y después, según el indicador de dirección: `1` descompone el CCI recibido en
oficina, número, moneda y dígitos de control del banco (CCI → BCP); `2` arma el CCI a partir
de la cuenta comercial, fijando el banco `002` (BCP), el tipo de producto y los dos dígitos de
chequeo módulo 10 (BCP → CCI). Todo error devuelve código 99 y un mensaje fijo; éxito es 00.
El único cambio respecto del original fueron cuatro retiros de llamadas CICS (ver README §1);
la lógica de negocio está intacta. Aritmética de los dígitos de chequeo (ADR-11 y ADR-12):
la "decena" de la suma sale de dividir por 10 y guardar en un campo sin decimales, o sea
truncando hacia abajo (42 / 10 → 4, nunca 5); y cuando la fórmula da exactamente 10 se guarda
en un campo de un solo dígito, que se queda con el 0. Ese recorte no es un desborde: es la
forma en que el COBOL calcula "módulo 10", y el Java lo reproduce a propósito.

| Párrafo | Qué hace | Spec |
|---|---|---|
| 0100-INICIO | Punto de entrada: solo pasa a recibir los parámetros. En el original aquí se registraba el manejador de caídas de CICS (retirado, adaptación 2). | §3 |
| 0120-RECIBE-COMMAREA | No hace nada. En el original comprobaba que CICS hubiera pasado el área de parámetros y, si no, devolvía 99 "ERROR AL RECIBIR COMMAREA"; corriendo fuera de CICS esa rama es inalcanzable (adaptación 3). | §3, §9 |
| 0500-EVALUA-PROCESO | Copia los 20 caracteres de la cuenta recibida a la vista de salida "cuenta comercial" (por eso BCP-EDIT siempre devuelve, como mínimo, lo que entró). Ejecuta las validaciones (si una falla, el programa termina ahí mismo). Luego, según el indicador: `1` → descomponer el CCI; `2` → armar el CCI con dígitos de chequeo; cualquier otro valor → código 99 "COD. CONV.NO VALIDO" y termina. | §3, §4 regla 4 |
| 0600-CALCULA-CTA-COMERCIAL | CCI → cuenta comercial. Mira el séptimo carácter del CCI (tipo de producto): `0` = IMPACS: familia devuelta 004, oficina, número de cuenta **sin su primer dígito** (7 de los 8), moneda y los dos dígitos de control del banco a la vista IMPACS. `1` = SAVING (familia 005) y `2` = CTS (familia 009): lo mismo a la vista SAVING/CTS pero con los 8 dígitos del número. Cualquier otro tipo: no hace nada, en silencio, y el retorno sigue siendo 00 con familia en blanco. No toca el campo CUENTA-ITE (queda en blanco). | §6 |
| 1000-VALIDA-ARGUMENTOS | Pone código 00 y aplica tres reglas en orden; la primera que falla pone 99, deja el mensaje y **termina el programa entero** (no sigue a los párrafos siguientes). 1) La familia debe ser 004/007 (IMPACS) o 005/009 (SAVING/CTS): si no, "COD. SIST.NO VALIDO". 2) El código de producto debe ser numérico: si no, "ACCT.TYPE NO NUMRIC" (sic). 3) Oficina, número, moneda y dígitos de control deben ser numéricos en la vista que corresponde a la familia (caracteres 8–20 para IMPACS, 7–20 para SAVING/CTS): si no, "DATOS NO NUMERICOS " (con espacio final). Se valida igual en las dos direcciones. | §4 |
| 1000-FINVALIDA | Fin del tramo de validación (párrafo vacío, destino del PERFORM … THRU). | §4 |
| 1500-CALCULA-CHEQUEO-INT | Cuenta comercial → CCI. Arma los primeros 18 caracteres: banco `002` fijo (BCP); si la familia es IMPACS (004/007): producto `0`, oficina, número de 7 dígitos con un `0` adelante para completar 8, moneda y dígitos de control de la vista IMPACS; si es SAVING/CTS: producto `1`, o `2` cuando la familia es 009 (CTS), y los campos de la vista SAVING/CTS (número ya de 8). Después calcula el primer dígito de chequeo sobre banco+oficina (6 dígitos), pone en cero el acumulador y calcula el segundo sobre producto+número+moneda+control (12 dígitos). | §5, §5.1 |
| 1500-FININT | Fin del tramo de armado del CCI (párrafo vacío, destino del PERFORM … THRU). | §5 |
| 2000-CALCULA-DIGCHEQ-BANOFI | Primer dígito de chequeo (carácter 19 del CCI), módulo 10 sobre los 6 dígitos de banco+oficina: suma los dígitos de las posiciones impares tal cual y los de las pares multiplicados por 2 (si el doble tiene dos cifras, se suman sus cifras: 14 → 5); dígito = lo que falta para llegar a la decena siguiente (suma 8 → 2; suma 42 → 8; suma múltiplo de 10 → 0). **Ojo, el COBOL difiere de la spec §5.2**: aquí el acumulador no se pone en cero antes de sumar (solo se confía en que arranca en cero); como la memoria de trabajo persiste entre llamadas, a partir del segundo pedido BCP→CCI de una misma corrida este dígito sale mal (verificado con el binario: el mismo pedido da `…28` la primera vez y `…08` la segunda). En CICS cada llamada arrancaba con memoria limpia, por eso no se notaba. | §5.2, §5.3 |
| 3000-CALCULA-DIGCHEQ-CUENTA | Segundo dígito de chequeo (carácter 20 del CCI), mismo algoritmo módulo 10 sobre los 12 dígitos de producto+número+moneda+control. Este sí arranca con el acumulador en cero (lo pone 1500 justo antes). Ejemplo verificado: `112345678112` → suma 42 → dígito 8. | §5.2, §5.4 |
| 2500-SUMA-NUM-IMP | Un paso de la suma para banco+oficina, posiciones impares (1, 3, 5): toma el dígito × 1, lo parte en decena y unidad y suma ambas al acumulador. | §5.2 |
| 2550-SUMA-NUM-PAR | Un paso de la suma para banco+oficina, posiciones pares (2, 4, 6): dígito × 2 (hasta 18), partido en decena y unidad, sumadas al acumulador. | §5.2 |
| 3500-SUMA-NUM-IMP2 | Igual que 2500 pero sobre los 12 dígitos de la cuenta, posiciones impares (1, 3, …, 11). | §5.2 |
| 3550-SUMA-NUM-PAR2 | Igual que 2550 pero sobre los 12 dígitos de la cuenta, posiciones pares (2, 4, …, 12). | §5.2 |
| 3000-FINAL | Devuelve el control al que llamó (en el original era el retorno a CICS, adaptación 4). Solo se llega aquí cuando no hubo error: las validaciones fallidas y el indicador inválido terminan el programa antes. Comparte el prefijo 3000 con el cálculo del segundo dígito; son dos párrafos distintos y se conservan ambos. | §3 |
