# add-policy-db — Guía de párrafos (qué hace cada parte)

Explicación de negocio, párrafo por párrafo, del módulo 1B: alta de una póliza como fila en
la base de datos. La lee `tools/render-traceability.py` y la muestra en el visor COBOL ↔ Java
(`traceability.html`) debajo de cada párrafo y en la barra del medio al seleccionarlo. La
fuente de verdad sigue siendo el COBOL (regla 3); la columna *Spec* apunta a la sección de
`specs/add-policy-db.md` donde está el contrato exacto.

El visor muestra dos programas: ADDPOLDB (el recorte ejecutable que se traduce a Java) y
LGAPDB01 (el original de IBM GenApp del que se recortó el párrafo INSERT-POLICY; se muestra
para que se vea de dónde viene cada regla). El original corre bajo CICS y DB2; el recorte corre
por lotes con una base SQLite a través de un puente (`cob_sqlite_*`), y el Java con JPA.

Formato (lo parsea el renderer): un título `## PROGRAMA[, PROGRAMA…] — qué hace el programa`,
un párrafo de resumen, y una tabla `| Párrafo | Qué hace | Spec |`.

---

## ADDPOLDB — Dar de alta pólizas en la tabla POLICY (recorte ejecutable, módulo 1B)

Crea la tabla POLICY vacía, lee un archivo de solicitudes de alta (un registro fijo de 99
caracteres por póliza) y, por cada solicitud, inserta una fila en la tabla con los nueve datos
de la póliza: número, cliente, fechas de emisión y vencimiento, tipo, fecha de última
modificación, corredor, referencia del corredor y pago. Si la base rechaza la fila (por ejemplo
porque el número de póliza ya existe) la cuenta como rechazada y sigue con la siguiente; nunca
se cae por un rechazo. Al final vuelca la tabla a `out/policy.csv` ordenada por número de
póliza y muestra el resumen `PROCESSED / INSERTED / REJECTED`. Termina con código 0 aunque haya
rechazos. El número de póliza y la fecha de última modificación vienen en la solicitud (en el
original los asignaba DB2) para que COBOL y Java produzcan la misma fila byte a byte.

| Párrafo | Qué hace | Spec |
|---|---|---|
| MAIN | Abre la base (`out/policy.db`), borra y vuelve a crear la tabla POLICY desde cero, abre el archivo de solicitudes y lo recorre: por cada registro cuenta 1 procesado y ejecuta INSERT-POLICY. Al terminar cierra el archivo, vuelca la tabla a `out/policy.csv` (ordenada por clave) y cierra la base. Si falla la apertura de la base, la creación de la tabla, la apertura del archivo o el volcado, muestra `OPEN FAILED` / `CREATE FAILED` / `OPEN REQUEST-FILE failed, FS=xx` / `DUMP FAILED` y termina con código 1. Si todo va bien muestra `PROCESSED=nnnnnn INSERTED=nnnnnn REJECTED=nnnnnn` y termina con código 0. | §1, §2.2, §4 fila 1 y 3, §6 |
| READ-RECORD | Lee la siguiente solicitud del archivo `requests.dat`. Al llegar al fin del archivo enciende la marca de fin (EOF-REACHED), que es lo que corta el bucle de MAIN. Un registro es: id de solicitud (6), número de póliza (10), cliente (10), fecha de emisión (10), fecha de vencimiento (10), tipo (1: M/H/E/C), última modificación (26), corredor (10), referencia del corredor (10), pago (6). | §2.1 |
| INSERT-POLICY | Arma la sentencia `INSERT INTO POLICY VALUES (…)` con los nueve campos de la solicitud (la referencia del corredor va sin los espacios de relleno a la derecha; en Java `.stripTrailing()`) y la ejecuta a través del puente SQLite. Si el puente devuelve 0 muestra `OK   POLNUM=nnnnnnnnnn` y suma 1 a insertadas; si devuelve otra cosa muestra `ERR  POLNUM=nnnnnnnnnn RC=+000000000n` y suma 1 a rechazadas. Un número de póliza repetido (clave duplicada, SQLCODE −803 en DB2) es el caso que devuelve `RC=+0000000001`; el programa no distingue motivos de error, cualquiera da el mismo código. Importante: el COBOL no tiene aquí las tres ramas SQLCODE del original (0 / −530 / otro → RC 00 / 70 / 90) que el README dice "conservadas tal cual"; el recorte solo pregunta "¿cero o no cero?" (la spec §5 lo describe bien, el README no). En Java este párrafo es `EntityManager.persist` + `flush` dentro de una transacción nueva por solicitud (ADR-9): `JpaRepository.save` haría MERGE y pisaría la fila existente en vez de rechazarla, cosa que el fixture 02-sql-errors detectó. | §3, §4 fila 2, §5 |

---

## LGAPDB01 — Insertar la póliza completa en DB2 (original de IBM GenApp, bajo CICS)

Es el programa de GenApp del que se recortó el módulo. Lo invoca otro programa por CICS LINK
con un área de comunicación (commarea) que trae el pedido. Verifica que la commarea exista y
que tenga el largo que corresponde al tipo de póliza pedido (seguro de vida con ahorro,
hogar, auto o comercial), inserta la fila genérica en POLICY dejando que DB2 asigne el número
de póliza y la fecha, y después inserta la fila de detalle en la tabla del tipo (ENDOWMENT,
HOUSE, MOTOR o COMMERCIAL). Si algo falla, escribe un mensaje con fecha, hora, cliente, póliza
y SQLCODE en una cola de errores y devuelve un código de retorno en la commarea (00 ok, 70
cliente inexistente, 90 error SQL, 98 commarea corta, 99 pedido desconocido). Al terminar
encadena con LGAPVS01 (el siguiente programa de la cadena). En el PoC solo se recortó
INSERT-POLICY; el resto se muestra para contexto y no tiene traducción Java.

| Párrafo | Qué hace | Spec |
|---|---|---|
| MAINLINE | Entrada del programa. Guarda los datos de la transacción CICS, pone a cero las variables numéricas para DB2 y, si no llegó commarea, escribe el mensaje `NO COMMAREA RECEIVED` y cae con abend LGCA. Pone el código de retorno en 00, copia el número de cliente al mensaje de error, y según el pedido (`01AEND` vida, `01AHOU` hogar, `01AMOT` auto, `01ACOM` comercial) fija el tipo de póliza (E/H/M/C) y calcula el largo mínimo de commarea; pedido desconocido → RC 99 y vuelve; commarea más corta que el mínimo → RC 98 y vuelve. Luego ejecuta INSERT-POLICY y el INSERT del tipo correspondiente; el `WHEN OTHER` de este segundo EVALUATE (RC 99) es inalcanzable porque el primero ya devolvió, y se conserva igual (regla 5). Siempre termina enlazando a LGAPVS01 con la commarea y devolviendo el control. Fuera del alcance del PoC: en el recorte la validación es "¿llegó registro?" y no hay commarea. | §1, §8 |
| MAINLINE-EXIT | Punto de salida vacío de la sección principal; no hace nada. | §8 |
| INSERT-POLICY | El párrafo que se recortó para el módulo. Convierte corredor y pago al formato entero de DB2 e inserta la fila en POLICY con número de póliza DEFAULT (lo asigna DB2) y LASTCHANGED = fecha y hora actual. Evalúa el SQLCODE: 0 → RC 00 y sigue; −530 (el cliente no existe en CUSTOMER, clave foránea) → RC 70, mensaje de error y vuelve al llamador; cualquier otro → RC 90, mensaje de error y vuelve. Si salió bien, recupera el número asignado (`IDENTITY_VAL_LOCAL()`), lo copia a la commarea y al mensaje de error, y relee de POLICY la fecha asignada para devolverla también. Adaptación del PoC: número de póliza y fecha vienen en la solicitud, no los asigna la base; la clave foránea a CUSTOMER (−530) no se lleva al PoC; la clave duplicada reemplaza al −530 como caso de error exercitado. | §3, §5, §8 |
| INSERT-ENDOW | Fuera del alcance del PoC (módulo 1B solo recorta INSERT-POLICY). Inserta la fila de detalle de un seguro de vida con ahorro en ENDOWMENT; si la commarea trae texto adicional (campo variable de hasta 3900 caracteres) usa la versión del INSERT que lo incluye, si no, la que no. Cualquier SQLCODE distinto de 0 → RC 90, mensaje de error y abend LGSQ, que deshace también la fila ya insertada en POLICY. | §8 |
| INSERT-HOUSE | Fuera del alcance del PoC. Inserta la fila de detalle de un seguro de hogar en HOUSE (tipo de propiedad, dormitorios, valor, nombre y número de la casa, código postal). SQLCODE distinto de 0 → RC 90, mensaje de error y abend LGSQ (deshace la fila de POLICY). | §8 |
| INSERT-MOTOR | Fuera del alcance del PoC. Inserta la fila de detalle de un seguro de auto en MOTOR (marca, modelo, valor, patente, color, cilindrada, año, prima, siniestros). SQLCODE distinto de 0 → RC 90, mensaje de error y abend LGSQ (deshace la fila de POLICY). Los fixtures del PoC traen pólizas tipo M pero solo se inserta la fila genérica de POLICY, nunca la de MOTOR. | §8 |
| INSERT-COMMERCIAL | Fuera del alcance del PoC. Inserta la fila de detalle de un seguro comercial en COMMERCIAL (dirección, ubicación, cliente, tipo de propiedad, riesgos y primas de incendio, robo, inundación y clima, estado y motivo de rechazo). Usa la fecha de última modificación de POLICY como fecha de solicitud. SQLCODE distinto de 0 → RC 90, mensaje de error y abend LGSQ (deshace la fila de POLICY). | §8 |
| WRITE-ERROR-MESSAGE | Arma el mensaje de error (fecha y hora de CICS, nombre del programa, cliente, póliza, qué INSERT falló y el SQLCODE) y lo escribe en la cola de errores a través del programa LGSTSQ; después escribe un segundo mensaje con los primeros 90 bytes de la commarea (o todos si tiene menos). En el PoC no existe: el recorte muestra el código en la salida estándar y el puente SQLite escribe el texto del error en stderr. | §5, §8 |
