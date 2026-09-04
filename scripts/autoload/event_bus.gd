extends Node

## Señales globales del juego.
## Solo va acá lo que cruza entidades. Si emisor y receptor están en la misma
## escena, la señal es local del componente.

## Emitida cuando muere un enemigo. `killer` permite el cooldown cruzado:
## cada AbilityComponent de movimiento se resetea si el killer no es su dueño.
signal enemy_died(killer: Node)

## Emitida cuando no quedan enemigos vivos en la sala actual.
signal room_cleared

## Emitida cuando un jugador recibe daño. La usa el HUD.
signal player_damaged(player: Node, amount: int)
