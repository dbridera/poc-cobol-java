# add-policy-facade — Guía de párrafos (qué hace cada parte)

Explicación de negocio, párrafo por párrafo, del módulo 1A: la fachada de alta de póliza que
valida el pedido y delega la inserción a otro programa. La lee `tools/render-traceability.py`
y la muestra en el visor COBOL ↔ Java (`traceability.html`) debajo de cada párrafo y en la
barra del medio al seleccionarlo. La fuente de verdad sigue siendo el COBOL (regla 3); la
columna *Spec* apunta a la sección de `specs/add-policy-facade.md` donde está el contrato
exacto.

El visor muestra cuatro programas: ADDPFCD (el recorte ejecutable de la fachada, que lleva
adentro el programa anidado ADDPOLDB-INSERT), LGAPOL01 (la fachada original de IBM GenApp),
LGAPDB01 (el programa original al que la fachada enlaza por CICS LINK) y ADDPOLDB (el recorte
del módulo 1B, que el Java de este módulo cita porque la inserción es el mismo código). La
cadena original "fachada → CICS LINK → programa de base" se traduce a dos servicios Spring,
uno inyectado en el otro (ADR-10).

Formato (lo parsea el renderer): un título `## PROGRAMA[, PROGRAMA…] — qué hace el programa`,
un párrafo de resumen, y una tabla `| Párrafo | Qué hace | Spec |`.

---

## ADDPFCD — Fachada de alta de pólizas: valida y delega la inserción (recorte ejecutable, módulo 1A)

Hace lo mismo que el módulo 1B visto desde afuera (misma entrada, misma tabla, misma salida),
pero con dos programas en vez de uno: la fachada lee cada solicitud, la valida (el número de
póliza no puede ser 0) y llama al programa anidado ADDPOLDB-INSERT, que es el que arma y
ejecuta el INSERT en POLICY. Ese CALL es el equivalente ejecutable del `EXEC CICS LINK
PROGRAM("LGAPDB01")` del original. Códigos por solicitud: OK si se insertó, `RC=98` si la
fachada la rechazó, `RC=+0000000001` si la base la rechazó (por ejemplo, número de póliza
repetido). Nunca se cae por un rechazo; al final vuelca la tabla a `out/policy.csv` y muestra
`PROCESSED / INSERTED / REJECTED`, código de salida 0. En Java: `PolicyFacadeService` llama por
inyección a `PolicyInsertService` (ADR-10), y este último inserta con `persist` + `flush` en
una transacción propia (ADR-9).

| Párrafo | Qué hace | Spec |
|---|---|---|
| MAIN | Igual que MAIN del módulo 1B: abre la base `out/policy.db`, borra y recrea la tabla POLICY, abre el archivo de solicitudes y lo recorre llamando a FACADE-HANDLE por cada registro (cuenta 1 procesado). Al terminar cierra el archivo, vuelca la tabla ordenada por número de póliza a `out/policy.csv`, cierra la base, muestra `PROCESSED=nnnnnn INSERTED=nnnnnn REJECTED=nnnnnn` y termina con código 0. Si falla la apertura de la base, la creación de la tabla, la apertura del archivo o el volcado, muestra el mensaje correspondiente (`OPEN FAILED`, `CREATE FAILED`, `OPEN REQUEST-FILE failed, FS=xx`, `DUMP FAILED`) y termina con código 1. | §1, §3, §6 |
| READ-RECORD | Lee la siguiente solicitud de `requests.dat` (mismo registro fijo de 99 caracteres que el módulo 1B: id de solicitud, número de póliza, cliente, fechas, tipo, última modificación, corredor, referencia, pago). Al fin del archivo enciende la marca EOF-REACHED que corta el bucle. | §2 |
| FACADE-HANDLE | La fachada propiamente dicha (traducción de MAINLINE de LGAPOL01). Validación: si el número de póliza es 0, cuenta 1 rechazada, muestra `ERR  POLNUM=0000000000 RC=98` y pasa a la siguiente solicitud sin tocar la base; es el reemplazo de la comprobación de largo de commarea del original (RC 98), porque en lotes no hay commarea y el número 0 ya no significa "que lo asigne la base". Si pasa, copia los nueve campos al bloque de parámetros y llama al programa anidado ADDPOLDB-INSERT (equivalente de `EXEC CICS LINK PROGRAM("LGAPDB01")`). Si el programa anidado devuelve 0: cuenta 1 insertada y muestra `OK   POLNUM=nnnnnnnnnn`; si no: cuenta 1 rechazada y muestra `ERR  POLNUM=nnnnnnnnnn RC=+000000000n` (1 para cualquier error SQL, típicamente clave duplicada). El programa anidado ADDPOLDB-INSERT (líneas 173-214, sin párrafos con nombre) arma el `INSERT INTO POLICY VALUES (…)` igual que INSERT-POLICY de ADDPOLDB y devuelve el código del puente SQLite. En Java: `PolicyFacadeService.add` devuelve `TOO_SHORT_98`, o captura la excepción de `PolicyInsertService.insert` y devuelve `SQL_ERROR` (ADR-10, ADR-9). El fixture actual (01-happy-chain) no ejercita el rechazo RC=98. | §3, §4, §5, §7 |

---

## LGAPOL01 — Fachada original de alta de póliza (IBM GenApp, bajo CICS)

Es el programa de GenApp del que se recortó la fachada. Otro programa lo invoca por CICS LINK
con una commarea que trae el pedido completo. Verifica que la commarea exista (si no, abend) y
que tenga al menos el largo de la cabecera (28 bytes; si no, devuelve RC 98) y enlaza a
LGAPDB01 pasándole la misma commarea, que es quien hace los INSERT y deja en ella el código
de retorno. No tiene lógica de negocio propia: es el patrón "orquestador que delega", que en
Java se vuelve un servicio que llama a otro por inyección (ADR-10).

| Párrafo | Qué hace | Spec |
|---|---|---|
| MAINLINE | Guarda los datos de la transacción CICS (id de transacción, terminal, tarea, largo de commarea). Si no llegó commarea: escribe `NO COMMAREA RECEIVED` en la cola de errores y cae con abend LGCA. Pone el código de retorno en 00, calcula el largo mínimo (solo la cabecera de 28 bytes: a diferencia de LGAPDB01, no mira el tipo de pedido) y, si la commarea es más corta, devuelve RC 98 sin hacer nada más. Si pasa, enlaza a LGAPDB01 con la commarea (largo 32500) y devuelve el control al llamador con lo que LGAPDB01 haya dejado en la commarea (número de póliza, fecha y código de retorno). En el recorte esta validación es "número de póliza distinto de 0" y el LINK es un CALL al programa anidado. | §1, §3, §4, §5 |
| MAINLINE-EXIT | Punto de salida vacío de la sección principal; no hace nada. | §9 |
| WRITE-ERROR-MESSAGE | Arma el mensaje de error (fecha y hora de CICS, nombre del programa y el texto del error) y lo escribe en la cola de errores a través del programa LGSTSQ; después escribe un segundo mensaje con los primeros 90 bytes de la commarea (o todos si tiene menos). Aquí solo se usa para el caso "sin commarea". En el PoC no existe (cola de errores, ASKTIME y FORMATTIME quedaron fuera). | §9 |

---

## LGAPDB01 — Programa enlazado que inserta la póliza completa en DB2 (original de IBM GenApp)

Es el programa al que LGAPOL01 enlaza. Recibe la misma commarea, verifica que exista y que
tenga el largo que corresponde al tipo de póliza pedido (seguro de vida con ahorro, hogar, auto
o comercial), inserta la fila genérica en POLICY dejando que DB2 asigne el número de póliza y
la fecha, y después inserta la fila de detalle en la tabla del tipo (ENDOWMENT, HOUSE, MOTOR o
COMMERCIAL). Si algo falla, escribe un mensaje con fecha, hora, cliente, póliza y SQLCODE en
una cola de errores y devuelve un código de retorno en la commarea (00 ok, 70 cliente
inexistente, 90 error SQL, 98 commarea corta, 99 pedido desconocido). Al terminar encadena con
LGAPVS01. En el PoC solo se lleva INSERT-POLICY (como programa anidado ADDPOLDB-INSERT /
`PolicyInsertService`); el resto se muestra para contexto y no tiene traducción Java.

| Párrafo | Qué hace | Spec |
|---|---|---|
| MAINLINE | Entrada del programa enlazado. Guarda los datos de la transacción CICS, pone a cero las variables numéricas para DB2 y, si no llegó commarea, escribe `NO COMMAREA RECEIVED` y cae con abend LGCA. Pone el código de retorno en 00, copia el cliente al mensaje de error, y según el pedido (`01AEND` vida, `01AHOU` hogar, `01AMOT` auto, `01ACOM` comercial) fija el tipo de póliza (E/H/M/C) y calcula el largo mínimo de commarea; pedido desconocido → RC 99 y vuelve; commarea más corta → RC 98 y vuelve. Luego ejecuta INSERT-POLICY y el INSERT del tipo; el `WHEN OTHER` del segundo EVALUATE es inalcanzable (el primero ya devolvió) y se conserva igual (regla 5). Siempre termina enlazando a LGAPVS01 y devolviendo el control. Fuera del alcance del PoC. | §4, §9 |
| MAINLINE-EXIT | Punto de salida vacío de la sección principal; no hace nada. | §9 |
| INSERT-POLICY | El párrafo que en este módulo se convierte en el programa anidado ADDPOLDB-INSERT y en `PolicyInsertService`. Convierte corredor y pago al formato entero de DB2 e inserta la fila en POLICY con número de póliza DEFAULT (lo asigna DB2) y LASTCHANGED = fecha y hora actual. Evalúa el SQLCODE: 0 → RC 00 y sigue; −530 (el cliente no existe en CUSTOMER, clave foránea) → RC 70, mensaje de error y vuelve; cualquier otro → RC 90, mensaje de error y vuelve. Si salió bien, recupera el número asignado (`IDENTITY_VAL_LOCAL()`), lo copia a la commarea y al mensaje de error, y relee de POLICY la fecha asignada. Adaptación del PoC: número y fecha vienen en la solicitud; la clave foránea (−530) no se lleva; cualquier error SQL devuelve 1 al llamador (`RC=+0000000001`), sin distinguir 70 de 90. | §4, §5, §8 |
| INSERT-ENDOW | Fuera del alcance del PoC. Inserta la fila de detalle de un seguro de vida con ahorro en ENDOWMENT; si la commarea trae texto adicional (campo variable de hasta 3900 caracteres) usa la versión del INSERT que lo incluye, si no, la que no. SQLCODE distinto de 0 → RC 90, mensaje de error y abend LGSQ, que deshace también la fila ya insertada en POLICY. | §9 |
| INSERT-HOUSE | Fuera del alcance del PoC. Inserta la fila de detalle de un seguro de hogar en HOUSE (tipo de propiedad, dormitorios, valor, nombre y número de la casa, código postal). SQLCODE distinto de 0 → RC 90, mensaje de error y abend LGSQ (deshace la fila de POLICY). | §9 |
| INSERT-MOTOR | Fuera del alcance del PoC. Inserta la fila de detalle de un seguro de auto en MOTOR (marca, modelo, valor, patente, color, cilindrada, año, prima, siniestros). SQLCODE distinto de 0 → RC 90, mensaje de error y abend LGSQ (deshace la fila de POLICY). Los fixtures traen pólizas tipo M pero solo se inserta la fila genérica de POLICY, nunca la de MOTOR. | §9 |
| INSERT-COMMERCIAL | Fuera del alcance del PoC. Inserta la fila de detalle de un seguro comercial en COMMERCIAL (dirección, ubicación, cliente, tipo de propiedad, riesgos y primas de incendio, robo, inundación y clima, estado y motivo de rechazo). Usa la fecha de última modificación de POLICY como fecha de solicitud. SQLCODE distinto de 0 → RC 90, mensaje de error y abend LGSQ (deshace la fila de POLICY). | §9 |
| WRITE-ERROR-MESSAGE | Arma el mensaje de error (fecha y hora de CICS, nombre del programa, cliente, póliza, qué INSERT falló y el SQLCODE) y lo escribe en la cola de errores a través del programa LGSTSQ; después escribe un segundo mensaje con los primeros 90 bytes de la commarea (o todos si tiene menos). En el PoC no existe: el código va a la salida estándar y el puente SQLite escribe el texto del error en stderr. | §9 |

---

## ADDPOLDB — Alta de pólizas en POLICY sin fachada (recorte del módulo 1B, citado por el Java de este módulo)

El programa del módulo 1B. Se muestra aquí porque `PolicyInsertService` de este módulo es el
mismo código que el del módulo 1B y cita su párrafo INSERT-POLICY. Hace en un solo programa lo
que ADDPFCD hace en dos: crea la tabla POLICY vacía, lee las solicitudes, inserta una fila por
solicitud, cuenta OK y rechazos, vuelca la tabla y muestra el resumen.

| Párrafo | Qué hace | Spec |
|---|---|---|
| MAIN | Abre la base, borra y recrea la tabla POLICY, abre el archivo de solicitudes y lo recorre ejecutando INSERT-POLICY por cada registro. Al terminar vuelca la tabla ordenada por clave a `out/policy.csv`, cierra la base, muestra `PROCESSED / INSERTED / REJECTED` y termina con código 0; cualquier falla de apertura, creación o volcado muestra su mensaje y termina con código 1. | §8 (y specs/add-policy-db.md §1, §6) |
| READ-RECORD | Lee la siguiente solicitud de `requests.dat` (registro fijo de 99 caracteres) y al fin del archivo enciende la marca que corta el bucle. | §2 |
| INSERT-POLICY | Arma el `INSERT INTO POLICY VALUES (…)` con los nueve campos de la solicitud (referencia del corredor sin espacios a la derecha) y lo ejecuta por el puente SQLite. Código 0 → `OK   POLNUM=…` y suma insertadas; cualquier otro → `ERR  POLNUM=… RC=+000000000n` y suma rechazadas (clave duplicada da 1). No tiene las tres ramas SQLCODE del original (0/−530/otro): solo "cero o no cero". En Java es `PolicyInsertService.insert`: `persist` + `flush` en transacción nueva por solicitud (ADR-9), nunca `save` (sería MERGE y pisaría la fila existente). | §8 (y specs/add-policy-db.md §3, §5) |
