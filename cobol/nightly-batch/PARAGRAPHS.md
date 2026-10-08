# nightly-batch — Guía de párrafos (qué hace cada parte)

Explicación de negocio, párrafo por párrafo, de los programas del cierre nocturno. La lee
`tools/render-traceability.py` y la muestra en el visor COBOL ↔ Java (`traceability.html`)
debajo de cada párrafo y en la barra del medio al seleccionarlo. La fuente de verdad sigue
siendo el COBOL (regla 3); la columna *Spec* apunta a la sección de `specs/nightly-batch.md`
donde está el contrato exacto.

Formato (lo parsea el renderer): un título `## PROGRAMA[, PROGRAMA…] — qué hace el programa`,
un párrafo de resumen, y una tabla `| Párrafo | Qué hace | Spec |`.

---

## CBTRN02C — Contabilizar las transacciones del día (paso 1, POSTTRAN)

Lee una por una las transacciones de tarjeta del día. Para cada una verifica que la tarjeta
exista, que su cuenta exista, que no exceda el límite de crédito y que la tarjeta no esté
vencida. Si pasa, la contabiliza: actualiza el saldo y los acumulados de ciclo de la cuenta,
el saldo por categoría, y la guarda en el maestro de transacciones. Si no pasa, la escribe en
el archivo de rechazos con un código de motivo. Termina con código 4 si hubo algún rechazo.

| Párrafo | Qué hace | Spec |
|---|---|---|
| 0000-DALYTRAN-OPEN | Abre el archivo de transacciones del día (entrada). Si falla, muestra el estado del archivo y cae. | §4.2 |
| 0100-TRANFILE-OPEN | Abre el maestro de transacciones para escribirlo desde cero (OPEN OUTPUT: el maestro de la noche se crea vacío). | §4.2, §8 |
| 0200-XREFFILE-OPEN | Abre la tabla tarjeta → cliente/cuenta (solo lectura). | §4.2 |
| 0300-DALYREJS-OPEN | Abre el archivo de rechazos para escribirlo desde cero. | §4.2 |
| 0400-ACCTFILE-OPEN | Abre el archivo de cuentas en modo lectura y actualización (los saldos se reescriben en el lugar). | §4.2, §8 |
| 0500-TCATBALF-OPEN | Abre el archivo de saldos por cuenta y categoría en modo lectura y actualización. | §4.2 |
| 1000-DALYTRAN-GET-NEXT | Lee la siguiente transacción del día. Estado 10 = fin de archivo; cualquier otro error cae. | §4.2 |
| 1500-VALIDATE-TRAN | Encadena las validaciones: primero la tarjeta (1500-A); si existe, la cuenta y sus reglas (1500-B). Un solo campo de motivo: la última validación que falla es la que queda. | §5 |
| 1500-A-LOOKUP-XREF | Busca la tarjeta en la tabla de referencia cruzada. Si no está: motivo 100 "INVALID CARD NUMBER FOUND". | §5 regla 1 |
| 1500-B-LOOKUP-ACCT | Busca la cuenta de esa tarjeta (si no está: motivo 101). Calcula el saldo temporal = crédito del ciclo − débito del ciclo (que se guarda negativo) + importe; si supera el límite: motivo 102. Si la fecha de vencimiento es anterior a la fecha de la transacción: motivo 103, que pisa al 102. El saldo temporal tiene un dígito menos que los acumulados y se trunca (defecto D6). | §5 reglas 2-4, §6.3 |
| 2000-POST-TRANSACTION | Copia los campos de la transacción del día al registro del maestro, le pone la fecha/hora de proceso y ejecuta las tres actualizaciones: saldo por categoría, cuenta, maestro. | §4.2 |
| 2500-WRITE-REJECT-REC | Escribe la transacción rechazada tal cual, más el motivo (4 dígitos) y su texto (76 caracteres). | §4.2, §7.3 |
| 2700-UPDATE-TCATBAL | Busca el saldo por cuenta + tipo + categoría. Si no existe lo crea (2700-A, con mensaje "Creating."); si existe lo actualiza (2700-B). | §4.2 |
| 2700-A-CREATE-TCATBAL-REC | Arma un registro nuevo de saldo por categoría con el importe de la transacción y lo graba. El relleno (FILLER) conserva lo que había en memoria. | §4.2 |
| 2700-B-UPDATE-TCATBAL-REC | Suma el importe al saldo por categoría y reescribe el registro. | §4.2 |
| 2800-UPDATE-ACCOUNT-REC | Suma el importe al saldo de la cuenta; si es positivo lo acumula en crédito del ciclo, si es negativo en débito del ciclo (como número negativo). Reescribe la cuenta. Sin control de desborde: un saldo que no entra pierde los dígitos de la izquierda. | §4.2, §6.2, §6.3 |
| 2900-WRITE-TRANSACTION-FILE | Graba la transacción en el maestro (clave: id de transacción). Un id repetido haría caer el programa. | §4.2 |
| 9000-DALYTRAN-CLOSE | Cierra el archivo de transacciones del día. | §4.2 |
| 9100-TRANFILE-CLOSE | Cierra el maestro de transacciones. | §4.2 |
| 9200-XREFFILE-CLOSE | Cierra la tabla de referencia cruzada. | §4.2 |
| 9300-DALYREJS-CLOSE | Cierra el archivo de rechazos (muestra el estado del archivo equivocado si falla, defecto D4). | §4.2 |
| 9400-ACCTFILE-CLOSE | Cierra el archivo de cuentas. | §4.2 |
| 9500-TCATBALF-CLOSE | Cierra el archivo de saldos por categoría. | §4.2 |
| Z-GET-DB2-FORMAT-TIMESTAMP | Toma la fecha y hora del sistema y la escribe en el formato de DB2 (AAAA-MM-DD-hh.mm.ss.cc0000). En el banco de pruebas el reloj está fijado, por eso todas las transacciones llevan la misma hora. | §6.4 |
| 9910-DISPLAY-IO-STATUS | Muestra el estado de archivo de la última operación fallida ("FILE STATUS IS: NNNN00xx"). Solo se ejecuta en una caída. | §7.1 |
| 9999-ABEND-PROGRAM | Muestra "ABENDING PROGRAM" y llama al servicio de caída del mainframe (CEE3ABD): el paso termina con código 12. | §4.2 |

---

## CBACT04C — Cobrar el interés mensual (paso 2, INTCALC)

Recorre los saldos por cuenta y categoría en orden de cuenta. Para cada saldo busca la tasa
anual del grupo de la cuenta (o la del grupo DEFAULT si no la hay), calcula el interés del
mes truncado al centavo, lo acumula por cuenta y escribe una transacción de interés. Al
cambiar de cuenta, suma el interés acumulado al saldo de la cuenta anterior y reinicia sus
acumulados de ciclo. Por un error del programa original, la última cuenta nunca recibe esa
actualización (defecto D1).

| Párrafo | Qué hace | Spec |
|---|---|---|
| 0000-TCATBALF-OPEN | Abre los saldos por categoría para recorrerlos en orden de clave (cuenta, tipo, categoría). | §4.4 |
| 0100-XREFFILE-OPEN | Abre la tabla de referencia cruzada; aquí se lee por la clave alternativa (número de cuenta) para obtener la tarjeta. | §4.4 |
| 0200-DISCGRP-OPEN | Abre la tabla de tasas por grupo de divulgación (grupo + tipo + categoría → tasa anual). | §4.4 |
| 0300-ACCTFILE-OPEN | Abre el archivo de cuentas en lectura y actualización. | §4.4 |
| 0400-TRANFILE-OPEN | Abre el archivo de salida de transacciones de interés (secuencial). | §4.4 |
| 1000-TCATBALF-GET-NEXT | Lee el siguiente saldo por categoría. Estado 10 = fin. | §4.4 |
| 1050-UPDATE-ACCOUNT | Suma el interés acumulado al saldo de la cuenta, pone en cero los acumulados de ciclo y reescribe la cuenta. Se ejecuta al cambiar de cuenta, nunca para la última (D1). | §4.4 |
| 1100-GET-ACCT-DATA | Lee la cuenta del saldo en curso. Si no existe: mensaje y caída. | §4.4 |
| 1110-GET-XREF-DATA | Busca por número de cuenta (clave alternativa) la tarjeta asociada, que irá en la transacción de interés. | §4.4 |
| 1200-GET-INTEREST-RATE | Busca la tasa con (grupo de la cuenta, tipo, categoría). Si no está (estado 23) avisa y prueba con el grupo DEFAULT (1200-A). | §5.3 |
| 1200-A-GET-DEFAULT-INT-RATE | Busca la tasa del grupo DEFAULT para ese tipo y categoría. Si tampoco está: mensaje de error, estado de archivo y caída (caso de prueba 06). | §5.3 |
| 1300-COMPUTE-INTEREST | Interés del mes = saldo × tasa anual / 1200, sin redondeo: se trunca hacia cero al centavo (0.09575 → 0.09, −11.4875 → −11.48). Lo acumula para la cuenta y escribe la transacción (1300-B). Solo se ejecuta si la tasa no es cero. | §6.1 |
| 1300-B-WRITE-TX | Arma la transacción de interés: id = fecha del PARM + correlativo, tipo 01, categoría 0005, origen "System", descripción "Int. for a/c" + cuenta, importe = interés, tarjeta de la cuenta, fecha/hora de proceso. La graba. | §4.4, §7.3 |
| 1400-COMPUTE-FEES | Vacío en el programa original ("a implementar"). Se mantiene para conservar el orden de ejecución. | §4.4 |
| 9000-TCATBALF-CLOSE | Cierra los saldos por categoría. | §4.4 |
| 9100-XREFFILE-CLOSE | Cierra la referencia cruzada. | §4.4 |
| 9200-DISCGRP-CLOSE | Cierra la tabla de tasas. | §4.4 |
| 9300-ACCTFILE-CLOSE | Cierra las cuentas. | §4.4 |
| 9400-TRANFILE-CLOSE | Cierra el archivo de transacciones de interés. | §4.4 |
| Z-GET-DB2-FORMAT-TIMESTAMP | Fecha y hora del sistema en formato DB2 (reloj fijado en el banco de pruebas). | §6.4 |
| 9910-DISPLAY-IO-STATUS | Muestra el estado de archivo de la operación fallida. | §7.1 |
| 9999-ABEND-PROGRAM | "ABENDING PROGRAM" + llamada a CEE3ABD: el paso termina con código 12. | §4.4 |

---

## CBTRN03C — Imprimir el reporte diario de transacciones (paso 4, TRANREPT)

Recibe las transacciones del rango de fechas, ya ordenadas por tarjeta, y arma un reporte de
133 columnas: encabezado con el rango, una línea por transacción con las descripciones de
tipo y categoría, total por cuenta cuando cambia la tarjeta, total por página cada 20 líneas
y total general al final. Por un error del programa original, al llegar al fin de archivo
vuelve a sumar el último importe: el total general queda inflado (defecto D2).

| Párrafo | Qué hace | Spec |
|---|---|---|
| 0000-TRANFILE-OPEN | Abre el archivo de transacciones a reportar (secuencial, ya filtrado y ordenado por el paso anterior). | §4.6 |
| 0100-REPTFILE-OPEN | Abre el archivo del reporte para escribirlo desde cero. | §4.6 |
| 0200-CARDXREF-OPEN | Abre la referencia cruzada para obtener la cuenta de cada tarjeta. | §4.6 |
| 0300-TRANTYPE-OPEN | Abre la tabla de tipos de transacción (código → descripción). | §4.6 |
| 0400-TRANCATG-OPEN | Abre la tabla de categorías (tipo + categoría → descripción). | §4.6 |
| 0500-DATEPARM-OPEN | Abre el archivo de parámetros con el rango de fechas. | §4.6 |
| 0550-DATEPARM-READ | Lee el rango de fechas y lo muestra ("Reporting from … to …"). | §4.6 |
| 1000-TRANFILE-GET-NEXT | Lee la siguiente transacción. Al fin de archivo el registro en memoria conserva la última leída, y la rama de fin de archivo la vuelve a sumar (D2). | §4.6 |
| 1100-WRITE-TRANSACTION-REPORT | Para cada transacción: si es la primera, escribe los encabezados; si el contador de líneas es múltiplo de 20, cierra la página (total de página + encabezados); suma el importe al total de página y al de cuenta; escribe la línea de detalle. | §7.4 |
| 1110-WRITE-PAGE-TOTALS | Escribe la línea "Page Total" con el total de página, lo pasa al total general, lo reinicia y escribe una línea de guiones. | §7.4 |
| 1120-WRITE-ACCOUNT-TOTALS | Escribe la línea "Account Total" de la tarjeta que termina, reinicia el total de cuenta y escribe una línea de guiones. No se escribe para la última tarjeta (D2). | §7.4 |
| 1110-WRITE-GRAND-TOTALS | Escribe la línea "Grand Total". | §7.4 |
| 1120-WRITE-HEADERS | Escribe las cuatro líneas de encabezado: nombre y rango de fechas, línea en blanco, títulos de columnas, guiones. | §7.4 |
| 1111-WRITE-REPORT-REC | Escribe una línea de 133 caracteres en el reporte; si falla, cae. | §7.4 |
| 1120-WRITE-DETAIL | Arma la línea de detalle: id, cuenta, tipo y su descripción (15 caracteres), categoría y su descripción (29), origen, importe editado con signo y separadores de miles. | §7.4 |
| 1500-A-LOOKUP-XREF | Busca la cuenta de la tarjeta en curso; si la tarjeta no existe, cae. | §4.6 |
| 1500-B-LOOKUP-TRANTYPE | Busca la descripción del tipo de transacción; si no existe, cae. | §4.6 |
| 1500-C-LOOKUP-TRANCATG | Busca la descripción de la categoría; si no existe, cae. | §4.6 |
| 9000-TRANFILE-CLOSE | Cierra el archivo de transacciones. | §4.6 |
| 9100-REPTFILE-CLOSE | Cierra el reporte. | §4.6 |
| 9200-CARDXREF-CLOSE | Cierra la referencia cruzada. | §4.6 |
| 9300-TRANTYPE-CLOSE | Cierra la tabla de tipos. | §4.6 |
| 9400-TRANCATG-CLOSE | Cierra la tabla de categorías. | §4.6 |
| 9500-DATEPARM-CLOSE | Cierra el archivo de parámetros. | §4.6 |
| 9910-DISPLAY-IO-STATUS | Muestra el estado de archivo de la operación fallida. | §7.1 |
| 9999-ABEND-PROGRAM | "ABENDING PROGRAM" + llamada a CEE3ABD: código 12. | §4.6 |
| L$0 | No es un párrafo del programa: es la etiqueta que el compilador genera para la sentencia que sigue al bucle principal (destino del NEXT SENTENCE de la línea 177). GnuCOBOL la registra una vez al terminar el bucle y el Java la emite igual. | §4.6 |

---

## INTCALC — Arranque del paso de intereses (agregado, no es de CardDemo)

En el mainframe el JCL le pasa al programa de intereses la fecha de proceso como PARM.
GnuCOBOL no lo hace, así que este programa chico toma la fecha de la variable de entorno
PARM, arma la misma estructura (largo + texto) y llama a CBACT04C sin modificarlo.

| Párrafo | Qué hace | Spec |
|---|---|---|

## CEE3ABD — Caída controlada (agregado, reemplaza un servicio del mainframe)

Reemplazo del servicio de Language Environment que termina un programa con un código de
abend. Muestra "CEE3ABD: USER ABEND U+000000999" y detiene el paso con código 12. Lo
llaman los tres programas de negocio desde su párrafo 9999-ABEND-PROGRAM.

| Párrafo | Qué hace | Spec |
|---|---|---|

## CBSORT01 — Ordenar y unir las transacciones (paso 3, COMBTRAN; agregado)

Reemplaza el paso DFSORT de COMBTRAN.jcl: une el respaldo de las transacciones contabilizadas
con las transacciones de interés, ordena por id de transacción y escribe el archivo que
después recarga el maestro. No tiene párrafos con nombre.

| Párrafo | Qué hace | Spec |
|---|---|---|

## CBSORT02 — Seleccionar y ordenar para el reporte (paso 4, TRANREPT; agregado)

Reemplaza el paso DFSORT de TRANREPT.jcl: lee el rango de fechas, se queda con las
transacciones cuya fecha de proceso está en el rango y las ordena por número de tarjeta
(y, como desempate documentado, por id de transacción).

| Párrafo | Qué hace | Spec |
|---|---|---|
| MAIN | Lee el rango de fechas del archivo de parámetros, lanza el ordenamiento con SELECT-RECORDS como procedimiento de entrada y muestra cuántas transacciones seleccionó de cuántas leídas. | §4.6 |
| SELECT-RECORDS | Lee las transacciones y entrega al ordenamiento solo las que tienen fecha de proceso dentro del rango. | §4.6 |

## LOAD-ACCTFILE, LOAD-XREFFILE, LOAD-TCATBALF, LOAD-DISCGRP, LOAD-TRANTYPE, LOAD-TRANCATG, LOAD-TRANSACT — Cargar un archivo indexado (generados)

Reemplazan el utilitario IDCAMS REPRO del mainframe: leen un archivo secuencial de
longitud fija y lo cargan en un archivo indexado (el análogo de VSAM) desde cero. Los genera
`tools/gen-ksds-io.py` a partir de `job.json`.

| Párrafo | Qué hace | Spec |
|---|---|---|
| MAIN | Abre la entrada secuencial y el archivo indexado (vacío), graba cada registro (una clave repetida cuenta como error, código 8) y muestra cuántos cargó. | §4.1 |

## UNLD-TRANSACT, UNLD-ACCTFILE, UNLD-TCATBALF — Descargar un archivo indexado (generados)

El REPRO inverso: recorren el archivo indexado en orden de clave y lo escriben en un archivo
secuencial. Así los archivos que el job actualiza en el lugar (cuentas, saldos por categoría)
se pueden comparar byte a byte, y así se hace el respaldo del maestro entre pasos.

| Párrafo | Qué hace | Spec |
|---|---|---|
| MAIN | Lee el archivo indexado de principio a fin en orden de clave, escribe cada registro y muestra cuántos descargó. | §4.3, §4.7 |
