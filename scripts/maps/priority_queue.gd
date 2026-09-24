class_name PriorityQueue
extends RefCounted

## Binary min-heap simple: no soporta decrease-key, A* la usa empujando
## duplicados y descartando entradas obsoletas contra el set cerrado.

var _heap: Array = []  ## cada elemento: [priority: float, id: int]

func is_empty() -> bool:
	return _heap.is_empty()

func push(id: int, priority: float) -> void:
	_heap.append([priority, id])
	_sift_up(_heap.size() - 1)

func pop_min() -> int:
	var top: int = _heap[0][1]
	var last: Array = _heap.pop_back()
	if not _heap.is_empty():
		_heap[0] = last
		_sift_down(0)
	return top

func _sift_up(index: int) -> void:
	var i: int = index
	while i > 0:
		var parent: int = (i - 1) / 2
		if _heap[parent][0] <= _heap[i][0]:
			break
		_swap(parent, i)
		i = parent

func _sift_down(index: int) -> void:
	var i: int = index
	var size: int = _heap.size()
	while true:
		var left: int = i * 2 + 1
		var right: int = i * 2 + 2
		var smallest: int = i
		if left < size and _heap[left][0] < _heap[smallest][0]:
			smallest = left
		if right < size and _heap[right][0] < _heap[smallest][0]:
			smallest = right
		if smallest == i:
			break
		_swap(i, smallest)
		i = smallest

func _swap(a: int, b: int) -> void:
	var tmp: Array = _heap[a]
	_heap[a] = _heap[b]
	_heap[b] = tmp
