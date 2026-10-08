# add-motor-policy — Guía de párrafos (qué hace cada parte)

Explicación de negocio, párrafo por párrafo, del programa de alta de pólizas de auto. La lee
`tools/render-traceability.py` y la muestra en el visor COBOL ↔ Java (`traceability.html`)
debajo de cada párrafo y en la barra del medio al seleccionarlo. La fuente de verdad sigue
siendo el COBOL (regla 3); la columna *Spec* apunta a la sección de `specs/add-motor-policy.md`
donde está el contrato exacto.

Formato (lo parsea el renderer): un título `## PROGRAMA[, PROGRAMA…] — qué hace el programa`,
un párrafo de resumen, y una tabla `| Párrafo | Qué hace | Spec |`.

---

## ADDMPOL — Dar de alta pólizas de auto (módulo 0)

Lee un archivo de solicitudes de alta de póliza de auto, una por línea. Para cada solicitud
comprueba que sea del tipo correcto y que tenga cliente, cilindrada, valor del vehículo y
fechas; calcula la prima (base por cilindrada + 0,5 % del valor + 50 por cada siniestro previo,
redondeada a moneda entera); y graba dos registros: la póliza (padre) y el detalle del auto
(hijo), con un número de póliza correlativo que arranca en 1 en cada corrida. Las solicitudes
que no pasan van a un log de errores con un código de motivo (10 validación, 11 prima
desbordada, 90 error de grabación, 99 tipo de solicitud desconocido). Termina mostrando
cuántas procesó, cuántas insertó y cuántas rechazó; el código de salida es 0 aunque haya
rechazos. Adaptado del `LGAPDB01` de GenApp: los INSERT de DB2 pasaron a archivos planos.

| Párrafo | Qué hace | Spec |
|---|---|---|
| MAIN-LOGIC | Secuencia de la corrida: abre archivos, procesa solicitudes hasta el fin del archivo, cierra, imprime el resumen y termina. | §3 |
| INITIALIZE-RUN | Abre el archivo de solicitudes; si no puede, muestra "FATAL: cannot open requests.dat" y termina con código de salida 90 (único caso en que la corrida no devuelve 0). Abre desde cero (vacía) los tres archivos de salida: pólizas, autos y log de errores. El estado de apertura de esos tres no se verifica. | §6.5, §7 |
| PROCESS-REQUESTS | Lee la siguiente solicitud (una línea de 143 caracteres). Si es fin de archivo marca la bandera; si no, suma 1 a "procesadas" y la trata. | §2.1, §3 |
| HANDLE-ONE-REQUEST | Cadena de pasos en corto circuito para una solicitud: tipo de solicitud → validaciones → prima → grabar póliza → grabar auto. En cuanto un paso deja un código distinto de 0, los siguientes se saltan. Si todo pasa: suma 1 a "insertadas", muestra "OK  CUST=… POL=… PREM=…" (dos espacios después de OK) y recién entonces avanza el número de póliza (una solicitud rechazada no consume número). Si no: suma 1 a "rechazadas" y registra el error. | §3, §6.1 |
| CHECK-REQUEST-ID | El tipo de solicitud debe ser exactamente `01AMOT` (alta de póliza de auto). Cualquier otro: código 99, motivo "unknown request id". Los otros tipos del GenApp original (vida, hogar, comercial) no están en este módulo. | §2.1, §8 |
| VALIDATE-REQUEST | Cinco reglas en orden; la **primera** que falla gana (código 10) y no se evalúan las demás: cliente en cero, cilindrada en cero, valor del vehículo en cero, fecha de emisión en blanco, fecha de vencimiento en blanco. Los motivos son textos fijos en inglés ("customer number is zero", etc.). No valida fechas futuras ni formatos. | §4 |
| CALC-MOTOR-PREMIUM | Prima = base por cilindrada (≤1000 → 200; ≤1600 → 350; ≤2000 → 500; más → 800) + 0,5 % del valor del vehículo (guardado con dos decimales, sin redondear) + 50 por siniestro previo. La suma se guarda con dos decimales y, si no entra en 999.999,99, da código 11 "premium overflowed PIC 9(6)V99". Luego se redondea a moneda entera **hacia arriba en el ,50** (512,50 → 513): es half-up, no "half-even" como dicen el README y el comentario del propio fuente (ADR-4, spec §5.1). Si al redondear da 1.000.000: código 11 "premium overflow on round". **Ojo, el COBOL difiere de la spec §5.2**: la carga por siniestros (siniestros × 50) no tiene control de desborde y, si supera 999.999,99, pierde los dígitos de la izquierda en silencio; con 20.000 siniestros la carga queda en 0 y la solicitud se acepta con prima 375 (verificado con el binario), mientras que 19.999 sí se rechaza. | §5, §5.1, §5.2 |
| INSERT-POLICY | Arma y graba el registro de póliza (67 caracteres): número de póliza asignado, cliente, tipo `M` (motor) fijo, fechas, corredor, referencia del corredor y pago, copiados tal cual de la solicitud. El número de póliza que venía en la solicitud se ignora. Si la grabación falla: código 90 "write policy.dat failed". | §6.2 |
| INSERT-MOTOR | Arma y graba el registro del auto (87 caracteres): número de póliza, marca, modelo, valor, matrícula, color, cilindrada, año de fabricación, la prima entera calculada y los siniestros. Si falla: código 90 "write motor.dat failed". Si la póliza ya se grabó y esto falla, la póliza queda huérfana (no hay rollback; diferido a la versión JPA). | §6.3, §8 |
| REPORT-ERROR | Escribe en el log de errores una línea "cliente código motivo" (el archivo recorta los espacios finales) y muestra en pantalla "ERR CUST=… RC=… motivo" con el motivo rellenado con espacios hasta 106 caracteres. | §6.1, §6.4 |
| FINALIZE-RUN | Cierra los cuatro archivos. | §7 |
| PRINT-SUMMARY | Muestra "SUMMARY processed=… inserted=… rejected=…" con los tres contadores a seis dígitos. | §6.1 |
