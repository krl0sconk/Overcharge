class_name BeginFiring
extends PerceptNode

## Gatilla el compromiso a disparar (gateada por IsTargetInRange y
## HasLineToTarget en el árbol). Una vez que enciende "firing", RangedAttack
## -- de prioridad más alta -- toma el control y completa el disparo sin
## volver a pedir rango ni línea: mismo patrón que BeginCharge/ChargeForward
## en el Yunque con "charging".

func tick(agent: PerceptComponent) -> Status:
	agent.blackboard["firing"] = true
	if agent.laser != null:
		agent.laser.begin_telegraph()
	return Status.SUCCESS
