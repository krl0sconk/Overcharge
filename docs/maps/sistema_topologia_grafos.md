# Sistema de topología con grafos para la generación de salas

## Objetivo

Crear niveles procedurales para el dungeon crawler mediante grafos. Cada nivel puede tener uno o varios grafos configurables. El grafo define la topología posible y las reglas de generación; la semilla y las estadísticas de los jugadores determinan el resultado concreto de cada intento.

La primera y la última sala permanecen fijas. Las salas intermedias pueden cambiar de orden, posición, tipo, dificultad, enemigos, objetos y ventajas.

## Conceptos principales

### Plantilla de grafo

Una plantilla define las posibilidades de un nivel:

- cantidad mínima y máxima de salas;
- sala inicial y sala final;
- tipos de sala disponibles;
- conexiones permitidas;
- límites de profundidad;
- bifurcaciones y caminos alternativos;
- ponderaciones de dificultad, objetos y ventajas;
- condiciones de generación.

Las plantillas deben ser datos configurables, preferiblemente Resources en `resources/maps/`. La lógica debe permanecer en `scripts/maps/`.

### Grafo generado

Es la instancia concreta creada para un intento. Cada nodo contiene, como mínimo:

- identificador de sala;
- tipo o rol de sala;
- posición;
- conexiones;
- distancia desde el inicio;
- distancia hasta el final;
- dificultad;
- enemigos, objetos y ventajas;
- estado de visitada, completada o bloqueada.

Los roles pueden incluir `start`, `combat`, `reward`, `event`, `elite`, `boss` y `exit`.

### Contexto de generación

El generador recibe:

```text
LevelDefinition
+ GraphDefinition
+ PlayerStats
+ Seed
```

El contexto debe resumir las estadísticas relevantes de los jugadores, por ejemplo:

- cantidad de jugadores;
- vida actual y máxima;
- daño y habilidades disponibles;
- mejoras activas;
- progreso y dificultad actual.

Las estadísticas modifican ponderaciones y condiciones definidas por el nivel. No deben cambiar arbitrariamente la conectividad del grafo.

## Semillas e intentos

Cada entrada nueva a un nivel crea una semilla única. Esa semilla controla toda la aleatoriedad del intento: topología, salas, dificultad, enemigos, objetos y ventajas.

La misma combinación de nivel, semilla y contexto debe producir el mismo resultado. Esto permite reproducir un intento durante debugging y comparar distintos intentos.

Un generador local con semilla debe usarse en lugar de depender de la aleatoriedad global sin control.

### Registro durante la sesión

Al entrar por primera vez a un nivel:

1. Se crea una semilla.
2. Se genera la topología.
3. Se valida mediante BFS.
4. Se analizan las distancias y rutas.
5. Se asignan tipos, dificultad y contenido.
6. Se registra la semilla y el resultado del grafo.
7. Se instancian las salas.

Mientras el juego permanezca abierto, el nivel debe conservar la misma semilla y el mismo grafo generado. Si el jugador vuelve al nivel o se reinicia su escena, el sistema debe consultar primero el registro de sesión y reutilizar el resultado existente.

El registro no debe depender de variables locales de una escena. Debe vivir en un gestor de sesión o autoload, para sobrevivir a los cambios de sala:

```text
SessionRegistry
{
    level_id:
    {
        seed:
        generated_graph:
        current_room_id:
        visited_rooms:
        completed_rooms:
        room_states:
    }
}
```

Este registro es persistencia durante la sesión, no un guardado permanente en disco. Si el juego se cierra, la semilla se pierde salvo que posteriormente se conecte con el sistema de guardado.

## Flujo de generación

```text
Seleccionar nivel
        |
        v
Consultar registro de sesión
        |
        +-- Existe --> reutilizar semilla y grafo
        |
        +-- No existe
                |
                v
        Crear semilla
                |
                v
        Cargar plantilla de grafo
                |
                v
        Leer estadísticas de jugadores
                |
                v
        Crear contexto
                |
                v
        Generar topología
                |
                v
        Validar y analizar con BFS
                |
                v
        Asignar salas y contenido
                |
                v
        Registrar resultado
                |
                v
        Instanciar escenas
```

## Adaptación por estadísticas

Las estadísticas modifican ponderaciones previamente definidas.

### Jugadores con poca vida

- mayor probabilidad de salas de curación;
- menos enemigos o menor presión inicial;
- más objetos defensivos;
- menor probabilidad de salas élite.

### Jugadores con daño elevado

- mayor dificultad de enemigos;
- posibilidad de salas élite;
- mayor probabilidad de caminos de riesgo;
- recompensas más valiosas.

### Jugadores con muchas ventajas

- menos ayudas comunes;
- más bifurcaciones de riesgo;
- enemigos más resistentes;
- posibilidad de recompensas especiales.

Todas las transformaciones deben ser explícitas, medibles y reproducibles con la misma semilla.

## Uso de BFS

BFS se utiliza después de generar la topología y antes de instanciar las salas.

### Validación

Desde la sala inicial debe comprobarse que:

- la sala final sea alcanzable;
- todas las salas sean alcanzables;
- no existan nodos aislados;
- las conexiones sean bidireccionales;
- no haya conexiones duplicadas;
- no haya referencias a nodos inexistentes;
- la cantidad de salas esté dentro del rango permitido.

Un grafo inválido no debe llegar a la instanciación. Si falla la validación, el generador debe regenerar con la misma política o devolver un error reproducible asociado a la semilla.

### Análisis

BFS también calcula:

- distancia desde el inicio;
- distancia hasta el final;
- camino principal;
- bifurcaciones;
- salas opcionales;
- salas críticas;
- profundidad del nivel.

Estos datos orientan la asignación de contenido:

```text
Inicio:
    combate básico y objetos comunes.

Zona intermedia:
    eventos, recompensas y bifurcaciones.

Cerca del final:
    élites, mayor dificultad y recompensas importantes.

Final:
    sala fija del nivel.
```

## Cantidad y variación de salas

Un nivel puede generar aproximadamente cinco salas:

```text
Sala inicial + salas intermedias variables + sala final
```

Las salas intermedias pueden cambiar por efecto de:

- semilla;
- estadísticas de entrada;
- grafo seleccionado;
- ponderaciones;
- condiciones de generación.

Dos intentos con semillas distintas pueden producir diferente orden, posiciones, bifurcaciones, dificultad, enemigos, objetos y ventajas, conservando la primera y la última sala.

## Instanciación de salas

Después de validar el grafo:

1. Asociar cada nodo con una escena de `scenes/maps/rooms/`.
2. Colocar la escena según la posición del nodo.
3. Crear las puertas correspondientes a sus conexiones.
4. Configurar enemigos y objetos.
5. Colocar a los jugadores en el punto de entrada.
6. Registrar el estado de la sala.
7. Mantener ese estado durante el intento.

La sala de prueba existente puede usarse para validar el primer prototipo, pero no debe asumir que todas las salas tendrán la misma configuración.

## Puertas y transición

Cada conexión del grafo debe corresponder a una puerta o salida real. Las salidas sin conexión deben permanecer desactivadas u ocultas.

Al atravesar una puerta:

1. resolver el nodo destino;
2. comprobar que la conexión sea válida;
3. bloquear transiciones duplicadas;
4. cambiar la sala actual;
5. cargar o activar la sala destino;
6. colocar a los jugadores en la entrada opuesta;
7. actualizar el registro de sesión;
8. mover la cámara;
9. devolver el control.

La dirección de la conexión determina la posición de la sala destino, la orientación de la puerta y el punto de entrada.

## Movimiento de cámara

La cámara sigue normalmente al grupo de jugadores. Durante una transición debe:

1. suspender temporalmente el seguimiento normal;
2. desplazarse o reposicionarse hacia la nueva sala;
3. encuadrar a los jugadores;
4. restaurar el seguimiento;
5. habilitar nuevamente el movimiento.

La cámara reacciona a una transición ya resuelta; no decide la navegación ni modifica el grafo.

## Modo debug

El modo debug debe mostrar:

- nodos y conexiones;
- identificador y tipo de cada sala;
- sala inicial, final y actual;
- salas visitadas;
- distancias calculadas por BFS;
- semilla del intento;
- cantidad de nodos y conexiones;
- resultado de validación;
- estadísticas resumidas del contexto.

Debe permitir regenerar usando una semilla manual para reproducir un intento y comparar resultados.

## Testing

### Determinismo

- misma semilla y mismas estadísticas producen el mismo grafo;
- misma semilla y estadísticas distintas producen cambios esperados;
- semillas distintas pueden producir grafos diferentes;
- primera y última sala permanecen constantes.

### Validación

- grafo lineal válido;
- grafo con bifurcaciones válido;
- nodo aislado;
- sala final inaccesible;
- conexión unilateral;
- conexión duplicada;
- referencia inexistente;
- cantidad incorrecta de salas.

### Registro de sesión

- un nivel nuevo recibe una semilla;
- volver al nivel reutiliza la misma semilla;
- reiniciar una escena no crea otra semilla;
- el grafo conserva sus estados;
- las salas visitadas mantienen su estado;
- dos niveles tienen registros independientes.

### Adaptación

- poca vida aumenta las ponderaciones defensivas;
- daño elevado aumenta la dificultad permitida;
- las estadísticas no rompen la conectividad;
- las condiciones son reproducibles con la misma semilla.

### Integración

- cada conexión crea la puerta correcta;
- una puerta lleva al nodo correcto;
- los jugadores aparecen en el punto opuesto;
- las transiciones duplicadas se bloquean;
- la cámara termina enfocando la sala destino;
- el jugador recupera el control al finalizar la transición.

## Orden de implementación

1. Definir Resources y estructuras del grafo.
2. Crear varias plantillas de grafos.
3. Crear el contexto de generación.
4. Implementar generación determinista por semilla.
5. Implementar BFS de validación y análisis.
6. Implementar el registro de sesión.
7. Añadir adaptación mediante estadísticas y ponderaciones.
8. Crear pruebas del sistema abstracto.
9. Crear el modo debug del grafo.
10. Asociar nodos con escenas de salas.
11. Implementar puertas y transiciones.
12. Integrar el movimiento de cámara.
13. Probar recorridos completos del nivel.

## Criterios de aceptación

El sistema estará completo cuando pueda:

1. seleccionar un nivel con un grafo asignado;
2. generar una semilla al entrar por primera vez;
3. crear aproximadamente cinco salas;
4. mantener fijas la primera y la última;
5. variar las salas intermedias según semilla y estadísticas;
6. validar la conectividad mediante BFS;
7. registrar semilla, grafo y estado durante la sesión;
8. reutilizar el mismo resultado al volver al nivel;
9. mostrar el grafo en modo debug;
10. instanciar salas conectadas mediante puertas;
11. realizar transiciones correctas;
12. mover la cámara durante las transiciones;
13. producir resultados reproducibles con la misma semilla.
