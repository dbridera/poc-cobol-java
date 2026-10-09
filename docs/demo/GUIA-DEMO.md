# Guía del presentador — demo "Harness COBOL → Java"

Para quien presenta. Qué contar, qué decir, qué comando correr y qué tiene que aparecer en pantalla en cada paso. Las salidas de esta guía son las reales de la rama `feature/translator-tooling` al 2026-10-08; si cambia el código, volver a correr el recorrido y actualizar los números.

Regla de oro: **no se traduce nada en vivo**. El Java ya está escrito y revisado. Lo que se demuestra es que la verificación es mecánica, repetible y la corre un agente. Si algo sale rojo en escena, no reiniciar: mostrar el informe de diferencias. Que el banco de pruebas pare la demo es, en sí, la demo.

---

## 0. Antes de empezar (30 minutos antes, sin público)

```bash
./tools/demo-commands.sh preflight
```

Qué esperar: las versiones de `cobc`, `java`, `mvn` y `claude`; "Clean state"; los cinco módulos corriendo en modo silencioso; al final:

```
Pre-flight complete. Fifteen fixtures byte-exact equivalent.
You're ready for the live demo.
```

Checklist de escena:

- Una sola ventana de terminal, fuente grande (18 pt o más), fondo claro u oscuro pero con buen contraste. La terminal integrada de VS Code es la más cómoda: los archivos se abren en el mismo editor, al lado de la terminal.
- El navegador abierto en una pestaña vacía (el visor se abre solo cuando toca).
- `claude` con sesión iniciada (`claude --version` responde). El agente en vivo usa la suscripción, no una API key.
- Si la red es dudosa, probar antes `./tools/demo-commands.sh agentic-eval --replay`: reproduce la grabación y no necesita red.
- Cerrar todo lo demás. Notificaciones apagadas.

Todos los comandos del recorrido llevan `--step`: el script explica, espera Enter, corre el comando, lista los artefactos y vuelve a esperar. El ritmo lo manejás vos con Enter. En las listas de artefactos, un número abre el ítem: los archivos (COBOL, Java, spec, salidas, informe) en VS Code, los html en el navegador, y los ítems marcados "(carpeta)" en Finder. En la terminal de VS Code los paths se muestran sin adorno y Cmd+clic los abre en el editor, lo cual es lo que querés para COBOL, Java, spec e informes, pero no para los html: VS Code los abriría como texto, así que los html se abren siempre con el número (van a Chrome o Safari) o con `viewer`. En Terminal.app o iTerm2 los paths son links y Cmd+clic los abre con la aplicación por defecto, así que ahí conviene usar el número para todo. Enter solo sigue.

---

## 1. Recorrido y tiempos

| Bloque | Slides del deck | Comando | Tiempo |
|---|---|---|---|
| Apertura: problema, quién hace qué, el harness, el loop, los artefactos, los módulos | 1 a 7 | ninguno | 11 min |
| El patrón en chico: módulo 0 | 7 | `module-0 --step` | 3 min |
| El cierre nocturno: módulo 3 y sus tres momentos | 8 y 9 | `module-3 --step` | 7 min |
| Agentic evals 1: el sabotaje | 10 | `negative-control --step` | 5 min |
| Agentic evals 2: el agente validador en vivo | 11 | `agentic-eval` | 3 min |
| Checklist de proceso y prueba final | 12 | `conformance` y `proof` | 3 min |
| Alcance y próximos pasos, preguntas | 13 y 14 | ninguno | 10 min |

Total: unos 40 minutos. Si hay que recortar, se cae primero `conformance` (decir el resultado sin correrlo) y después `module-0` (ir directo al módulo 3).

---

## 2. Bloque por bloque

### 2.1 Apertura (slides 1 a 7, sin comandos)

**Qué contar.** Traducir COBOL a Java es fácil; demostrar que se comporta igual, no. El harness acelera la traducción y produce artefactos que una persona puede auditar sin correr nada. El loop (slide 5) es: leer el COBOL, leer el harness, escribir el Java, agentic eval, capturar la lección; cada fase deja un artefacto (slide 6) y esos mismos artefactos son los que la terminal va a listar como links en cada bloque. Las validaciones las corre un agente y por eso las llamamos agentic evals. Cubrimos cuatro aristas del mainframe: archivos VSAM, base DB2, orquestación CICS y batch con JCL.

**Qué decir al pasar a la terminal.** "Lo que sigue no es una traducción en vivo. El Java ya existe. Lo que van a ver es cómo se verifica, y cómo esa verificación se defiende sola."

### 2.2 Módulo 0: el patrón en chico (3 minutos)

```bash
./tools/demo-commands.sh module-0 --step
```

**Qué contar.** Un programa de seguros de IBM GenApp que da de alta pólizas de auto en lote, leyendo y escribiendo archivos de registros de largo fijo, la forma VSAM. Sirve para mostrar el patrón de tres pasos que se repite en todos los módulos.

**Qué esperar, paso a paso.**

1. Cabecera: `MÓDULO 0 — Archivos VSAM: alta de pólizas en lote` y la pregunta del banco: "¿cómo manejan los archivos VSAM?". Enter.
2. `FASE A — Capturar la salida de referencia del COBOL`. Decir: "corremos el COBOL original, sin tocar, con tres casos de prueba; cada byte que produce es el contrato". Enter. Aparecen tres líneas `captured: golden-master/add-motor-policy/...`.
3. Lista de artefactos de la fase A. Opcional: abrir el 1 (el programa COBOL principal, se abre en el editor) y cerrarlo enseguida: "este es el programa tal cual, no lo tocamos". Enter. Se abre solo en el navegador el grafo de dependencias del COBOL (programas, copybooks, archivos): una mirada de cinco segundos, "esto es lo que el harness entendió del módulo antes de traducir". Enter.
4. `FASE C — Correr el Java ya traducido`. Decir: "nada se traduce ahora; esto compila y corre lo que ya está escrito". Enter. Aparece `==> building add-motor-policy` y tres `captured: java-run/...`. La compilación tarda unos 20 segundos; es el único silencio del bloque.
5. Artefactos de la fase C. Vale la pena abrir el 1 (la clase Java con más citas al COBOL, se abre en el editor) y mostrar un comentario `// COBOL: ADDMPOL.cbl:...`: "cada método dice qué líneas del COBOL traduce". Enter.
6. `FASE D — Agentic eval: comparación byte a byte (el contrato)`. Enter. Tres líneas verdes:

```
[OK ] add-motor-policy/01-happy-small   (files 5 · records 10 · bytes 666 · differing 0)
[OK ] add-motor-policy/02-validation-errors   (files 5 · records 12 · bytes 931 · differing 0)
[OK ] add-motor-policy/03-numeric-boundaries   (files 5 · records 18 · bytes 1250 · differing 0)
```

7. Se abre solo el visor COBOL ↔ Java del módulo en el navegador. En el módulo 0 no hace falta detenerse: un clic en un párrafo para mostrar que el Java salta, y volver. Enter.
8. Bloque `RESULTADO — Módulo 0 (VSAM): 3 / 3 casos de prueba idénticos byte a byte ✅`, con los canales comparados y el hallazgo: "el ROUNDED del COBOL redondea HALF_UP, no HALF_EVEN como Java por defecto (ADR-4)".

**Qué decir sobre el hallazgo.** "Este módulo nos enseñó que el redondeo por defecto de Java no es el del COBOL. Salió rojo, se corrigió, y la regla quedó escrita en una decisión de arquitectura para que ningún módulo siguiente la repita."

### 2.3 Módulo 3: el cierre nocturno (7 minutos)

```bash
./tools/demo-commands.sh module-3 --step
```

**Qué contar.** Un cierre nocturno real de una cartera de tarjetas, de AWS CardDemo, con los tres programas sin tocar: contabilizar las transacciones del día, cobrar el interés mensual, imprimir el reporte diario. Cuatro pasos de JCL, archivos indexados actualizados en el lugar, ordenamientos, una reanudación tras una caída y una caída controlada.

**Qué esperar.**

1. Cabecera `MÓDULO 3 — Cierre nocturno: trabajo JCL de 4 pasos (AWS CardDemo)`. Enter.
2. `FASE A — Capturar el trabajo COBOL, paso a paso`. Decir: "16 pasos contando cargas y capturas, 6 casos de prueba; uno de ellos se mata después del paso 2 y se reanuda". Enter. Corre unos 40 segundos; se ven `==> fixture ...` y `captured: ... (exit_code=4)` para cinco casos y `(exit_code=12)` para el sexto, la caída. Decir: "4 es 'hubo rechazos', 12 es 'caída', igual que en el mainframe".
3. Artefactos de A. Sugerido: abrir `job.json` (el manifiesto que hace de JCL) o la especificación; los números cambian según el módulo, guiarse por el nombre. Enter. Se abre solo el grafo de dependencias: aquí vale la pena detenerse, porque muestra los 16 pasos del trabajo, los 24 archivos y qué programa lee y escribe cada uno. Enter.
4. `FASE C — Correr la traducción a Spring Batch`. Enter. Un paso Spring Batch por paso JCL; 40 a 60 segundos. Mismos `captured:` y mismos códigos de salida.
5. `FASE D — Agentic eval: hasta 60 archivos por caso, byte a byte`. Enter. Seis líneas verdes; señalar la cuarta:

```
[OK ] nightly-batch/04-full-carddemo   (files 60 · records 3377 · trace entries 5743 · bytes 1031658 · differing 0)
```

   Decir: "60 archivos por caso, un millón de bytes en el caso completo, 5.743 entradas de traza: cada párrafo que el COBOL ejecutó, en el mismo orden, el Java lo ejecutó también".

6. **MOMENTO 1, reanudación.** Enter. Aparece el registro del caso 05:

```
JOB NIGHTLY RUN 1
STEP 07 POSTTRAN RC=0004
ABEND AFTER INTCALC (injected)
JOB NIGHTLY RUN 2
STEP 01 LOAD-ACCTFILE SKIPPED (COMPLETED IN RUN 1)
...
STEP 09 INTCALC SKIPPED (COMPLETED IN RUN 1)
JOB NIGHTLY END MAXRC=0004
```

   Decir: "matamos el job después de calcular intereses; la segunda corrida saltea lo ya hecho y termina. Los archivos finales son idénticos a la corrida sin corte, en COBOL y en Java, y el chequeo lo exige."

7. **MOMENTO 2, el defecto fiel.** Enter. Aparece la cuenta 5 de la salida de referencia:

```
cuenta 5 saldo 1182.86 crédito del ciclo 1266.85 débito del ciclo -428.99
```

   Decir: "el programa de intereses nunca actualiza la última cuenta: le escribe la transacción de interés pero el saldo no cambia y los acumulados del ciclo no se reinician. Es un error del programa original. Lo tradujimos tal cual, porque la regla 5 dice que no mejoramos el COBOL antes de probar equivalencia, y le preguntamos al banco qué quiere hacer." Abajo salen los tres lugares donde está escrito: la especificación, la guía de párrafos y el comentario en el Java (`IntCalcProgram.java:123`). Señalarlos: "no está escondido, está en tres documentos".

8. **MOMENTO 3, ¿tradujimos todo?** Enter. Aparece la cobertura:

```
Coverage from the paragraph traces: 82 / 86 paragraphs of 14 programs ...
Not reached by any fixture: CBTRN02C.9999-ABEND-PROGRAM, ...
```

   Decir: "82 de 86 párrafos los ejecuta algún caso de prueba; los cuatro que faltan son los de caída por error de archivo, y los listamos en vez de esconderlos." Después se abre solo el visor en el navegador. En él, no más de 30 segundos:

   - Leer el resumen del programa arriba a la izquierda.
   - Clic en una fila azul, por ejemplo `1300-COMPUTE-INTEREST`. El panel derecho salta al Java y marca la línea.
   - Leer la línea "Qué hace" debajo del párrafo: "Interés del mes = saldo × tasa anual / 1200, sin redondeo: se trunca hacia cero al centavo".
   - Clic en una cita `COBOL:` del Java: el panel izquierdo vuelve a esas líneas.

   Decir: "esto es para el auditor: elige un párrafo y ve el Java que lo traduce, con la regla en lenguaje llano y la sección de la especificación".

9. Volver a la terminal, Enter. `RESULTADO — Módulo 3 (cierre nocturno, 4 pasos JCL): 6 / 6 casos de prueba idénticos byte a byte ✅`.

### 2.4 Agentic evals 1: el sabotaje (5 minutos)

```bash
./tools/demo-commands.sh negative-control --step
```

**Qué contar.** Un verde vale solo si el rojo es posible. Vamos a romper el Java a propósito dos veces, de las dos formas en que un revisor humano dejaría pasar el cambio.

**Qué esperar.**

1. Cabecera `Control negativo: ¿el agentic eval detecta una traducción equivocada?`. Enter.
2. `sabotaje 1: RoundingMode.DOWN → HALF_UP en InterestCalculator.monthlyInterest: una palabra`. Enter. Aparece el `git diff`, una línea menos y una línea más. Decir: "una palabra: redondear en vez de truncar. En una revisión de código pasa."
3. Corre el caso 03 en Java (unos 20 segundos) y la comparación. Aparece `[FAIL] nightly-batch/03-numeric-boundaries (... differing 37)`, un diff largo, y al final el resumen aislado en rojo:

```
En una línea — qué dice el agentic eval que está mal:
    record 1 (ACCT-ID=1): ACCT-CURR-BAL cobol=201.75 java=201.76
    record 2 (ACCT-ID=2): ACCT-CURR-BAL cobol=-772.48 java=-772.49
    record 1 (TRAN-ID=2022071800000001): TRAN-AMT cobol=0.09 java=0.10
```

   Decir: "no dice 'byte 23 difiere'. Dice: cuenta 1, saldo, COBOL 201.75, Java 201.76. Un centavo, y lo nombra."

4. `revertir (git conserva el archivo real)`. Enter.
5. `sabotaje 2: 'arreglar' el defecto del COBOL: actualizar también la última cuenta`. Enter. Aparece el diff con la línea `if (!firstTime) calc.updateAccount(...)   // SABOTAGE: the 'obvious fix'`. Decir: "ahora el sabotaje es una mejora bien intencionada: corregir el error del original."
6. Corre el caso 01 y la comparación. `[FAIL] nightly-batch/01-happy-small (... differing 165)` y el resumen:

```
record 5 (ACCT-ID=5): ACCT-CURR-BAL cobol=1182.86 java=1198.69
record 5 (ACCT-ID=5): ACCT-CURR-CYC-CREDIT cobol=1266.85 java=0.00
record 5 (ACCT-ID=5): ACCT-CURR-CYC-DEBIT cobol=-428.99 java=0.00
trace: first divergence at entry 68: cobol [CBACT04C Paragraph 1000-TCATBALF-GET-NEXT] vs java [CBACT04C Paragraph 1050-UPDATE-ACCOUNT]
```

   Decir: "la cuenta 5 es la de hace un rato. Y la traza dice en qué párrafo se separaron los caminos: el Java entró a actualizar la cuenta donde el COBOL fue a leer el siguiente registro. El harness protege al banco también de las mejoras."

7. `revertir y volver al verde`. Enter. Corren los seis casos (un minuto) y salen seis `[OK ]`.

### 2.5 Agentic evals 2: el agente validador en vivo (3 minutos)

```bash
./tools/demo-commands.sh agentic-eval
```

Si no hay red o no se quiere arriesgar: `./tools/demo-commands.sh agentic-eval --replay` reproduce la grabación de una corrida real, al mismo ritmo. Si la llamada en vivo falla o no termina en verde, el script cae solo a la grabación y lo dice.

**Qué contar.** Hasta ahora corrimos nosotros los comandos. En el harness, la verificación la corre un agente de solo lectura, y lo que hace está versionado en el repositorio.

**Qué esperar.**

1. Cabecera `Agentic eval: el validador es un agente`. Debajo, la definición del agente tal como está en el repo: `tools: Bash, Read, Grep` y sus restricciones ("no modifica fuentes", "no afloja el comparador", "no saltea pasos", "no especula"). Decir: "esto es el agente. Tres herramientas, cuatro prohibiciones, y una lista cerrada de comandos que puede ejecutar." Enter.
2. La línea `$ claude -p "Validá el módulo nightly-batch e informá..." --agent equivalence-validator --output-format stream-json` y la cabecera `agente: equivalence-validator · modelo: ... · herramientas: Bash, Read, Grep`.
3. Durante unos 80 segundos: líneas `🤖` con lo que el agente dice ("Empiezo por identificar el tipo de módulo..."), líneas `$` con los comandos que corre (`run-cobol.sh`, `run-java.sh`, `compare-outputs.py`), y el final de cada resultado en gris. Decir mientras corre: "nada está guionado; el agente decide el orden. Fíjense que primero mira qué tipo de módulo es, después corre el COBOL, después el Java, después compara, después lee el informe."
4. Al final: `turnos: 10 · duración: 82s` (puede variar), el `INFORME DEL AGENTE` con los seis `[OK]`, los totales (341 archivos, 4.852 registros, 1.370.179 bytes, 7.884 entradas de traza, 0 distintos) y la línea verde `RESULT: GREEN`. Cierra con: "El agente corrió los dos lados y los comparó; una persona lee el informe y firma el verde."

**Qué decir.** "Esto es un agentic eval: el agente ejecuta, compara y entrega un informe legible por máquina y por personas. La decisión sigue siendo de una persona."

### 2.6 Checklist de proceso y prueba final (3 minutos)

```bash
./tools/demo-commands.sh conformance
```

**Qué esperar.** Para cada módulo, una lista de `[PASS]` con algunos `[WARN]` en amarillo y al final `RESULT: CONFORMANT` por módulo, cinco de cinco. Decir: "los amarillos son reales y a propósito: los módulos viejos tienen menos casos de prueba de los que el proceso pide hoy, y el chequeo lo dice. Lo que no hay es ningún rojo."

```bash
./tools/demo-commands.sh proof
```

**Qué esperar.** Una tabla por módulo con `diffs: []` en cada caso y, al final, los totales calculados desde los informes, no escritos a mano:

```
TOTAL 15/15 fixtures byte-exact · records 4932 · bytes 1374520 · differing 0
En castellano: 15 casos de prueba · 4.932 registros y 1.37 MB comparados · 0 bytes distintos
```

Decir: "quince casos, casi cinco mil registros, un megabyte y medio comparado byte a byte, cero distintos. Este número sale del informe de los agentic evals, no de una slide."

Nota: el deck cuenta 12 casos y 4.914 registros porque deja afuera el módulo 2 (el convertidor CCI); la terminal muestra 15 y 4.932 porque lo incluye. Si alguien lo nota, esa es la explicación.

---

## 3. Si querés explorar más (opcional, para preguntas)

```bash
./tools/demo-commands.sh explore nightly-batch   # los 15 artefactos del módulo, numerados; un número los abre
./tools/demo-commands.sh viewer nightly-batch    # abre el visor en el navegador
./tools/demo-commands.sh deps nightly-batch      # abre el grafo de dependencias del COBOL en el navegador
```

Útiles cuando preguntan "¿y la especificación?", "¿y el grafo de dependencias?", "¿dónde están los casos de prueba?".

---

## 4. Preguntas difíciles y la respuesta corta

- **"¿Tradujeron un error a propósito?"** Sí, dos, y mostramos la línea exacta. Regla 5: no mejoramos el COBOL antes de probar equivalencia. El Java los reproduce, los cita, y la especificación le pregunta al banco si son intencionales. Cuando "arreglamos" uno como control negativo, el diff se puso rojo en la cuenta 5.
- **"¿Qué prueba el diff y qué no?"** Prueba que, para cada caso de prueba, el Java produce exactamente los mismos bytes que el COBOL en todos los canales. No prueba comportamiento fuera de los casos de prueba, ni rendimiento, ni que el COBOL fuera correcto.
- **"¿El harness encuentra todo?"** No, y esta semana lo vimos: al escribir la guía de párrafos de los módulos viejos, leyendo el COBOL con lupa, aparecieron dos diferencias que ningún caso de prueba cubre: un desborde silencioso en el cálculo de la prima del módulo 0 y un acumulador que no se reinicia entre llamadas en el módulo 2. El diff solo ve lo que los casos ejercitan. La respuesta del harness es agregar el caso, no confiar en la lectura. Decirlo de frente da más credibilidad que esconderlo.
- **"¿Por qué no una herramienta comercial?"** Traducen sintaxis y producen Java que compila. No prueban que se comporte igual. Los errores que atrapamos (redondeo, inserción que no falla con clave repetida, dígito de control) habrían salido a producción.
- **"¿Cómo intervino Claude Code?"** Leyó el COBOL, leyó las reglas del harness (versionadas en el repo), escribió el Java bajo esas reglas, y una persona corrió los agentic evals y decidió qué hacer con cada rojo.
- **"¿Y el rendimiento?"** No se midió; GnuCOBOL en una laptop no es base de comparación. Es el siguiente paso, con la misma red de seguridad.
- **"¿Por qué no hay traducción en vivo?"** Porque el valor no está en ver escribir Java, está en poder verificarlo. La traducción es el paso rápido; la verificación es lo que una auditoría necesita.

Más respuestas, en inglés y con enlaces, en [DEMO.md](./DEMO.md) sección 6.

---

## 5. Si algo sale mal

| Síntoma | Qué hacer |
|---|---|
| Un `[FAIL]` inesperado en un módulo | No reiniciar. Leer el bloque "En una línea" o el diff. Decir qué campo y qué cuenta difieren. Es la demo del harness funcionando. Después de la charla, investigar. |
| `agentic-eval` tarda más de 3 minutos o falla | El script cae solo a la grabación. Si no lo hace, Ctrl+C y correr `agentic-eval --replay`. |
| El navegador no abre el visor | Abrir a mano `cobol/nightly-batch/traceability.html` (está en la lista de artefactos de la fase D, ítem con estrella). |
| Los links de la terminal no son clicables | Es la terminal: en modo `--step` escribir el número del artefacto y Enter lo abre igual. |
| Maven compila lento la primera vez | Por eso existe `preflight`: correrlo antes deja todo compilado y en caché. |
| Se editó el script mientras corría | No hacerlo: bash lee el archivo a medida que ejecuta y da errores fantasma. |
