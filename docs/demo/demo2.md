# Deck 3 — "El harness acelera, las personas deciden, los agentic evals son el contrato"

Guion (storyline) para el deck HTML de la demo a gerentes y gerentes técnicos de un banco. 30-40 minutos, 14 slides. Cada slide trae: eyebrow (la frase chica arriba del título), el título como una oración, el mensaje clave, el cuerpo tal como debe aparecer y las notas para el presentador.

## Qué cambió respecto de la versión anterior (y por qué)

| Cambio | Por qué |
|---|---|
| **"Harness" en lugar de "framework" / "método"** en todo el deck, y una slide dedicada (slide 4) que muestra de qué está hecho: Claude Code, skills por fase, un subagente validador, hooks y modo sin intervención (`claude -p`), sin API keys. | Queremos mostrar que somos expertos en IA y agentes, no solo en COBOL. El harness se presenta como **acelerador con artefactos auditables**, nunca como una caja que hace todo sola. |
| **"Agentic evals"** es el nombre de las validaciones de equivalencia en títulos y etiquetas (slides 1, 3, 5, 6, 7, 10 a 14). | Las validaciones las corre un agente y entrega un informe legible por máquina; el término las distingue de las pruebas unitarias escritas a mano. |
| **Menos técnico, más explicativo**: el estilo vuelve al del primer deck (cards por módulo, una idea por slide, menos tablas densas). Cada término técnico aparece una vez y explicado en pocas palabras. Sin "SME" (es "analista del banco"), sin "fixture" (es "caso de prueba"), sin "golden master" sin explicar (es "la salida de referencia del COBOL"), sin "conformant" (es "cumple el proceso"). | La versión anterior era más técnica y explicaba peor. El público son gerentes y gerentes técnicos de banca. |
| **El cierre nocturno entra como cuarta card** en la slide de cobertura del mainframe (junto a VSAM, DB2 y CICS) y conserva su slide propia (acto 3). El convertidor CCI (módulo 2) no forma parte de este deck. | La slide "tres módulos, tres validaciones" del primer deck era la mejor para explicar el ecosistema; ahora son cuatro aristas del mainframe. |
| **Dos slides recuperadas del primer deck** porque explicaban mejor los artefactos: "El loop. Versionado en markdown." (slide 5, oscura: los cinco pasos del loop y los archivos markdown del harness) y "Cada fase produce un artefacto auditable." (slide 6: cinco cards A–E con fragmentos reales del módulo 1B). La segunda reemplaza la tabla de "Cinco fases, cinco artefactos"; el deck pasa de 13 a 14 slides. | El usuario juzgó que esas dos slides del primer deck explicaban mejor qué queda en el repositorio y cómo se genera el Java. |
| Cada programa COBOL se explica primero por **lo que hace para el negocio** y después por la arista técnica que cubre. | Que quede claro por qué cada programa es un caso de uso real y no un ejemplo de juguete. |

Reglas del guion:

- Mensaje de fondo: **el harness acelera la traducción; las personas deciden en cada fase; cada fase deja un artefacto auditable; los agentic evals (comparación byte a byte COBOL contra Java) son el contrato.** Nunca decir ni sugerir que la herramienta hace todo sola.
- Alcance: 4 módulos (0, 1B, 1A, 3), 12 casos de prueba (3 + 2 + 1 + 6), 4.914 registros y 1,37 MB comparados, 0 bytes distintos. Las cifras salen de `validation/reports/*.json`, no se escriben a mano.
- Nada se inventa en vivo: todos los comandos de la slide 13 están en el repositorio y dan siempre el mismo resultado.

Fuentes: `docs/demo/DEMO.md`, `docs/demo/ACTO-3-VS-PROPUESTA.md`, `cobol/nightly-batch/README.md`, `cobol/nightly-batch/PARAGRAPHS.md`, `docs/methodology/DECISIONS.md` (ADR-8, ADR-13 a ADR-17), `docs/methodology/SKILLS-GUIDE.md`, `tools/demo-commands.sh`, `validation/reports/*.json`.

---

## Slide 1 — Título

**Eyebrow:** Harness COBOL → Java · Demo

**Título:** Migración COBOL → Java verificable.

**Mensaje clave:** El harness acelera la traducción; las personas deciden; los agentic evals demuestran, byte a byte, que el Java hace lo mismo que el COBOL.

**Cuerpo:**

> El harness acelera la traducción.
> Las personas deciden en cada fase.
> Cada fase deja un artefacto que se puede auditar.
> Los agentic evals son el contrato.

4 módulos · 12 casos de prueba · 0 bytes distintos

Programas públicos de dos sistemas de referencia: seguros (IBM GenApp) y tarjetas de crédito (AWS CardDemo).

**Notas para el presentador:**
Abrir con las cuatro líneas, no con la tecnología. Lo que no vendemos: "la inteligencia artificial escribe el Java y listo". Lo que sí: un harness (un andamiaje de agentes, reglas y comparadores) que hace el trabajo pesado, una persona que decide en cada punto de control, y una prueba mecánica, repetible y guardada de que el Java hace lo mismo que el COBOL. "0 bytes distintos" significa: para cada caso de prueba, todo lo que produce el Java (archivos, pantalla, códigos de retorno, tablas) es idéntico, byte por byte, a lo que produce el COBOL original. Los programas no son nuestros: son muestras públicas de IBM y de AWS que la industria usa para hablar de modernización.

---

## Slide 2 — El problema

**Eyebrow:** Por qué fracasan las migraciones

**Título:** Traducir es fácil. Demostrar que se comporta igual, no.

**Mensaje clave:** El riesgo de una migración no está en escribir Java, está en probar que el Java hace exactamente lo mismo que el COBOL.

**Cuerpo:**

Décadas de COBOL bancario. Migraciones que fracasan porque demostrar equivalencia es más difícil que traducir el código.

| | | |
|---|---|---|
| 01 ✓ | Leer COBOL | Los modelos de lenguaje lo resuelven a bajo costo. |
| 02 ✓ | Escribir Java moderno | Los modelos de lenguaje lo resuelven a bajo costo. |
| 03 ✕ | Demostrar que el código nuevo se comporta idéntico al viejo | Ningún modelo lo resuelve solo. Es donde toda migración real se rompe y donde se concentra el riesgo regulatorio. |

> Sin prueba de equivalencia, "aproximadamente correcto" se vuelve auditorías, multas y un cálculo de interés silenciosamente equivocado en producción.

**Notas para el presentador:**
Esta slide se mantiene del primer deck porque sigue siendo cierta. El punto 03 es el corazón: ninguna herramienta, ni comercial ni de IA, demuestra sola que el sistema nuevo hace lo mismo. Lo que sí se puede hacer es construir un banco de pruebas que corra los dos sistemas con los mismos datos y compare las salidas byte por byte; eso es lo que llamamos agentic evals y es lo que vamos a mostrar. Anticipar la frase "aproximadamente correcto": en banca, un centavo de diferencia en el interés de una cuenta es un hallazgo de auditoría, no un detalle.

---

## Slide 3 — Quién hace qué

**Eyebrow:** División del trabajo

**Título:** El harness acelera. La persona decide.

**Mensaje clave:** En cada fase hay una tarea mecánica que hace un agente del harness y una decisión que toma una persona del banco o del equipo.

**Cuerpo:**

| Fase | Hace el agente | Decide la persona |
|---|---|---|
| A · Descubrimiento | Lee el COBOL, arma el mapa de programas y archivos, propone los casos de prueba, corre el COBOL original y guarda su salida como referencia | Confirma el inventario, aporta y valida los datos de prueba, aprueba qué casos cubren qué reglas |
| B · Especificación | Redacta la especificación en lenguaje de negocio a partir del COBOL, con una línea "qué hace" por cada párrafo del programa | El analista del banco la revisa, corrige y responde las preguntas abiertas ("¿este comportamiento es intencional?") |
| C · Traducción | Escribe el Java siguiendo las reglas acumuladas, con cada método citando el COBOL que lo originó | Revisa las decisiones de diseño y las aprueba o las cambia |
| D · Agentic evals | Corre COBOL y Java con los mismos datos, compara byte a byte y entrega un informe | Lee cada diferencia y decide: ¿error del Java, caso de prueba faltante o comportamiento del COBOL que no conocíamos? Firma el verde |
| E · Captura | Propone nuevas reglas de traducción a partir de lo aprendido | Aprueba la regla que pasa a aplicarse en el módulo siguiente |

**Notas para el presentador:**
Recorrer la tabla fila por fila. Insistir: el agente nunca aprueba nada; cada "verde" lo firma una persona después de mirar el resultado. Ejemplo para la fila B: en el cierre nocturno, la especificación le pregunta al analista del banco si es intencional que la última cuenta no reciba interés (slide 9). Ejemplo para la fila D: la primera corrida del Java en ese módulo dio rojo en 22 bytes de relleno por registro; la persona tuvo que decidir si era un error del Java o una regla del COBOL que faltaba documentar (era lo segundo). Ejemplo para la fila E: el redondeo por defecto del COBOL no es el que uno supone; quedó escrito como regla y no se vuelve a discutir.

---

## Slide 4 — El harness

**Eyebrow:** De qué está hecho

**Título:** Un harness de agentes, no una caja mágica.

**Mensaje clave:** El harness es Claude Code más reglas versionadas, una skill por fase, un subagente que valida y corridas sin intervención; todo auditable, sin API keys.

**Cuerpo:**

| Pieza | Qué es | Para qué sirve |
|---|---|---|
| Claude Code | El agente que lee, escribe y ejecuta, dentro del repositorio | Hace el trabajo pesado de cada fase bajo reglas escritas |
| Reglas en markdown versionado | `CLAUDE.md` (reglas duras), glosario de equivalencias COBOL → Java, decisiones documentadas (ADR) | Un ingeniero nuevo o un auditor puede leer exactamente qué restricciones aplicaron |
| Una skill por fase | `cobol-analyze` (A) · `cobol-spec` (B) · `java-translate` (C) · `equivalence-validate` (D) | Cada fase tiene su procedimiento, sus entradas y su entregable; no hay salto de fase |
| Subagente `equivalence-validator` | Solo lectura: corre el COBOL, corre el Java, compara y responde VERDE o ROJO | No puede tocar el Java ni el comparador; nunca puede "aflojar" la prueba |
| Hooks y modo sin intervención (`claude -p`) | Corridas repetibles desde la terminal o un pipeline | La verificación se vuelve a correr igual, sin que nadie la escriba a mano |
| Sin API keys | Corre sobre Claude Code con una suscripción | Sin infraestructura extra ni costo por token; el repositorio ya es el contexto |

> El harness es un acelerador. Lo que entrega no es "confianza": son artefactos que una persona puede abrir, leer y firmar.

**Notas para el presentador:**
Esta es la slide donde mostramos que entendemos de agentes. La idea central: la inteligencia artificial no está suelta; está dentro de un harness que le fija reglas (markdown versionado), le da un procedimiento por fase (skills) y le pone un verificador aparte (el subagente, que es de solo lectura por diseño: tiene permiso de ejecutar y leer, no de editar). Lo que hace la skill de la fase C, por ejemplo: exige `BigDecimal` para todo número, exige un comentario `// COBOL: archivo:línea` en cada método y rechaza la traducción si falta cualquiera de los dos, aunque compile. Decir de frente por qué no API keys: a esta escala el repositorio ya es el contexto (glosario, skills, especificaciones); una capa más sería indirección sin valor, con costo e infraestructura extra. Si preguntan "¿y si el modelo inventa código?": lo atrapan los agentic evals (slide 10), que no miran si el Java es lindo, miran si los bytes coinciden.

---

## Slide 5 — El loop

**Eyebrow:** Cómo generamos el Java

**Título:** El loop. Versionado en markdown.

**Mensaje clave:** El Java del repositorio es la salida de un loop de cinco pasos cuyas reglas están en archivos de texto versionados; cualquiera puede auditarlas.

**Cuerpo (slide oscura):**

```
01  Leer el COBOL
02  Leer el harness              CLAUDE.md · glossary.yaml · skills/*
03  Escribir el Java             BigDecimal · trazabilidad · Spring
04  Agentic eval: comparación byte a byte contra la salida de referencia del COBOL (golden master)
      ↳ rojo  → volver al paso 03
      ↳ verde → paso 05
05  Capturar la lección          entrada en el glosario + ADR · el próximo módulo la aprovecha
```

**El harness en markdown**

| Archivo | Qué es |
|---|---|
| `CLAUDE.md` | Reglas duras no negociables: `BigDecimal`, trazabilidad, el COBOL es la verdad |
| `docs/methodology/glossary.yaml` | Cada idiom COBOL mapeado a su equivalente Java |
| `.claude/skills/*/SKILL.md` | Instrucciones por fase: analyze, spec, translate, validate |
| `.claude/agents/equivalence-validator.md` | El agente de solo lectura que corre los agentic evals |

> Un ingeniero nuevo puede auditar qué reglas aplicamos. El agente escribe; el harness verifica; la persona decide.

**Notas para el presentador:**
Esta es la respuesta a "¿cómo se escribió el Java?": el agente leyó el COBOL, leyó el harness (las reglas duras, el glosario de equivalencias y la skill de la fase) y escribió el Java bajo esas reglas. Después corrió el agentic eval contra la salida de referencia del COBOL. Las dos ramas del paso 04 son el corazón del loop: rojo devuelve al paso 03 (se corrige el Java, nunca el comparador); verde habilita el paso 05, donde la lección se escribe en el glosario y en una decisión documentada (ADR) para que el próximo módulo arranque sabiéndola. Lo que se audita está en la columna de la derecha: cuatro archivos de texto, versionados en el repositorio. Un ingeniero nuevo o un auditor los lee y sabe exactamente qué restricciones aplicaron, sin preguntarle a nadie. El Java del repositorio es la salida de este loop, no texto libre de un modelo.

---

## Slide 6 — Los artefactos

**Eyebrow:** Los artefactos

**Título:** Cada fase produce un artefacto auditable.

**Mensaje clave:** Cada fase deja un entregable concreto en el repositorio, con contenido real, que se puede revisar sin correr nada.

**Cuerpo (cinco cards; los fragmentos son del módulo 1B, la póliza en base de datos):**

**A · Discovery — Salida de referencia (golden master).** Captura cada byte que el COBOL produce: pantalla, código de salida, archivos de salida. Es la *fuente de verdad* contra la que se mide todo lo demás.

```
golden-master/add-policy-db/
└── 01-happy-small/
    ├── stdout.txt
    ├── exit_code          # 0
    └── out/policy.csv
        1000000001|1234567890|
        2026-01-15|...
```

**B · Spec — Markdown estructurado.** Documento que un analista del banco puede leer sin tocar COBOL. Cada construcción del original aparece mapeada a su contraparte en Java. La fase B también produce `PARAGRAPHS.md`: qué hace cada párrafo, en lenguaje llano.

```
## 4. SQL contract

| # | Operation     | COBOL → Java
|---|---------------|----------------
| 1 | Insert one row| INSERT INTO POLICY
|   |               | → em.persist + flush
| 2 | Schema reset  | DROP + CREATE shim
|   |               | → schema.sql
```

**C · Translation — Java + trazabilidad.** Java moderno (Spring Boot + JPA) con un comentario que apunta a las líneas exactas del COBOL original. Auditoría línea por línea posible.

```java
/** Mirror of INSERT-POLICY
    in lgapdb01.cbl:261-322. */
@Transactional(propagation = REQUIRES_NEW)
public void insert(PolicyEntity p) {
    em.persist(p);
    em.flush();
}
```

**D · Validation (card destacada, borde verde) — Informe JSON de los agentic evals.** **La prueba de equivalencia.** JSON con cero diferencias por caso de prueba: evidencia archivable para cumplimiento y auditoría.

```json
[
  { "fixture": "01-happy-small", "module": "add-policy-db", "diffs": [] },
  { "fixture": "02-sql-errors",  "module": "add-policy-db", "diffs": [] }
]
```

**E · Captura en el harness — Entrada de glosario · ADR.** Cada lección se vuelve una regla. El próximo módulo arranca con todo lo aprendido: el harness no olvida.

```yaml
exec_sql_insert:
  target: "EntityManager.persist(entity); em.flush()"
  avoid:  "JpaRepository.save — INSERT-OR-UPDATE"
  note:   "See ADR-9."
```

**Notas para el presentador:**
Cinco artefactos, uno por fase, todos en el repositorio y todos reales: los fragmentos son del módulo 1B. El orden importa: nadie empieza a traducir antes de tener la salida de referencia (A) guardada; el COBOL es la verdad, no la especificación, y si difieren se corrige la especificación. Elegir tres para contar. (A) La salida de referencia: cada byte que el COBOL produjo, congelado como evidencia. (C) El comentario de trazabilidad: si un auditor pregunta de dónde sale una regla, la respuesta es una línea de COBOL con número. (D) El informe JSON: `"diffs": []` es el contrato; cualquier cosa que no sea vacío detiene la migración. (E) es lo que hace que el harness mejore con cada módulo: la lección del módulo 1B (guardar no es insertar) quedó como entrada del glosario y como ADR-9, y el módulo siguiente ya no puede cometer ese error. Nada de esto requiere correr nada para auditarlo.

---

## Slide 7 — Qué parte del mainframe cubrimos

**Eyebrow:** Cobertura del mainframe

**Título:** Cuatro módulos. Cuatro aristas del mainframe.

**Mensaje clave:** Cuatro programas públicos cubren archivos, base de datos, orquestación entre programas y batch nocturno; y decimos de frente lo que todavía no cubrimos.

**Cuerpo (cuatro cards):**

| Módulo | Programa | Qué hace para el negocio | Arista del mainframe | Casos |
|---|---|---|---|---|
| 0 · VSAM | `ADDMPOL` (seguros, IBM GenApp) | **Alta de pólizas de auto en lote**: lee solicitudes, valida cliente, cilindrada, valor del vehículo y fechas, calcula la prima con redondeo comercial y graba póliza, vehículo y un registro de errores | Archivos de registros de largo fijo, leídos y escritos en secuencia (VSAM) | 3 |
| 1B · DB2 | `ADDPOLDB` (GenApp) | **Guardar la póliza en la base de datos**: la misma alta, insertando en una tabla y rechazando la clave duplicada | Base de datos con SQL embebido y manejo de códigos de error (DB2) | 2 |
| 1A · CICS | `ADDPFCD` (GenApp) | **La fachada que orquesta**: un programa recibe la solicitud, la valida y le pasa el control al programa de base de datos | Un programa invoca a otro y recibe el resultado (CICS LINK) | 1 |
| 3 · BATCH | `CBTRN02C` · `CBACT04C` · `CBTRN03C` (tarjetas, AWS CardDemo) | **El cierre nocturno de una cartera de tarjetas**: contabilizar las transacciones del día, cobrar el interés mensual, reconstruir el maestro, imprimir el reporte diario | Trabajo de varios pasos (JCL), archivos indexados actualizados en el lugar, ordenamientos, reanudación tras caída, código de error | 6 |

> Mismo harness. Mismos agentic evals. Cuatro preocupaciones distintas del mainframe.

**Notas para el presentador:**
Contar primero qué hace cada programa para el negocio, después la arista técnica. Módulo 0 es la puerta de entrada: un batch de seguros con reglas de validación y una fórmula de prima. Módulos 1B y 1A son el mismo negocio (alta de póliza) resuelto de las dos formas en que un mainframe lo hace: contra base de datos y a través de un programa orquestador. Módulo 3 es el salto de escala: tres programas de un core de tarjetas, tomados sin tocar una línea, corriendo como un trabajo de cuatro pasos. Frase a evitar: "esto cubre todo lo que hace un sistema COBOL". No: cubre cuatro aristas frecuentes.

---

## Slide 8 — Acto 3: el cierre nocturno

**Eyebrow:** Módulo 3 · AWS CardDemo

**Título:** Un día en el banco, de noche.

**Mensaje clave:** Un trabajo real de cuatro pasos, con reanudación tras caída y caída con código de error, corre idéntico en COBOL y en Java.

**Cuerpo:**

| Paso | Programa | Qué hace para el negocio |
|---|---|---|
| 1 · Contabilizar | `CBTRN02C` | Toma las transacciones del día; verifica que la tarjeta y la cuenta existan, el límite de crédito y el vencimiento; actualiza saldo y acumulados; los rechazos salen con motivo |
| 2 · Intereses | `CBACT04C` | Calcula el interés mensual por cuenta con la tasa de su grupo (o la tasa por defecto), lo suma al saldo y genera una transacción de interés |
| 3 · Reconstruir | ordenar + recargar | Une las transacciones del día con las de interés, las ordena y reconstruye el maestro |
| 4 · Reporte | ordenar + `CBTRN03C` | Filtra por fechas, ordena por tarjeta e imprime el reporte diario con totales por cuenta, por página y general |

- 4 pasos de negocio = 16 pasos técnicos en el guion del trabajo (`job.json`, el análogo del JCL, que leen los dos lados).
- 6 casos de prueba: normal · rechazos · bordes numéricos · volumen (50 cuentas, 300 transacciones, 18 páginas) · **reanudación** · **caída**.
- Por caso, 60 archivos comparados. En total: 4.852 registros, 1,37 MB y 7.884 entradas de traza, 0 bytes distintos.

**Notas para el presentador:**
Lo que esto responde: "¿y el batch de verdad, con JCL de varios pasos, archivos que se actualizan en el lugar, ordenamientos y reinicio?" El guion del trabajo está escrito una sola vez, en un archivo que lee tanto el lado COBOL como el lado Java: orden de pasos, archivos, códigos de retorno y reglas de reanudación no pueden divergir. Reanudación: un caso mata el trabajo después del paso 2 y lo reanuda; la salida final tiene que ser idéntica a la corrida sin corte, de los dos lados, y el comparador lo exige. Caída: otro caso introduce una categoría sin tasa; el programa de intereses cae con código 12, los pasos siguientes quedan "NO EJECUTADO", los pasos de captura corren igual, y el código final es 12 en los dos lados. Tres honestidades: (1) los programas son públicos y sin modificar, pero el entorno del mainframe (JCL, utilitarios, ordenador, runtime) se reemplaza por piezas chicas y documentadas; (2) los datos usan el formato de signo del mainframe (overpunch zonado), no el formato empaquetado (COMP-3) en archivo; (3) la reanudación prueba "misma salida final", no "mismo mecanismo de checkpoint".

---

## Slide 9 — Traducimos los errores a propósito

**Eyebrow:** Regla 5 del harness: no refinar el COBOL antes del verde

**Título:** Traducimos los errores a propósito. Y decimos dónde están.

**Mensaje clave:** El cierre nocturno trae dos defectos reales de legado; el Java los reproduce, los cita, y la especificación le pregunta al banco si son intencionales.

**Cuerpo:**

| Defecto | Dónde | Qué pasa | Cómo se ve |
|---|---|---|---|
| D1 | `CBACT04C.cbl:219-221` | La última cuenta recibe su transacción de interés, pero su saldo nunca se actualiza ni se reinician sus acumulados (una rama que nunca se ejecuta) | Cuenta 5 en los casos chicos; cuenta 50 en el caso completo |
| D2 | `CBTRN03C.cbl:197-204` | Al llegar al final del archivo, el reporte vuelve a sumar el último importe: el total general queda inflado y la última tarjeta no tiene total de cuenta | Caso completo: total general 79.254,29 contra 79.233,86 real (diferencia 20,43, el último importe) |

Preguntas que la especificación le hace al analista del banco:

1. ¿Es intencional que la última cuenta nunca reciba su interés ni reinicie sus acumulados? Hoy el mainframe se comporta así.
2. El total general del reporte supera la suma de sus líneas por el importe de la última. ¿Alguien lo está conciliando?

**Notas para el presentador:**
Respuesta ensayada a "¿tradujeron un error a propósito?": "Sí, dos, y podemos mostrar la línea exacta. La regla del harness dice: no refinar el COBOL antes de que los agentic evals estén en verde. El Java reproduce los dos, los cita, y la especificación le pregunta al banco si son intencionales. Cuando 'arreglamos' el primero como prueba de sabotaje, el diff se puso rojo en la cuenta 5: el banco de pruebas también protege al banco de mejoras bien intencionadas." División del trabajo: el agente encontró y documentó los defectos; la decisión de qué hacer con ellos (mantener, corregir después del verde, conciliar) es del banco. Esto es lo que una traducción sintáctica comercial nunca entrega: no solo Java que compila, sino una lista de preguntas de negocio con número de línea.

---

## Slide 10 — Agentic evals: la prueba de sabotaje

**Eyebrow:** Control negativo · rompemos el Java a propósito

**Título:** Agentic evals: un centavo alcanza para ponerlo en rojo.

**Mensaje clave:** Un agente corre COBOL y Java con el mismo caso, compara byte a byte todos los canales y nombra cuenta, campo y centavo; cambiamos una sola cosa a propósito y lo detecta.

**Cuerpo:**

**Qué es un agentic eval**, en cuatro pasos: el agente corre el COBOL y el Java con el mismo caso de prueba → compara byte a byte todos los canales (archivos, pantalla, códigos de retorno, tablas y el recorrido de párrafos) → entrega un informe JSON con registro, campo y los dos valores → una persona lo lee y aprueba el resultado.

**Sabotaje 1 — un modo de redondeo.** Cambiamos truncar por redondear (`RoundingMode.DOWN` → `HALF_UP`) en el cálculo de interés.

> `registro 1 (ACCT-ID=00000000001): ACCT-CURR-BAL cobol=201.75 java=201.76`

Un centavo, en la cuenta 1. Rojo. Revertido: verde.

**Sabotaje 2 — "arreglar" el defecto D1.** Hacemos que la última cuenta sí reciba su interés.

> `cuenta 5: saldo cobol=1182.86 java=1198.69` (y los acumulados de ciclo)
> `traza: primera divergencia en la entrada 68 — cobol 1000-TCATBALF-GET-NEXT vs java 1050-UPDATE-ACCOUNT`

La verificación falla en el dato y en el recorrido del programa. Revertido: verde.

**Notas para el presentador:**
Es el momento más fuerte de la demo y conviene correrlo en vivo (`negative-control`, un minuto). Lo que demuestra: que la verificación detecta un error real. Si no detectara un centavo, no serviría para banca. El segundo sabotaje tiene un detalle nuevo: además de comparar los datos, comparamos el recorrido de párrafos de los dos programas (la traza de ejecución) y el informe dice en qué entrada se separan y qué párrafo tomó cada lado. Para un ingeniero eso convierte "hay un byte distinto" en "el Java fue a actualizar la cuenta cuando el COBOL ya había terminado de leer". Insistir en la división de trabajo: el agente corre y compara; una persona lee el informe y decide qué significa. Los dos sabotajes están documentados y revertidos; el repositorio vuelve a pasar la verificación completa.

---

## Slide 11 — Cómo los agentic evals encuentran divergencias

**Eyebrow:** Hallazgos reales, no teóricos

**Título:** Lo que los agentic evals atraparon y una lectura de código no.

**Mensaje clave:** Cada regla de traducción que tenemos nació de una divergencia concreta que el comparador detectó; ninguna la habríamos visto leyendo el Java.

**Cuerpo:**

| Hallazgo | Módulo | Qué pasó |
|---|---|---|
| El redondeo por defecto del COBOL no es el que supone Java | 0 | `350 + 112,50 + 50 = 512,50` → COBOL da **513**, Java daba 512. Regla fijada. |
| "Guardar" no es "insertar" | 1B | Ante clave duplicada el COBOL falla; el método estándar de Java sobreescribía en silencio. Regla fijada. |
| Un programa sin redondeo trunca | 3 | `0,09575` → `0,09`; `−11,4875` → `−11,48`. Lo contrario pone rojo un centavo. |
| Los bytes de relleno se conservan | 3 | La primera corrida del Java dio rojo en exactamente 22 bytes de relleno por registro creado. |

Cuatro instrumentos del banco de pruebas:

1. **Diferencia por campo**: antes `byte 24: E vs F`; ahora `registro 1: ACCT-CURR-BAL cobol=201.75 java=201.76`.
2. **Traza de párrafos**: el COBOL y el Java emiten el recorrido de párrafos; si difieren, el informe dice en qué entrada y qué párrafo tomó cada lado.
3. **Matriz de cobertura generada** desde las trazas reales: 82 de 86 párrafos del cierre nocturno ejecutados por algún caso; los 4 restantes son rutas de caída, listadas, no escondidas.
4. **Visor lado a lado COBOL ↔ Java**: un clic en un párrafo salta al Java que lo traduce; cada párrafo lleva una línea "Qué hace" en castellano para el analista del banco.

**Notas para el presentador:**
Mensaje central: estos hallazgos no salieron de leer código ni de pruebas unitarias escritas contra el Java; salieron de correr los dos lados y comparar. Un traductor comercial que solo verifica que el Java compila habría embarcado al menos los dos primeros. Lo nuevo: el informe ya no dice "byte 24 E contra F", dice el nombre del campo COBOL, el registro y los dos valores; y cuando el recorrido de párrafos difiere, dice en qué párrafo se separaron. Eso baja el tiempo entre "rojo" y "entendimos por qué" de horas a minutos, y es información que lee el analista del banco, no solo el programador. El visor (`traceability.html`) se abre en vivo en el tercer momento del módulo 3: no es código contra código, explica la tarea de cada párrafo.

---

## Slide 12 — Checklist de proceso

**Eyebrow:** Mismo harness, todos los módulos

**Título:** Mismo harness para todos los módulos: 12 controles, 4 de 4 cumplen.

**Mensaje clave:** Un comando verifica que cada módulo pasó por las cinco fases con los mismos artefactos; hoy los cuatro módulos cumplen el proceso.

**Cuerpo:**

| # | Control |
|---|---|
| 1 | El módulo documenta de dónde viene el COBOL y qué se mantuvo, adaptó o agregó |
| 2 | Existe el mapa de dependencias y su diagrama está sincronizado |
| 3 | Los programas declarados "sin modificar" son idénticos byte a byte al original |
| 4 | Hay casos de prueba definidos |
| 5 | Hay salida de referencia del COBOL para cada caso |
| 6 | Existe la especificación para el analista del banco |
| 7 | El Java no contamina la salida, cada clase cita su COBOL y no hay tipos numéricos inexactos |
| 8 | Los agentic evals están en verde y son más nuevos que las corridas |
| 9 | Las decisiones documentadas y el glosario citan al módulo |
| 10 | El módulo está en el guion de la demo |
| 11 | (batch) La corrida con reanudación produce lo mismo que la corrida sin corte |
| 12 | Recordatorio: una persona corre los agentic evals y firma el verde |

`./tools/check-module.sh --all` → cumple el proceso, 4 de 4

**Notas para el presentador:**
En el primer deck esta slide era una aspiración ("evaluación en cada paso"). Ahora es un script que corre en segundos. Verifica presencia y consistencia de los artefactos de proceso, no la equivalencia en sí (eso es el control 8, que lee el informe de los agentic evals). Destacar el control 3: los tres programas del cierre nocturno se comparan contra el original; si alguien tocara una línea, el módulo deja de cumplir. Destacar el control 12: es deliberadamente un recordatorio, no un chequeo automático; la firma del verde es humana por diseño. Esto es lo que permite escalar a un equipo: cualquier módulo nuevo tiene que pasar la misma checklist, y no depende de quién lo hizo.

---

## Slide 13 — Demo en vivo

**Eyebrow:** Todo reproducible, nada se traduce en vivo

**Título:** Lo que vamos a correr en vivo.

**Mensaje clave:** Cada comando reproduce una fase del harness con los artefactos ya existentes; no hay traducción en vivo y cualquier corrida da el mismo resultado.

**Cuerpo:**

```
./tools/demo-commands.sh module-0           # alta de pólizas en lote · 3 casos
./tools/demo-commands.sh module-1b          # póliza en base de datos · 2 casos
./tools/demo-commands.sh module-1a          # fachada que orquesta · 1 caso
./tools/demo-commands.sh module-3           # cierre nocturno · 6 casos + reanudación + defecto fiel
./tools/demo-commands.sh negative-control   # sabotaje: rojo → revertir → verde
./tools/demo-commands.sh agentic-eval       # el agente validador corre la verificación solo y entrega su informe
./tools/demo-commands.sh viewer nightly-batch   # abre el visor lado a lado COBOL ↔ Java y dice qué hacer con él
./tools/demo-commands.sh explore nightly-batch  # todos los artefactos del módulo, numerados; un número los abre
./tools/demo-commands.sh conformance        # checklist de proceso, 12 controles por módulo
./tools/demo-commands.sh proof              # informe de los agentic evals, totales calculados
```

Cada módulo son tres pasos: capturar la salida de referencia del COBOL → compilar y correr el Java → agentic evals byte a byte. Con `--step` el script narra en castellano, espera Enter antes de cada comando y, después de cada fase, lista los artefactos intermedios como links: el COBOL sin tocar, la especificación, qué hace cada párrafo, los casos de prueba, las salidas, el informe, el visor lado a lado. Un número los abre.

**Lo que prueba:** para cada caso de prueba, el Java produce exactamente los mismos bytes que el COBOL en todos los canales (pantalla, código de salida, archivos, tablas, registro del trabajo, traza de párrafos).

**Lo que no prueba:** comportamiento fuera de los casos de prueba · rendimiento · que el COBOL fuera correcto (lo traducimos fiel, errores incluidos).

**Notas para el presentador:**
Recorrido sugerido para 12-15 minutos: `module-0 --step` (rápido, muestra el patrón de tres pasos y los links a los artefactos), `module-3 --step` (el registro de la reanudación, el defecto fiel con sus tres lugares escritos, y al final el visor lado a lado: se abre solo en el tercer momento, o en cualquier momento con `viewer nightly-batch`, con la guía del presentador diciendo qué mostrar), `negative-control --step` (el momento rojo → verde, con el `git diff` del sabotaje y la línea roja sola), `agentic-eval` (el agente validador en vivo, unos 70 segundos; si falla la red, `--replay` reproduce la grabación), `proof` (la línea final con los totales calculados, nada escrito a mano). Decir explícitamente: no hay traducción en vivo. El Java ya está escrito y revisado; lo que se demuestra es que la verificación es mecánica y repetible. Si algo sale rojo en escena: no reiniciar, mostrar el informe de diferencias. "Parar la demo y mostrar el diff" es en sí una demostración de que el banco de pruebas es honesto. Si preguntan cómo intervino Claude Code: leyó el COBOL, leyó las reglas del harness (versionadas en el repositorio), escribió el Java bajo esas reglas, y una persona corrió los agentic evals y decidió qué hacer con cada rojo.

---

## Slide 14 — Alcance y próximos pasos

**Eyebrow:** Qué está hecho y qué falta

**Título:** Correctitud primero. Lo que sigue, con la misma red de seguridad.

**Mensaje clave:** La prueba de concepto demuestra equivalencia verificable en cuatro aristas del mainframe; lo que sigue es validar en el entorno real y medir rendimiento, con el mismo contrato.

**Cuerpo:**

**Hecho**

- 4 módulos · 12 casos de prueba · 4.914 registros y 1,37 MB comparados · 0 bytes distintos
- Pruebas de sabotaje: dos, en el cierre nocturno, documentadas y revertidas
- Checklist de proceso: 12 controles · 4 de 4 módulos cumplen
- Diferencias reportadas por campo y por párrafo; matriz de cobertura generada desde la ejecución real (82 de 86 párrafos del cierre nocturno)
- Visor lado a lado COBOL ↔ Java por módulo, con "qué hace" por párrafo
- Dos defectos de legado detectados, reproducidos y preguntados al banco

**Pendiente**

- Validar contra el mainframe real (hoy el COBOL corre en un compilador abierto, GnuCOBOL, en x86)
- Una corrida completa con entrada 100 % EBCDIC
- Pantallas interactivas (CICS online), IMS, MQ, cursores en batch
- Rendimiento con una línea base del mainframe

**La pregunta difícil: "¿y el rendimiento?"**

> Correctitud primero. Esta prueba de concepto demuestra correctitud, no rendimiento. Toda optimización posterior (particionar, paralelizar, cambiar el motor de base de datos) se hace con la misma red de seguridad: los agentic evals tienen que seguir en verde. GnuCOBOL en x86 no es una línea base válida del mainframe; medir rendimiento requiere la corrida original en z/OS.

**Notas para el presentador:**
Cerrar con la división de trabajo una vez más: lo que el harness aceleró (lectura, especificación, traducción, comparación) y lo que las personas decidieron (casos de prueba, reglas, qué hacer con cada rojo, qué hacer con los defectos). Sobre el pendiente más importante, la validación contra el mainframe real: la salida de referencia se produjo con un compilador abierto; una migración real tiene que correr el COBOL en el mainframe al menos una vez y confirmar que la referencia es la misma. Sobre rendimiento: no esquivar la pregunta, dar la respuesta tal como está en la slide. Propuesta de siguiente paso: elegir un programa del banco (no una muestra pública), correrlo en su mainframe para capturar la referencia, y repetir las cinco fases con el analista del banco en la fase B.
