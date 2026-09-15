# AGENTS.md

Instrucciones para asistentes de IA que trabajen en este repositorio.

---

## Qué es Overcharge

Dungeon crawler cooperativo top-down 3D para dos jugadores, hecho en **Godot 4 (GDScript)**.
Proyecto académico de Estructura de Datos II, Universidad del Norte. Equipo de cuatro personas.

Dos robots, Ni-TZSch y Pl4-to, descienden por una red social que se volvió física. El screentime
es el puntaje. Los jefes no se matan: se les rompe la máscara.

**Regla narrativa:** el tema del juego (uso saludable de redes sociales) nunca se enuncia con
texto explícito. Se comunica solo por mecánica. No agregues diálogos, tutoriales ni mensajes
que expliquen el tema.

### Lo que se evalúa académicamente

El proyecto se califica por el uso de **árboles y grafos**. Esto condiciona decisiones técnicas:

- **Behavior trees** para toda la IA de enemigos. Se implementan **a mano**.
  No uses LimboAI, Beehave ni ningún plugin de behavior trees: resolvería justo lo que se evalúa.
- **Grafos** en tres usos: mapa del mundo, generación procedural de niveles (grafo → validación
  con BFS → instanciación) y pathfinding A*.
- **A\* propio o `AStarGrid2D`**, nunca `NavigationAgent2D`: es una caja negra y no se puede
  sustentar qué estructura tiene adentro.

---

## Estructura de carpetas

Organizada **por tipo de archivo primero, por categoría después**. Los jugadores y enemigos
van dentro de `entities/` porque heredan de `Entidad`.

```
res://
  assets/                  arte y audio (fuente)
    entities/players/
    entities/enemies/
    maps/
    ui/
    audio/
    fonts/

  scenes/                  archivos .tscn
    entities/players/      nitzsch.tscn, plato.tscn
    entities/enemies/      spam.tscn, centinela.tscn, ...
    maps/rooms/            salas prefabricadas
    ui/                    HUD, menús, pantalla de ayuda

  scripts/                 archivos .gd
    entities/              entidad.gd (clase base)
    entities/players/      nitzsch.gd, plato.gd
    entities/enemies/      spam.gd, centinela.gd, ...
    components/            HealthComponent.gd, MovementComponent.gd, ...
    abilities/             DashAbility.gd, ComboAbility.gd, ...
    ai/components/         todo el árbol de IA en una sola carpeta: clases base
                           (PerceptNode, PerceptComponent), composites y condiciones
                           (Selector, Sequence, PerceptCondition, PerceptDecorator)
                           y hojas de acción (AcquireTarget, MoveToTarget,
                           MeleeAttack, ...)
    maps/                  generador de grafo, validación BFS, pathfinding
    ui/
    autoload/              event_bus.gd

  resources/               archivos .tres (datos, no código ni escena)
    stats/                 spam_stats.tres, nitzsch_stats.tres, ...
    abilities/             nitzsch_dash.tres, plato_bounce.tres, ...
    ai/trees/              árboles armados por enemigo: centinela.tres, spam.tres,
                           virus.tres, yunque.tres

  addons/                  plugins de editor; no se empaquetan con el juego
    percept_editor/        panel visual propio del equipo para armar y depurar
                           los árboles de ai/components como .tres (ver nota abajo)
```

`percept_editor` es una herramienta de editor hecha por el equipo, no un plugin de
terceros: arma visualmente los mismos nodos de `ai/components` y los guarda como
`.tres`. No reemplaza la lógica del árbol ni el motor de behavior trees, así que no
contradice la regla de no usar LimboAI/Beehave. El juego no depende de `addons/`
en runtime.

Un elemento del juego se reparte entre carpetas: el script en `scripts/`, la escena en
`scenes/`, el arte en `assets/`, los datos en `resources/`. **Usá siempre el mismo nombre base
en las cuatro** (`centinela.gd`, `centinela.tscn`, `centinela_stats.tres`) para poder encontrarlo.

Al crear un script desde el editor de Godot, la ruta por defecto es la de la escena.
Hay que redirigirla a `scripts/` manualmente.

---

## Arquitectura: componentes

Todo se construye con **componentes**: nodos hijos que resuelven una sola responsabilidad y se
montan en cualquier entidad. Un jugador, un enemigo común y un jefe son la misma cosa con
distintos componentes encima.

### Reglas no negociables

1. **Los componentes se montan como nodos hijos en la escena**, arrastrados en el editor.
   No los crees por código.

2. **El dueño se inyecta por `@export`, nunca `get_parent()`.**
   ```gdscript
   @export var owner_body: CharacterBody3D
   ```

3. **Señales locales por defecto; EventBus solo para lo que cruza entidades.**
   Si el que escucha está en la misma escena → señal local del componente.
   Si está en otra rama del árbol → EventBus.

4. **El input vive en un `InputComponent`** que traduce input a intenciones
   (`move_dir`, `wants_attack`, `wants_dash`). Ninguna entidad lee `Input` directamente.
   Esto permite reemplazarlo por input de red en la entrega final sin reescribir nada.

5. **Las habilidades son `Resource`, no código dentro del personaje.**
   El `AbilityComponent` es un slot genérico que ejecuta el Resource asignado.
   Ni-TZSch y Pl4-to son la misma escena base con distintos Resources cargados.

6. **Los stats son datos (`.tres`), no valores en código.**
   Todos los `StatsResource` llevan `resource_local_to_scene = true`.
   Sin eso, los Resources se comparten entre instancias y todos los enemigos mueren juntos.

7. **`Entidad` es una clase base delgada.** Solo cablea componentes y expone acceso a ellos.
   Cero comportamiento propio.
   **Si un método de `Entidad` estaría vacío en alguna entidad, no va en `Entidad`.**
   El Centinela no se mueve, El Ancla no ataca, El Bucle no hace ninguna de las dos.

### Componentes existentes

| Componente | Responsabilidad |
| --- | --- |
| `HealthComponent` | Vida, recibir daño, morir. Señales `damaged`, `died`. |
| `HurtboxComponent` | Área que recibe golpes y delega al HealthComponent. |
| `HitboxComponent` | Área que inflige daño. Lleva daño, knockback y origen. |
| `MovementComponent` | Velocidad, aceleración, fricción, dirección. |
| `InputComponent` | Traduce input a intenciones. |
| `AbilityComponent` | Ejecuta una habilidad y maneja su cooldown. |
| `HitFeedbackComponent` | Flash, pausa de impacto, sacudida de cámara. |
| `PerceptComponent` | Monta y tickea un árbol de `ai/components` (.tres). Solo enemigos. |
| `EnemyDeathComponent` | Despawnea al enemigo al morir. El jugador no despawnea, revive. |
| `LaserSightComponent` | Mira láser de apuntado, sincronizada con la dirección lógica del `PerceptComponent`. |
| `ChargeAnticipationComponent` | Puesta en escena visual del embiste (telegraph/carga/stun), lee el blackboard del `PerceptComponent`. |
| `CorruptionBlotComponent` | Mancha de corrupción: daño periódico y autodestrucción por tiempo de vida. |
| `CorruptionTrailComponent` | Suelta manchas de corrupción según la distancia recorrida. |
| `SlimeHopComponent` | Anima salto y aplastado (squash & stretch) para enemigos sin animación de caminata propia. |

---

## Capas de colisión

Ya están nombradas en `project.godot`. No las cambies sin avisar al equipo.

| # | Capa |
| --- | --- |
| 1 | Entorno |
| 2 | Cuerpo jugador |
| 3 | Cuerpo enemigo |
| 4 | Hurtbox jugador |
| 5 | Hurtbox enemigo |
| 6 | Hitbox jugador |
| 7 | Hitbox enemigo |
| 8 | Interactuables |

**Máscaras:** cuerpo jugador → 1, 3 · cuerpo enemigo → 1, 2, 3 · hitbox jugador → solo 5 ·
hitbox enemigo → solo 4 · interactuables → 2.

La hurtbox va separada del cuerpo a propósito: el dash la desactiva para las invencibilidades
sin tocar la física, y El Yunque tiene hurtbox trasera y ninguna frontal.

---

## Convención de nombres

**Idioma:** código, clases, variables y señales en **inglés**. Comentarios, commits y
documentación en **español**. Nunca mezclar idiomas dentro de un identificador.

- Carpetas y archivos que no son código (`.tscn`, `.tres`) en `snake_case`:
  `spam_stats.tres`, `test_room.tscn`.
- Scripts con un `class_name` reutilizable en varias escenas (componentes,
  habilidades, nodos de IA) en `PascalCase`, igual al `class_name`:
  `HealthComponent.gd`, `PerceptNode.gd`, `DashAbility.gd`.
- Scripts atados a un solo elemento del juego, que comparten nombre base con su
  escena/datos (ver "Estructura de carpetas" arriba), y los autoloads, en
  `snake_case` aunque tengan `class_name`: `entidad.gd` (`class_name Entidad`),
  `nitzsch.gd`, `event_bus.gd`.
- Clases en `PascalCase` y **siempre con `class_name`**
- Variables y funciones en `snake_case`; privadas con guion bajo: `_cooldown_timer`
- Constantes en `SCREAMING_SNAKE_CASE`
- `@export` siempre tipado: `@export var speed: float = 5.0`
- Señales **en pasado**: `damaged`, `died`, `ability_used`. Handlers: `_on_health_died`
- Nodos en escena en `PascalCase`, nombrados por lo que **son**: `HealthComponent`, no `Vida`

### Sufijos fijos

| Sufijo | Para qué |
| --- | --- |
| `...Component` | Componentes montables |
| `...Ability` | Habilidades (Resource) |
| `...Stats` | Datos de balance (Resource) |
| `Percept...` | Clases base del árbol de IA: `PerceptNode`, `PerceptComponent`, `PerceptComposite`, `PerceptCondition`, `PerceptDecorator` |

Los nodos concretos del árbol (composites y hojas) no llevan sufijo fijo: se
nombran por lo que hacen y heredan de una de las clases `Percept...` de arriba
(`Selector`, `Sequence`, `AcquireTarget`, `MoveToTarget`, `MeleeAttack`, ...).

---

## Comentarios

**Cortos y concisos. Explican el porqué, no el qué.**

```gdscript
# BIEN: explica una decisión que no se deduce del código
# Se duplica porque los Resources se comparten entre instancias.
stats = stats.duplicate()

# MAL: repite lo que el código ya dice
# Duplica los stats
stats = stats.duplicate()
```

- Usa `##` para documentar clases, señales y métodos públicos (aparece en el editor de Godot).
- Usa `#` para notas internas.
- No comentes código muerto: bórralo, está en git.
- Si un bloque necesita un párrafo de explicación, probablemente había que extraer una función.
- Dependencia de algo que otro integrante todavía no hizo: una línea, `# TODO(Nombre): qué falta`.
  Nunca un bloque describiendo el contrato asumido.

---

## Git

```
main                  siempre compilable, nadie commitea directo
feat/<area>-<cosa>    feat/ia-behavior-tree, feat/gameplay-dash
fix/<cosa>            fix/hurtbox-no-detecta
```

Commits en español, imperativo y cortos: `agrega HealthComponent`, `corrige cooldown del dash`.

El repositorio se evalúa: debe haber commits de los cuatro integrantes repartidos durante todo
el periodo de cada entrega, no un empujón al final.

**Los commits son del equipo, no de la IA.** Un asistente de IA nunca se agrega como
`Co-Authored-By`, ni como coautor de ningún otro modo, ni deja enlaces de sesión u otros
trailers de atribución en el mensaje. Tampoco se agrega como colaborador del repositorio en
GitHub. El commit va firmado únicamente por el integrante que hizo el trabajo.

---

## Al escribir código en este repo

- Respeta la arquitectura de componentes aunque la solución directa parezca más corta.
  Si algo no encaja en un componente, planteálo antes de meterlo en la entidad.
- Respeta la estructura de carpetas: el script va en `scripts/`, la escena en `scenes/`,
  nunca juntos.
- No agregues dependencias ni plugins sin consultarlo. En particular ningún plugin de
  behavior trees o pathfinding.
- No generes código de más: nada de sistemas "por si acaso", abstracciones especulativas
  ni configuración que nadie pidió.
- Si una decisión de diseño no está definida en este archivo, preguntá en vez de asumir.
