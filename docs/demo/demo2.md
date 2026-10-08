# Deck 2 — "Claude Code acelera, las personas deciden, el diff es el contrato"

Guion (storyline) para el deck HTML de la demo a gerentes y gerentes técnicos de un banco. 30-40 minutos, 13 slides. Cada slide trae: eyebrow (la frase chica arriba del título), título, el mensaje clave en una oración, el cuerpo tal como debe aparecer y las notas del presentador.

Reglas del guion:

- Mensaje de fondo: **Claude Code es un acelerador de la traducción. Las personas deciden. Cada fase deja un artefacto auditable. La comparación byte a byte es el contrato.** Nunca decir ni sugerir que la herramienta hace todo sola.
- Alcance: 4 módulos (0, 1B, 1A, 3), 12 casos de prueba (3 + 2 + 1 + 6), 0 bytes distintos. El módulo 2 (convertidor CCI) no forma parte de este deck.
- Sin jerga: cada término técnico aparece una sola vez entre paréntesis, en letra chica, para el lector técnico.
- Nada se inventa en vivo: todos los comandos de la slide 12 son reproducibles y están en el repositorio.

Fuentes: `docs/demo/DEMO.md`, `docs/demo/ACTO-3-VS-PROPUESTA.md`, `cobol/nightly-batch/README.md`, `specs/*.md`, `docs/methodology/SCALING.md` §4, `README.md` §5.

---

## Slide 1 — Título

**Eyebrow:** Prueba de concepto · COBOL → Java

**Título:** Migración COBOL → Java verificable

**Mensaje clave:** La herramienta acelera la traducción; las personas deciden; la comparación byte a byte con la salida original es el contrato.

**Cuerpo:**

> Claude Code acelera la traducción.
> Las personas deciden en cada fase.
> Cada fase deja un artefacto que se puede auditar.
> La comparación byte a byte es el contrato.

4 módulos · 12 casos de prueba · 0 bytes distintos

Programas públicos de dos sistemas de referencia: seguros (IBM GenApp) y tarjetas de crédito (AWS CardDemo).

**Notas del presentador:**
Abrir con la frase de cuatro líneas y no con la tecnología. La diferencia con lo que suele mostrarse: no vendemos "la inteligencia artificial escribe el Java". Vendemos un proceso donde la herramienta hace el trabajo pesado, una persona decide en cada punto de control, y la prueba de que el Java hace lo mismo que el COBOL es mecánica, repetible y queda guardada. "0 bytes distintos" significa: para cada caso de prueba, la salida del Java (archivos, pantalla, códigos de retorno, tablas) es idéntica, byte por byte, a la salida del COBOL original. Los programas no son juguetes nuestros: son muestras públicas de IBM y de AWS que la industria usa para hablar de modernización.

---

## Slide 2 — El problema

**Eyebrow:** Por qué fracasan las migraciones

**Título:** Traducir es fácil. Demostrar que se comporta igual, no.

**Mensaje clave:** El riesgo de una migración no está en escribir Java, está en probar que el Java hace exactamente lo mismo que el COBOL.

**Cuerpo:**

Décadas de COBOL bancario. Migraciones que fracasan porque demostrar equivalencia es más difícil que traducir el código.

| | | |
|---|---|---|
| 01 | Leer COBOL | Las herramientas de IA lo resuelven. |
| 02 | Escribir Java moderno | Las herramientas de IA lo resuelven. |
| 03 | Demostrar que el código nuevo se comporta idéntico al viejo | Ninguna herramienta lo resuelve sola. Es donde toda migración real se rompe y donde se concentra el riesgo regulatorio. |

Sin prueba de equivalencia, "aproximadamente correcto" se vuelve auditorías, multas y cálculo de interés silenciosamente equivocado.

**Notas del presentador:**
Esta slide se mantiene del deck anterior porque sigue siendo cierta. El punto 03 es el corazón: ninguna herramienta, ni comercial ni de IA, demuestra sola que el nuevo sistema hace lo mismo. Lo que sí se puede hacer es construir un banco de pruebas que corra los dos sistemas con los mismos datos y compare las salidas byte por byte. Eso es lo que vamos a mostrar. Anticipar la frase "aproximadamente correcto": en banca, un centavo de diferencia en el interés de una cuenta es un hallazgo de auditoría, no un detalle.

---

## Slide 3 — Quién hace qué

**Eyebrow:** División del trabajo

**Título:** La herramienta acelera. La persona decide.

**Mensaje clave:** En cada fase hay una tarea mecánica que hace Claude Code y una decisión que toma una persona del banco o del equipo.

**Cuerpo:**

| Fase | Hace la herramienta | Decide la persona |
|---|---|---|
| A · Descubrimiento | Lee el COBOL, arma el mapa de programas y archivos, propone los casos de prueba, corre el COBOL original y guarda su salida como referencia | Confirma el inventario, aporta y valida los datos de prueba, aprueba qué casos cubren qué reglas |
| B · Especificación | Redacta la especificación en lenguaje de negocio a partir del COBOL | El analista del banco la revisa, corrige, y responde las preguntas abiertas ("¿este comportamiento es intencional?") |
| C · Traducción | Escribe el Java siguiendo las reglas acumuladas, con cada línea citando el COBOL que la originó | Revisa las decisiones de diseño y las aprueba o las cambia |
| D · Validación | Corre COBOL y Java con los mismos datos y compara byte a byte | Lee cada diferencia y decide: ¿error del Java, caso de prueba faltante o comportamiento del COBOL que no conocíamos? Firma el verde |
| E · Captura | Propone nuevas reglas de traducción a partir de lo aprendido | Aprueba la regla que pasa a aplicarse en el módulo siguiente |

**Notas del presentador:**
Esta es la slide que reemplaza el mensaje del deck anterior. Recorrer la tabla fila por fila. Insistir: la herramienta nunca aprueba nada; cada "verde" lo firma una persona después de mirar el resultado. Ejemplo concreto para la fila B: en el módulo del cierre nocturno, la especificación le pregunta al analista del banco si es intencional que la última cuenta no reciba interés (lo vemos en la slide 8). Ejemplo para la fila D: la primera corrida del Java en ese módulo dio rojo en 22 bytes de relleno por registro; la persona tuvo que decidir si era un error del Java o una regla del COBOL que faltaba documentar (era lo segundo). Ejemplo para la fila E: el redondeo por defecto del COBOL no es el que uno supone; eso quedó escrito como regla y ya no se vuelve a discutir.

---

## Slide 4 — Las cinco fases y sus artefactos

**Eyebrow:** El método

**Título:** Cinco fases, cinco artefactos auditables

**Mensaje clave:** Cada fase termina con un entregable concreto que queda en el repositorio y se puede revisar sin correr nada.

**Cuerpo:**

| Fase | Qué se hace | Por qué | Artefacto que queda |
|---|---|---|---|
| A · Descubrimiento | Leer el módulo completo y correr el COBOL original con casos de prueba | Si el COBOL original no es reproducible, no hay contra qué comparar | La salida original del COBOL, guardada como referencia (golden master) + mapa de dependencias |
| B · Especificación | Describir las reglas en lenguaje de negocio | Que alguien que no sabe COBOL pueda validar qué hace el programa | Especificación con checklist de preguntas para el analista del banco |
| C · Traducción | Escribir el Java bajo reglas fijas | Precisión numérica obligatoria; cada método cita su párrafo COBOL | Código Java con trazabilidad línea a línea + decisiones documentadas (ADR) |
| D · Validación | Correr los dos lados y comparar byte a byte | "Compila" no es "hace lo mismo" | Informe de equivalencia en formato legible por máquina (JSON) |
| E · Captura | Convertir lo aprendido en reglas | Que el módulo siguiente arranque con más reglas y menos sorpresas | Reglas de traducción acumuladas (glosario) + checklist de proceso |

**Notas del presentador:**
El orden importa: nadie empieza a traducir antes de tener la salida original guardada. Regla de la casa: el COBOL es la verdad, no la especificación; si difieren, se corrige la especificación. Otra regla: no se "mejora" el COBOL antes de que el diff esté verde, porque en COBOL bancario lo que parece código muerto suele estar sosteniendo algo. Aclarar que todo esto está escrito como reglas en el repositorio, versionadas, y que un ingeniero nuevo puede leerlas y auditar exactamente qué restricciones aplicaron.

---

## Slide 5 — Los artefactos, de cerca

**Eyebrow:** Qué queda en el repositorio

**Título:** Lo que se puede auditar sin correr nada

**Mensaje clave:** Cada afirmación de esta presentación apunta a un archivo concreto que el banco puede abrir.

**Cuerpo:**

| Artefacto | Ejemplo real (abreviado) |
|---|---|
| Salida original del COBOL, guardada como referencia | `golden-master/nightly-batch/01-happy-small/` — salida por paso, códigos de retorno, 9 archivos de datos |
| Especificación con preguntas para el analista | *"¿Es intencional que la última cuenta nunca reciba su interés? Hoy la salida del mainframe se comporta así."* |
| Java con trazabilidad | `// COBOL: CBACT04C.cbl:219-221` — cada línea de Java cita la línea de COBOL que la originó |
| Informe de equivalencia | `"diffs": []` — 44 archivos · 397 registros · 0 bytes distintos (caso de prueba 01 del cierre nocturno) |
| El guion del cierre nocturno | `job.json` — un solo archivo describe los 16 pasos; lo leen el lado COBOL y el lado Java |
| Registro de corrida con reanudación | `ABEND AFTER INTCALC (injected)` → `SKIPPED (COMPLETED IN RUN 1)` → `END MAXRC=0004` |
| Matriz de cobertura | Qué párrafo del COBOL ejecutó cada caso de prueba, generada desde la traza de ejecución real |
| Checklist de proceso | `RESULT: CONFORMANT` — 12 controles por módulo |
| Decisiones y reglas acumuladas | 16 decisiones documentadas (ADR-1 a ADR-16) + glosario de reglas de traducción |

**Notas del presentador:**
No leer la tabla entera; elegir tres. (1) La pregunta de la especificación: muestra que el método produce preguntas para el banco, no solo código. (2) El comentario de trazabilidad: si un auditor pregunta "¿de dónde sale esta regla de interés?", la respuesta es una línea de COBOL con número. (3) El informe de equivalencia: `diffs: []` es el contrato; cualquier cosa que no sea vacío detiene la demo. La matriz de cobertura es nueva: antes se escribía a mano leyendo el código; ahora se genera desde lo que el COBOL realmente ejecutó, así que no se puede "olvidar" un párrafo. Si preguntan por el visor lado a lado COBOL ↔ Java: existe por módulo (`traceability.html`) y se abre en el tercer momento del módulo 3.

---

## Slide 6 — Qué parte del mainframe cubrimos

**Eyebrow:** Cuatro módulos, cuatro aristas

**Título:** Casos reales, no ejemplos de juguete

**Mensaje clave:** Cuatro programas públicos cubren archivos, base de datos, orquestación y batch nocturno; y decimos de frente lo que todavía no cubrimos.

**Cuerpo:**

| Módulo | Programa | Qué hace para el negocio | Arista del mainframe | Casos |
|---|---|---|---|---|
| 0 | `ADDMPOL` (seguros, IBM GenApp) | **Alta de pólizas de auto en lote**: lee solicitudes, valida cliente, cilindrada, valor del vehículo y fechas, calcula la prima (base por cilindrada + 0,5 % del valor + 50 por siniestro previo, redondeo comercial) y graba póliza + vehículo + log de errores | Archivos de entrada/salida | 3 |
| 1B | `ADDPOLDB` (GenApp) | **Persistir la póliza en la base de datos**: la misma alta pero insertando en una tabla, con manejo de errores de clave duplicada | Base de datos (DB2 / SQL) | 2 |
| 1A | `ADDPFCD` (GenApp) | **La fachada que orquesta programas**: un programa recibe la solicitud, la valida y le pasa el control al programa de base de datos | Orquestación entre programas (CICS LINK) | 1 |
| 3 | `CBTRN02C` · `CBACT04C` · `CBTRN03C` (tarjetas, AWS CardDemo) | **El cierre nocturno de una cartera de tarjetas**: contabilizar las transacciones del día, cobrar el interés mensual, ordenar y reconstruir el maestro, imprimir el reporte diario | Batch de varios pasos, archivos indexados actualizados en el lugar, ordenamientos, reanudación, caída con código de error | 6 |

**Todavía no cubierto (lo decimos antes de que lo pregunten):** pantallas interactivas (CICS online / BMS), bases jerárquicas (IMS), colas (MQ), cursores de base de datos en batch, generaciones de archivos (GDG), condiciones selectivas entre pasos (`COND=`), una corrida con entrada 100 % EBCDIC, y rendimiento.

**Notas del presentador:**
Contar primero qué hace cada programa para el negocio, después la arista técnica. Módulo 0 es la puerta de entrada: un batch de seguros con reglas de validación y una fórmula de prima. Módulo 1B y 1A son el mismo negocio (alta de póliza) resuelto de las dos formas en que un mainframe lo hace: contra base de datos y a través de un programa orquestador. Módulo 3 es el salto de escala: tres programas de un core de tarjetas, tomados sin tocar una línea, corriendo como un trabajo de cuatro pasos. Frase a evitar: "esto cubre todo lo que hace un sistema COBOL". No. Cubre cuatro aristas frecuentes. La lista de lo no cubierto es parte del mensaje de honestidad; decirla completa y sin apuro.

---

## Slide 7 — Acto 3: el cierre nocturno

**Eyebrow:** Módulo 3 · AWS CardDemo

**Título:** Un día en el banco, de noche

**Mensaje clave:** Un trabajo real de cuatro pasos, con reanudación tras caída y caída con código de error, corre idéntico en COBOL y en Java.

**Cuerpo:**

| Paso | Programa | Qué hace para el negocio |
|---|---|---|
| 1 · Contabilizar | `CBTRN02C` | Toma las transacciones del día; verifica que la tarjeta exista, que la cuenta exista, el límite de crédito y el vencimiento; actualiza saldo y acumulados de ciclo; los rechazos salen con motivo (100 tarjeta inexistente · 101 cuenta inexistente · 102 excede límite · 103 tarjeta vencida) |
| 2 · Intereses | `CBACT04C` | Calcula el interés mensual por cuenta y categoría con la tasa del grupo de la cuenta (o la tasa por defecto), lo suma al saldo y genera una transacción de interés por cuenta |
| 3 · Reconstruir | ordenamiento + recarga | Une las transacciones del día con las de interés, las ordena y reconstruye el maestro de transacciones |
| 4 · Reporte | ordenamiento + `CBTRN03C` | Filtra por rango de fechas, ordena por tarjeta e imprime el reporte diario con totales por cuenta, por página y general |

- 4 pasos de negocio = 16 pasos técnicos en el guion del trabajo (cargas de archivos, respaldos, capturas).
- 6 casos de prueba: normal · rechazos · bordes numéricos · volumen (50 cuentas, 300 transacciones, 18 páginas) · **reanudación** · **caída**.
- 60 archivos comparados por caso (datos, salidas de cada paso, log del trabajo y la traza de párrafos de cada programa); 0 bytes distintos.

**Notas del presentador:**
Lo que esto responde: "¿y el batch de verdad, con JCL de varios pasos, archivos que se actualizan en el lugar, ordenamientos y reinicio?" El guion del trabajo (el análogo del JCL) está escrito una sola vez, en un archivo que lee tanto el lado COBOL como el lado Java: orden de pasos, archivos, códigos de retorno y reglas de reanudación no pueden divergir. Reanudación: un caso mata el trabajo después del paso 2 y lo reanuda; la salida final tiene que ser idéntica a la corrida sin corte, de los dos lados, y el checker lo exige. Caída: otro caso introduce una categoría sin tasa; el programa de intereses cae con código 12, los pasos siguientes quedan "NO EJECUTADO", los pasos de captura corren igual, y el código final es 12 en los dos lados. Tres honestidades que hay que decir: (1) los programas son públicos y sin modificar, pero el entorno del mainframe (JCL, utilitarios, ordenador, runtime) se reemplaza por piezas chicas y documentadas; (2) los datos usan el formato de signo del mainframe (overpunch zonado), no el formato empaquetado (COMP-3) en archivo; (3) la reanudación prueba "misma salida final", no "mismo mecanismo de checkpoint".

---

## Slide 8 — Traducimos los errores a propósito

**Eyebrow:** Regla 5: no refinar el COBOL antes del verde

**Título:** Lo que el banco corre, con sus errores, y le decimos dónde están

**Mensaje clave:** El cierre nocturno trae dos defectos reales de legado; el Java los reproduce, los cita, y la especificación le pregunta al banco si son intencionales.

**Cuerpo:**

| Defecto | Dónde | Qué pasa | Cómo se ve |
|---|---|---|---|
| D1 | `CBACT04C.cbl:219-221` | La última cuenta recibe su transacción de interés, pero su saldo nunca se actualiza ni se reinician sus acumulados (una rama `ELSE` que nunca se ejecuta) | Cuenta 5 en los casos chicos; cuenta 50 en el caso completo |
| D2 | `CBTRN03C.cbl:197-204` | Al llegar al final del archivo, el reporte vuelve a sumar el último importe: el total general queda inflado y la última tarjeta no tiene total de cuenta | Caso completo: total general 79.254,29 contra 79.233,86 real (Δ 20,43, el último importe) |

Preguntas que la especificación le hace al analista del banco:

1. ¿Es intencional que la última cuenta nunca reciba su interés ni reinicie sus acumulados? Hoy la salida del mainframe se comporta así.
2. El total general del reporte supera la suma de sus líneas por el importe de la última. ¿Alguien lo está conciliando?

**Notas del presentador:**
Respuesta ensayada a "¿tradujeron un error a propósito?": "Sí, dos, y podemos mostrar la línea exacta. La regla del método dice: no refinar el COBOL antes de que el diff esté verde. El Java reproduce los dos, los cita, y la especificación le pregunta al banco si son intencionales. Cuando 'arreglamos' el primero como prueba de sabotaje, el diff se puso rojo en la cuenta 5: el banco de pruebas también protege al banco de mejoras bien intencionadas." Aclarar la división de trabajo: la herramienta encontró y documentó los defectos; la decisión de qué hacer con ellos (mantener, corregir después del verde, conciliar) es del banco. Esto es lo que una traducción sintáctica comercial nunca entrega: no solo Java que compila, sino una lista de preguntas de negocio con número de línea.

---

## Slide 9 — La prueba de sabotaje

**Eyebrow:** ¿El banco de pruebas tiene dientes?

**Título:** Un centavo alcanza para ponerlo en rojo

**Mensaje clave:** Cambiamos una sola cosa en el Java a propósito y el comparador lo detecta, nombrando cuenta, campo y centavo.

**Cuerpo:**

**Sabotaje 1 — un modo de redondeo.** Cambiamos truncar por redondear (`RoundingMode.DOWN` → `HALF_UP`) en el cálculo de interés.

> `registro 1: ACCT-CURR-BAL cobol=201.75 java=201.76`

Un centavo, en la cuenta 1. Rojo. Revertido: verde.

**Sabotaje 2 — "arreglar" el defecto D1.** Hacemos que la última cuenta sí reciba su interés.

> `cuenta 5: saldo cobol=1182.86 java=1198.69` (y los acumulados de ciclo)
> `traza: primera divergencia en la entrada 68 — cobol 1000-TCATBALF-GET-NEXT vs java 1050-UPDATE-ACCOUNT`

Rojo en el dato y rojo en el recorrido del programa. Revertido: verde.

**Notas del presentador:**
Este es el momento más fuerte de la demo y conviene correrlo en vivo (`negative-control`, un minuto). Lo que demuestra: que el verde no es decorativo. Si el comparador no detectara un centavo, no serviría para banca. El segundo sabotaje tiene un detalle nuevo: además de comparar los datos, comparamos el recorrido de párrafos de los dos programas (la traza de ejecución) y el informe dice en qué entrada se separan y qué párrafo tomó cada lado. Para un ingeniero eso convierte "hay un byte distinto" en "el Java fue a actualizar la cuenta cuando el COBOL ya había terminado de leer". Insistir en la división de trabajo: la herramienta corre y compara; una persona lee el informe y decide qué significa. Los dos sabotajes están documentados y revertidos; el repositorio está en verde.

---

## Slide 10 — Checklist de proceso

**Eyebrow:** Mismo método, mismas herramientas, todos los módulos

**Título:** 12 controles por módulo · 4 de 4 cumplen

**Mensaje clave:** Un comando verifica que cada módulo pasó por las cinco fases con los mismos artefactos; hoy los cuatro módulos cumplen la checklist de proceso (conformance).

**Cuerpo:**

| # | Control |
|---|---|
| 1 | El módulo documenta de dónde viene el COBOL y qué se mantuvo, adaptó o agregó |
| 2 | Existe el mapa de dependencias y su diagrama está sincronizado |
| 3 | Los programas declarados "sin modificar" son idénticos byte a byte al original |
| 4 | Hay casos de prueba definidos |
| 5 | Hay salida original guardada para cada caso |
| 6 | Existe la especificación para el analista |
| 7 | El Java no contamina la salida, cada clase cita su COBOL y no hay tipos numéricos inexactos |
| 8 | El informe de equivalencia está en verde y es más nuevo que las corridas |
| 9 | Las decisiones documentadas y el glosario citan al módulo |
| 10 | El módulo está en el guion de la demo |
| 11 | (batch) La corrida con reanudación produce lo mismo que la corrida sin corte |
| 12 | Recordatorio: una persona corre la validación y firma el verde |

`./tools/check-module.sh --all` → `RESULT: CONFORMANT`

**Notas del presentador:**
En el deck anterior esta slide era una aspiración ("evaluación en cada paso"). Ahora es un script que corre en segundos. Lo que verifica es presencia y consistencia de los artefactos de proceso, no la equivalencia en sí (eso es el control 8, que lee el informe de la fase D). Destacar el control 3: los tres programas del cierre nocturno se comparan contra el original con `cmp`; si alguien tocara una línea, el módulo deja de cumplir. Destacar el control 12: es deliberadamente un recordatorio, no un chequeo automático; la firma del verde es humana por diseño. Esto es lo que permite escalar a un equipo: cualquier módulo nuevo tiene que pasar la misma checklist, y no depende de quién lo hizo.

---

## Slide 11 — Cómo el banco de pruebas encuentra divergencias

**Eyebrow:** Hallazgos reales, no teóricos

**Título:** Lo que el diff atrapó y una revisión de código no

**Mensaje clave:** Cada regla de traducción que tenemos nació de una divergencia concreta que el comparador detectó; ninguna la habríamos visto leyendo el Java.

**Cuerpo:**

| Hallazgo | Dónde | Qué pasó |
|---|---|---|
| El redondeo por defecto del COBOL no es el que supone Java | Módulo 0 | `350 + 112,50 + 50 = 512,50` → COBOL da **513**, Java daba 512. Regla fijada. |
| "Guardar" no es "insertar" | Módulo 1B | Ante clave duplicada el COBOL falla; el método estándar de Java sobreescribía en silencio. Regla fijada. |
| Un programa sin redondeo trunca | Módulo 3 | `0,09575` → `0,09`; `−11,4875` → `−11,48`. Lo contrario pone rojo un centavo. |
| Los bytes de relleno se conservan | Módulo 3 | La primera corrida del Java dio rojo en exactamente 22 bytes de relleno por registro creado. |
| El reloj congelado necesita centésimas | Módulo 3 | Las marcas de tiempo seguían corriendo en las centésimas; sin eso no hay comparación posible. |
| La pantalla de arranque del Java "ensucia" la salida | Todos | El banner y los logs del motor Java iban a la salida que se compara. Suprimidos por regla. |
| Dos errores de legado sobreviven la traducción | Módulo 3 | D1 y D2, citados en el Java y preguntados al banco. |

Cómo se reporta hoy una diferencia:

> antes: `byte 24: E vs F`
> ahora: `registro 1: ACCT-CURR-BAL cobol=201.75 java=201.76`
> y, si el recorrido del programa cambia: `primera divergencia en la entrada 68 — cobol 1000-TCATBALF-GET-NEXT vs java 1050-UPDATE-ACCOUNT`

**Notas del presentador:**
Mensaje central: estos hallazgos no salieron de leer código ni de pruebas unitarias escritas contra el Java; salieron de correr los dos lados y comparar. Un traductor comercial que solo verifica que el Java compila habría embarcado al menos los dos primeros. Lo nuevo desde el deck anterior está en el bloque de abajo: el informe de diferencias ya no dice "byte 24 E contra F", dice el nombre del campo COBOL, el registro y los dos valores; y cuando el recorrido de párrafos difiere, dice en qué párrafo se separaron. Eso baja el tiempo entre "rojo" y "entendimos por qué" de horas a minutos, y es información que lee el analista del banco, no solo el programador. Recordar la división de trabajo: el comparador señala; la persona decide si es un error del Java, un caso de prueba que falta o un comportamiento del COBOL que hay que documentar.

---

## Slide 12 — Demo en vivo

**Eyebrow:** Todo reproducible, nada en vivo se traduce

**Título:** Lo que vamos a correr

**Mensaje clave:** Cada comando reproduce una fase del método con los artefactos ya existentes; no hay traducción en vivo y cualquier corrida da el mismo resultado.

**Cuerpo:**

```
./tools/demo-commands.sh module-0           # alta de pólizas en lote · 3 casos
./tools/demo-commands.sh module-1b          # póliza en base de datos · 2 casos
./tools/demo-commands.sh module-1a          # fachada que orquesta · 1 caso
./tools/demo-commands.sh module-3           # cierre nocturno · 6 casos + reanudación + defecto fiel
./tools/demo-commands.sh negative-control   # sabotaje: rojo → revertir → verde
./tools/demo-commands.sh conformance        # checklist de proceso, 12 controles por módulo
./tools/demo-commands.sh proof              # informe de equivalencia, totales calculados
```

Cada módulo son tres pasos: capturar la salida original del COBOL → compilar y correr el Java → comparar byte a byte.

**Lo que prueba:** para cada caso de prueba, el Java produce exactamente los mismos bytes que el COBOL en todos los canales (pantalla, código de salida, archivos, tablas, log del trabajo).

**Lo que no prueba:** comportamiento fuera de los casos de prueba · rendimiento · que el COBOL fuera correcto (lo traducimos fiel, errores incluidos).

**Notas del presentador:**
Recorrido sugerido para 12-15 minutos: `module-0` (rápido, muestra el patrón de tres pasos), `module-3` (el registro de la reanudación y el defecto fiel), `negative-control` (el momento rojo → verde), `proof` (la línea final con 12/12 y los totales calculados, nada escrito a mano). Decir explícitamente: no hay traducción en vivo. El Java ya está escrito y revisado; lo que se demuestra es que la verificación es mecánica y repetible. Si algo sale rojo en escena: no reiniciar, mostrar el informe de diferencias. "Parar la demo y mostrar el diff" es en sí una demostración de que el banco de pruebas es honesto. Si preguntan cómo intervino Claude Code: leyó el COBOL, leyó las reglas del método (versionadas en el repositorio), escribió el Java bajo esas reglas, y una persona corrió el diff y decidió qué hacer con cada rojo.

---

## Slide 13 — Alcance y próximos pasos

**Eyebrow:** Qué está hecho y qué falta

**Título:** Correctitud primero; el diff es la red de seguridad para todo lo demás

**Mensaje clave:** La prueba de concepto demuestra equivalencia verificable en cuatro aristas del mainframe; lo que sigue es validar en el entorno real y medir rendimiento, con el mismo contrato.

**Cuerpo:**

**Hecho**

- 4 módulos · 12 casos de prueba · 0 bytes distintos
- Pruebas de sabotaje: dos, en el cierre nocturno, documentadas y revertidas
- Checklist de proceso: 12 controles · 4 de 4 módulos cumplen
- Diferencias reportadas por campo y por párrafo; matriz de cobertura generada desde la ejecución real (82 de 86 párrafos del cierre nocturno; los 4 restantes son las rutas de caída que ningún caso dispara, listadas, no escondidas)
- Visor lado a lado COBOL ↔ Java por módulo: cada párrafo muestra qué Java lo traduce y en cuántos casos se ejecutó
- Dos defectos de legado detectados, reproducidos y preguntados al banco

**Pendiente**

- Validar contra el mainframe real (hoy el COBOL corre en un compilador abierto, GnuCOBOL, en x86)
- Una corrida completa con entrada 100 % EBCDIC
- Pantallas interactivas (CICS online), IMS, MQ, cursores en batch
- Rendimiento con una línea base del mainframe

**La pregunta difícil: "¿y el rendimiento?"**

> Correctitud primero. Esta prueba de concepto demuestra correctitud, no rendimiento. Toda optimización posterior (particionar, paralelizar, cambiar el motor de base de datos) se hace con la misma red de seguridad: el diff byte a byte tiene que seguir en verde. GnuCOBOL en x86 no es una línea base válida del mainframe; medir rendimiento requiere la corrida original en z/OS.

**Notas del presentador:**
Cerrar con la división de trabajo una vez más: lo que la herramienta aceleró (lectura, especificación, traducción, comparación) y lo que las personas decidieron (casos de prueba, reglas, qué hacer con cada rojo, qué hacer con los defectos). Sobre el pendiente más importante, la validación contra el mainframe real: la salida original que usamos como referencia se produjo con un compilador abierto; una migración real tiene que correr el COBOL en el mainframe al menos una vez y confirmar que la referencia es la misma. Sobre rendimiento: no esquivar la pregunta, dar la respuesta acordada tal como está en la slide. El argumento es que el contrato no cambia cuando se optimiza: primero se demuestra que hace lo mismo, después se hace más rápido, y cada paso de optimización vuelve a pasar por el mismo diff. Propuesta de siguiente paso: elegir un programa del banco (no una muestra pública), correrlo en su mainframe para capturar la referencia, y repetir las cinco fases con el analista del banco en la fase B.
