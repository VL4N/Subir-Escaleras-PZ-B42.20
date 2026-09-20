# Mapeo del juego: estrategia en un laberinto con una ciudad adentro

> Nombre provisional: **El Claro** (la ciudad) y **El Muro** (el laberinto).
> Documento vivo. Todo lo que está aquí es una hipótesis hasta que el prototipo la confirme.

## 1. Concepto en una frase

Administras una pequeña ciudad encerrada en el centro de un laberinto que cambia solo.
Envías corredores a explorar, aprendes el patrón del laberinto y decides cuándo arriesgarlo todo para salir.

## 2. Pilares de diseño

Estos cuatro pilares son el filtro para cualquier idea nueva. Si una mecánica no sirve a alguno, no entra.

| Pilar | Qué significa | Qué NO es |
|---|---|---|
| **El laberinto se aprende** | Los cambios de paredes siguen reglas que el jugador puede descubrir. Ganar es entender. | Un mapa aleatorio que se reinicia sin sentido. |
| **Cada persona cuenta** | Pocos corredores, con nombre y habilidades. Perder uno duele en la ciudad y en el mapa. | Unidades desechables producidas en masa. |
| **Adentro y afuera se afectan** | Lo que construyes cambia el laberinto y lo que exploras cambia la ciudad. | Dos juegos pegados con una pantalla de carga entre medio. |
| **La presión viene del reloj, no del enemigo** | Las paredes se mueven cada N turnos. La tensión es tomar decisiones a tiempo. | Oleadas de enemigos como única fuente de dificultad. |

## 3. Identidad propia (distancia de Maze Runner)

Tomamos de la referencia solo la mecánica: laberinto que cambia y una comunidad encerrada.
Nos alejamos de la estética y la historia:

- No hay virus, organización secreta ni adolescentes elegidos.
- El laberinto no es una prueba de nadie. Es un sistema con reglas propias, casi un organismo.
- La ciudad tiene historia acumulada: generaciones que ya intentaron salir y dejaron mapas incompletos.
- Tono: misterio y gestión, no acción. Referencias más cercanas: *Frostpunk* (decisiones morales bajo presión), *Into the Breach* (información completa y decisiones limpias), *Return of the Obra Dinn* (deducción).

## 4. Las dos capas

### 4.1 El Claro (la ciudad)

Zona segura en el centro del laberinto. Aquí el jugador construye y administra.

**Recursos iniciales (solo tres):**

| Recurso | De dónde sale | Para qué sirve |
|---|---|---|
| Comida | Huertos en la ciudad, hallazgos en el laberinto | Mantener vivos a los habitantes. Raciones para expediciones. |
| Materiales | Solo del laberinto (escombros, restos de otras ciudades) | Construir edificios. Es el recurso que obliga a salir. |
| Conocimiento | Solo de expediciones que vuelven | Desbloquear deducciones sobre el patrón. Mejorar corredores. |

**Edificios base (primera versión):**

- Huerto: produce comida por turno.
- Taller: convierte materiales en equipo para corredores.
- Sala de mapas: donde se dibuja el mapa y se desbloquean deducciones con conocimiento.
- Enfermería: recupera corredores heridos en menos turnos.
- Muralla interior: reduce la pérdida cuando el laberinto "empuja" contra la ciudad.

### 4.2 El Muro (el laberinto)

Una cuadrícula alrededor de la ciudad. Cada celda es pasillo, pared o punto de interés.

**Reglas del cambio (el corazón del juego):**

- El laberinto cambia cada N turnos (el "ciclo"). N empieza en 5 y puede variar según el estado de la ciudad.
- Los cambios NO son aleatorios. Cada partida genera un **patrón oculto** compuesto de 3 a 5 reglas simples, por ejemplo:
  - "Las paredes del sector norte rotan en sentido horario cada ciclo."
  - "Un pasillo que fue recorrido dos veces se cierra al ciclo siguiente."
  - "Cada tercer ciclo se abre una ruta radial nueva."
- El jugador descubre esas reglas observando y gastando conocimiento en la sala de mapas.
- Al descubrir todas las reglas, la salida se vuelve alcanzable por deducción, no por suerte.

**Puntos de interés:**

- Escombros: materiales.
- Ciudades muertas: materiales, conocimiento, pistas del patrón, y a veces un corredor perdido de otra generación.
- Marcas: señales dejadas por generaciones anteriores. Dan una regla parcial del patrón.
- Grietas: zonas donde el laberinto cambia más seguido. Peligrosas pero con más recompensa.

### 4.3 Los corredores

El puente entre las dos capas. Son escasos: la ciudad empieza con 3 y nunca tiene más de 6 o 7.

Cada corredor tiene:

- Nombre e historia corta (dos líneas).
- Tres atributos: velocidad (celdas por turno), carga (recursos que trae) y ojo (probabilidad de detectar pistas).
- Estado: sano, herido, perdido, muerto.
- Vínculos con otros habitantes. Si un corredor muere, sus vínculos afectan la moral y las facciones.

Una expedición se planifica turno a turno: eliges la ruta con la información que tienes y el corredor la ejecuta. Si el laberinto cambia mientras está afuera, la ruta de vuelta puede no existir. Ahí está la decisión central: **¿lo mando ahora o espero al próximo ciclo?**

### 4.4 Las facciones

Dos corrientes dentro de la ciudad, sin enemigos externos:

- **Los que quieren salir.** Presionan por más expediciones y menos gasto en edificios. Si los ignoras, se van solos y pierdes corredores.
- **Los que quieren quedarse.** Presionan por murallas y huertos. Si los ignoras, sabotean expediciones o esconden recursos.

Se representan con un solo indicador de balance (de -10 a +10). Cada decisión mueve la aguja. No es un sistema de diplomacia completo: es un termómetro que genera dilemas.

### 4.5 El laberinto responde

El laberinto reacciona al comportamiento del jugador. Esto lo convierte en antagonista:

| Si el jugador... | El laberinto... |
|---|---|
| Construye mucho sin explorar | Cierra pasillos cercanos a la ciudad. El ciclo se acorta. |
| Explora mucho y abre rutas | Abre rutas radiales nuevas pero aparecen más grietas. |
| Deja muchos corredores afuera durante un cambio | Los pasillos donde estaban se vuelven "marcados" y cambian más seguido. |

Esta reacción también sigue reglas fijas y forma parte del patrón que se puede aprender.

## 5. Mapa de dependencias entre sistemas

Este es el mapa que evita que el juego sea "dos juegos pegados". Cada flecha es una dependencia que debe existir en el código y en el diseño.

```
                 ┌──────────────────────┐
                 │  PATRÓN DEL LABERINTO │  ← reglas ocultas generadas por partida
                 └──────────┬───────────┘
                            │ define cómo cambia
                            ▼
┌────────────┐     ┌──────────────────┐     ┌───────────────┐
│  CIUDAD    │────►│    LABERINTO     │◄────│  CORREDORES   │
│ (El Claro) │     │    (El Muro)     │     │               │
└─────┬──────┘     └────────┬─────────┘     └───────┬───────┘
      │                     │                       │
      │ construir           │ reacciona             │ traen
      │ cambia el ciclo     │ al comportamiento     │ materiales
      │                     │                       │ y conocimiento
      │                     ▼                       │
      │            ┌─────────────────┐              │
      └───────────►│  SALA DE MAPAS  │◄─────────────┘
                   │ (deducción)     │
                   └────────┬────────┘
                            │ desbloquea reglas
                            ▼
                   ┌─────────────────┐
                   │    FACCIONES    │  ← reaccionan a cada decisión
                   └─────────────────┘
```

Dependencias obligatorias:

1. **Materiales solo vienen del laberinto.** Sin esto, la ciudad se vuelve autosuficiente y el jugador deja de salir.
2. **Conocimiento solo viene de corredores que vuelven.** Sin esto, la deducción se vuelve un menú de compra.
3. **El ciclo del laberinto depende del estado de la ciudad.** Sin esto, el laberinto es un fondo decorativo.
4. **Las facciones reaccionan a expediciones y construcciones.** Sin esto, no hay dilema interno.

## 6. Bucle de juego (un turno)

1. **Fase de ciudad.** Recolectas producción, asignas habitantes a edificios, construyes con materiales.
2. **Fase de mapa.** Revisas el mapa dibujado, gastas conocimiento en deducciones, planificas rutas.
3. **Fase de expedición.** Cada corredor afuera avanza según su velocidad y la ruta trazada. Resuelves hallazgos.
4. **Fase de ciclo.** Si el contador llega a N, el laberinto cambia según el patrón. Los corredores afuera quedan donde estaban, con el mapa nuevo.
5. **Fase de facciones.** El balance se ajusta según lo que hiciste. Si cruza un umbral, ocurre un evento.

Un turno debería durar entre 1 y 3 minutos de decisiones reales. Una partida completa, entre 2 y 4 horas.

## 7. Condiciones de fin

- **Victoria:** un corredor llega a la salida con el patrón completo descubierto. Variante: llega sin el patrón completo, con final más ambiguo.
- **Derrota:** la ciudad se queda sin comida dos ciclos seguidos, o se queda sin corredores, o una facción abandona la ciudad con la mayoría de habitantes.

## 8. Lo que queda explícitamente FUERA de la primera versión

Recortar es la única forma de terminar. Esto no entra hasta que el bucle base sea divertido:

- Combate de cualquier tipo.
- Más de tres recursos.
- Árbol de tecnología.
- Narrativa ramificada con diálogos.
- Multijugador.
- Arte final. Todo el prototipo se hace con cuadrados y texto.
