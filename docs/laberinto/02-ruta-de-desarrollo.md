# Ruta de desarrollo

> Cada fase termina con una **puerta de decisión**: una pregunta concreta que responde sí o no.
> Si la respuesta es no, se ajusta o se corta antes de seguir. Nunca se pasa a la siguiente fase "por inercia".

## Resumen de fases

| Fase | Nombre | Objetivo | Duración estimada | Puerta de decisión |
|---|---|---|---|---|
| 0 | Prototipo de papel | Validar el dilema central sin código | 1 semana | ¿Decidir "mando ahora o espero" genera tensión? |
| 1 | Prototipo mínimo | Bucle base jugable con cuadrados y texto | 3 a 4 semanas | ¿Es divertido 20 minutos seguidos? |
| 2 | El laberinto se aprende | Patrón oculto y sala de mapas | 3 a 4 semanas | ¿Un jugador nuevo descubre al menos una regla solo? |
| 3 | Cada persona cuenta | Corredores con identidad y facciones | 3 a 4 semanas | ¿Perder un corredor cambia cómo juega la gente? |
| 4 | El laberinto responde | Reacción al comportamiento | 2 semanas | ¿El jugador nota que el laberinto "lo castiga o premia"? |
| 5 | Corte vertical | Una partida completa de inicio a fin, con arte provisional | 4 a 6 semanas | ¿Alguien que no eres tú quiere jugar otra vez? |
| 6 | Producción | Contenido, arte, sonido, balance | Según alcance | ¿Está listo para mostrarlo públicamente? |

Las duraciones asumen una persona trabajando medio tiempo. Son estimaciones para ordenar, no compromisos.

---

## Fase 0: Prototipo de papel

**Objetivo:** probar el dilema central antes de escribir una línea de código.

**Qué se hace:**

- Una cuadrícula de 9x9 en papel o en una hoja de cálculo. La ciudad en el centro.
- Fichas para 3 corredores. Un dado para simular hallazgos.
- Una regla de cambio fija y visible, por ejemplo: "cada 3 turnos las paredes de las filas pares se desplazan una celda".
- Jugar 5 partidas de 15 turnos con dos o tres personas.

**Entregables:**

- Reglas escritas en una página.
- Notas de cada partida: qué decisiones fueron difíciles, cuáles fueron obvias.

**Puerta de decisión:** ¿Al menos una vez por partida alguien dudó de verdad antes de mandar un corredor?
Si no, el ciclo es demasiado predecible o demasiado caótico. Ajustar N antes de seguir.

---

## Fase 1: Prototipo mínimo

**Objetivo:** el bucle de un turno funcionando en código, sin nada más.

**Alcance exacto (nada fuera de esta lista):**

- Cuadrícula de 15x15 con paredes y pasillos. Ciudad de 3x3 en el centro.
- Un tipo de cambio de laberinto, con regla fija y conocida.
- Tres recursos: comida, materiales, conocimiento.
- Dos edificios: huerto y taller.
- Un tipo de corredor, sin nombre ni atributos. Se mueve N celdas por turno por una ruta que el jugador traza.
- Hallazgos: escombros (materiales) y marcas (conocimiento).
- Turnos por fases, como en el mapeo.
- Derrota por comida. Sin victoria todavía.

**Decisiones técnicas a tomar en esta fase:**

- Motor. Recomendación: **Godot 4** con GDScript. Razones: gratis, buen soporte para cuadrículas 2D y juegos por turnos, exporta a PC y web sin esfuerzo, y la comunidad en español es grande. Alternativa válida: un prototipo en web pura (HTML y JavaScript) si se prefiere iterar aún más rápido y sin instalar nada.
- Representación del laberinto: una matriz de celdas con estado. El cambio del laberinto es una función pura que recibe la matriz y el número de ciclo y devuelve la matriz nueva. Esto es clave para la fase 2: si el cambio es una función pura, se pueden componer reglas.
- Guardado: ninguno todavía.

**Entregables:**

- Build jugable.
- Registro de 10 partidas propias con duración y causa de derrota.

**Puerta de decisión:** ¿Jugarías 20 minutos seguidos sin obligación? Si la respuesta honesta es no, el problema está en el bucle y ningún sistema encima lo va a arreglar.

---

## Fase 2: El laberinto se aprende

**Objetivo:** convertir el cambio del laberinto en un misterio con solución.

**Qué se agrega:**

- Generador de patrones: cada partida elige entre 3 y 5 reglas de una biblioteca de 10 a 12 reglas simples.
- Sala de mapas: pantalla donde el jugador ve el mapa dibujado por sus corredores (solo lo que vieron) y gasta conocimiento para "confirmar" una hipótesis sobre una regla.
- Historial de ciclos: el jugador puede ver cómo estaba el mapa en ciclos anteriores. Sin esto, deducir es imposible.
- Marcas de generaciones anteriores: dan una regla parcial.
- Victoria: llegar a la salida.

**Riesgo principal:** que las reglas sean demasiado difíciles de deducir o demasiado obvias. Se mitiga con la biblioteca de reglas ordenada por dificultad y con pruebas con jugadores nuevos.

**Entregables:**

- Biblioteca de reglas documentada, cada una con un ejemplo visual.
- Pruebas con al menos 3 personas que no conocen el juego.

**Puerta de decisión:** ¿Un jugador nuevo descubre al menos una regla por su cuenta en la primera partida? Si no, las reglas son ilegibles y hay que simplificarlas.

---

## Fase 3: Cada persona cuenta

**Objetivo:** que perder un corredor tenga peso.

**Qué se agrega:**

- Corredores con nombre, dos líneas de historia y tres atributos.
- Estados: sano, herido, perdido, muerto. Enfermería.
- Vínculos entre habitantes: una lista simple de "quién le importa a quién".
- Facciones con el indicador de balance y 4 a 6 eventos de umbral.
- Sala de mapas amplía: mejorar corredores con conocimiento.

**Entregables:**

- Generador de corredores con al menos 30 nombres e historias.
- Tabla de eventos de facciones con sus efectos.

**Puerta de decisión:** ¿En las pruebas, la gente evita mandar a un corredor específico por quién es? Si todos los corredores se tratan igual, la identidad no está funcionando.

---

## Fase 4: El laberinto responde

**Objetivo:** que el laberinto se sienta como un antagonista con comportamiento.

**Qué se agrega:**

- Tres reacciones del laberinto (las de la tabla del mapeo), cada una como una regla más del patrón.
- Indicadores sutiles de que el laberinto reaccionó: sonido, cambio de color en las celdas afectadas.
- El ciclo N deja de ser fijo y depende del estado de la ciudad.

**Puerta de decisión:** ¿Los jugadores describen al laberinto con verbos ("me cerró el paso", "se enojó")? Si lo describen como "cambió aleatoriamente", la reacción no se está comunicando.

---

## Fase 5: Corte vertical

**Objetivo:** una partida completa, de inicio a fin, que se pueda mostrar.

**Qué se agrega:**

- Arte provisional coherente (tiles simples, una paleta, una tipografía).
- Interfaz de usuario completa para las cinco fases del turno.
- Tutorial integrado en los primeros 5 turnos.
- Guardado y carga.
- Balance de una partida de 2 a 4 horas.
- Los dos finales: con patrón completo y sin él.

**Entregables:**

- Build compartible.
- Página de itch.io con descripción y capturas.
- Pruebas con al menos 10 personas.

**Puerta de decisión:** ¿Alguien que no eres tú termina una partida y quiere empezar otra? Esta es la única métrica que importa en esta fase.

---

## Fase 6: Producción

Solo se planifica en detalle cuando la fase 5 pasa su puerta. A grandes rasgos:

- Arte y sonido finales.
- Más reglas de patrón y más eventos de facciones.
- Modos: partida corta, partida larga, laberinto diario con semilla fija.
- Localización (empezar en español e inglés).
- Publicación en Steam o itch.io.

---

## Orden de construcción dentro de cada fase

Para no perderse, cada fase se construye en este orden:

1. **Datos primero.** Definir las estructuras (celda, corredor, recurso) antes de cualquier pantalla.
2. **Lógica pura.** Funciones que reciben estado y devuelven estado nuevo. Sin interfaz. Se prueban con tests automáticos.
3. **Interfaz mínima.** Lo justo para jugar. Texto y rectángulos.
4. **Pruebas con personas.** Antes de pulir nada.
5. **Pulido.** Solo lo que las pruebas señalaron.

## Riesgos y cómo se vigilan

| Riesgo | Señal de alerta | Respuesta |
|---|---|---|
| Alcance se infla | La lista de "qué se agrega" de una fase crece durante la fase | Congelar la lista al inicio de cada fase. Lo nuevo va a una lista de "después". |
| Dos juegos pegados | En pruebas, la gente ignora la ciudad o ignora el laberinto | Revisar las cuatro dependencias obligatorias del mapeo. Una está rota. |
| Reglas ilegibles | Nadie deduce nada en la fase 2 | Reducir el patrón a 2 reglas y agregar el historial de ciclos con más detalle. |
| Pérdida de motivación | Más de dos semanas sin build nueva | Bajar el alcance de la fase actual hasta que salga una build esta semana. |

## Próximos tres pasos concretos

1. Hacer el prototipo de papel esta semana con la cuadrícula de 9x9 y una regla de cambio.
2. Decidir el motor (Godot 4 recomendado) y crear el proyecto vacío con la matriz de celdas y la función de cambio.
3. Escribir la biblioteca inicial de 10 reglas de patrón, cada una en una línea, ordenadas de fácil a difícil.
