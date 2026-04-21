extends Area2D
class_name Player1
var velocity = Vector2.ZERO
var currentState
var nextState
var boxArgs = [false, 0, 0, 0, 0]
var boxSize = Vector2.ZERO
@export var forwardSpeed: int
@export var isPlayer1: bool
@export var otherPlayer: Area2D
var playerString
var pathString
var hitbox
var dealingHitstun
var dealingBlockstun
var dealingPushback
var hp = 100
var dealingDamage
var isGrabbing = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	currentState = idle.new()
	hitbox = get_node("hitbox/box")
	hitbox.set_disabled(true)
	if isPlayer1: 
		playerString = "P1"
		pathString = "Player1"
		$Player1Sprite.play("idle")
	else: 
		playerString = "P2"
		pathString = "Player2"
		$Player1Sprite.set_flip_h(true)
		$Player1Sprite.play("idle")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	velocity = currentState.activeVector(forwardSpeed)
	nextState = currentState.activeState(playerString)
	boxArgs = currentState.activeBox()
	if nextState:
		currentState.exit()
		currentState = nextState
		currentState.enter(isPlayer1)
		if currentState.animation:
			$Player1Sprite.play(currentState.animation)
	elif currentState.isBlockingOrHit():
		if currentState.count < 2:
			$Player1Sprite.play(currentState.animation)
	elif currentState.justHitGrab():
		$Player1Sprite.play("grabSuccess")
			
	position += velocity
	if isPlayer1: position = position.clamp(Vector2.ZERO, otherPlayer.position + Vector2(-100, 0))
	else: position = position.clamp(otherPlayer.position + Vector2(100, 0), Vector2(1080, 720))
	if boxArgs[0]:
		hitbox.set_disabled(false)
		boxSize = Vector2(boxArgs[1], boxArgs[2])
		hitbox.shape.set_size(boxSize)
		if isPlayer1:
			boxSize = Vector2(boxArgs[3] + 39 + boxArgs[1] * 0.5, boxArgs[4])
		else:
			boxSize = Vector2(boxArgs[3] - 53 - boxArgs[1] * 0.5, boxArgs[4])
		hitbox.set_position(boxSize)
		dealingHitstun = (boxArgs[5])
		dealingBlockstun = boxArgs[6]
		dealingPushback = boxArgs[7]
		dealingDamage = boxArgs[8]
		isGrabbing = boxArgs[9]
		
	else: hitbox.set_disabled(true)
	$Player1Box.scale = currentState.expandBox()
	
func disable() -> void:
	currentState = disabled.new()
	
class State:
	func enter(isPlayer1) -> void:
		pass
	func exit() -> State:
		return null
	func activeState(playerString) -> State:
		return null
	func activeVector(speed: int) -> Vector2:
		return Vector2.ZERO
	func activeBox() -> Array:
		return [false, 0, 0, 0, 0]
	func isBlockingOrHit() -> bool:
		return false
	func justHitGrab() -> bool:
		return false
	func expandBox() -> Vector2:
		return Vector2(1, 1)

class disabled extends State:
	var animation = "idle"

class idle extends State:
	var animation = "idle"
	func activeState(playerString) -> State:
		if playerString == "P1": 
			if Input.is_action_pressed("P1Right") && Input.is_action_pressed("P1Heavy"):
				return grabbing.new()
		else:
			if Input.is_action_pressed("P2Left") && Input.is_action_pressed("P2Heavy"):
				return grabbing.new()
		if Input.is_action_just_pressed(playerString + "Right"): 
			return movingRight.new()
		if Input.is_action_just_pressed(playerString + "Left"): 
			return movingLeft.new()
		if Input.is_action_just_pressed(playerString + "Light"): 
			return standingLight.new()
		if Input.is_action_just_pressed(playerString + "Medium"): 
			return standingMedium.new()
		if Input.is_action_just_pressed(playerString + "Heavy"): 
			return standingHeavy.new()
		return null

class movingRight extends State:
	var animation
	
	func enter(isPlayer1):
		if isPlayer1:
			animation = "walking"
		else: animation = "walkingReverse"
	func activeState(playerString) -> State:
		if playerString == "P1": 
			if Input.is_action_pressed("P1Right") && Input.is_action_pressed("P1Heavy"):
				return grabbing.new()
		else:
			if Input.is_action_pressed("P2Left") && Input.is_action_pressed("P2Heavy"):
				return grabbing.new()
		if Input.is_action_just_pressed(playerString + "Left"): 
			return movingLeft.new()
		if Input.is_action_just_pressed(playerString + "Light"): 
			return standingLight.new()
		if Input.is_action_just_pressed(playerString + "Medium"): 
			return standingMedium.new()
		if Input.is_action_just_pressed(playerString + "Heavy"): 
			return standingHeavy.new()
		if Input.is_action_pressed(playerString + "Right"): return null
		else: return idle.new()
	func activeVector(speed: int) -> Vector2: 
		return Vector2(speed, 0)

class movingLeft extends State:
	var animation 

	func enter(isPlayer1):
		if isPlayer1:
			animation = "walking"
		else: animation = "walkingReverse"
	
	func activeState(playerString) -> State:
		if playerString == "P1": 
			if Input.is_action_pressed("P1Right") && Input.is_action_pressed("P1Heavy"):
				return grabbing.new()
		else:
			if Input.is_action_pressed("P2Left") && Input.is_action_pressed("P2Heavy"):
				return grabbing.new()
		if Input.is_action_just_pressed(playerString + "Right"): 
			return movingRight.new()
		if Input.is_action_just_pressed(playerString + "Light"): 
			return standingLight.new()
		if Input.is_action_just_pressed(playerString + "Medium"): 
			return standingMedium.new()
		if Input.is_action_just_pressed(playerString + "Heavy"): 
			return standingHeavy.new()
		if Input.is_action_pressed(playerString + "Left"): return null
		else: return idle.new()
	func activeVector(speed: int) -> Vector2: 
		return Vector2(-speed, 0)
		
class grabbing extends State:
	var animation = "grabAttempt"
	var startUp = 4
	var active = 2
	var recovery = 20
	var hitboxXSize = 50
	var hitboxYSize = 200 
	var hitboxXoffset = 0
	var hitboxYoffset = -22
	var hitStun = 20
	var blockStun = 0
	var pushback = 5
	var damage = 20
	var hitGrab: bool = false
	var length = startUp + active + recovery
	static var subState
	static var count = 0
	
	func justHitGrab() -> bool:
		var toReturn = hitGrab
		hitGrab = false
		return toReturn 
		
	func enter(isPlayer1) -> void:
		subState = 0
		count = 0
	func activeState(playerString) -> State:
		count += 1
		if count < length: return null
		else:
			if Input.is_action_pressed(playerString + "Right"): 
				return movingRight.new()
			if Input.is_action_pressed(playerString + "Left"): 
				return movingLeft.new()
			if Input.is_action_pressed(playerString + "Light"): 
				return standingLight.new()
			if Input.is_action_pressed(playerString + "Medium"): 
				return standingMedium.new()
			if Input.is_action_pressed(playerString + "Heavy"): 
				return standingHeavy.new()
			else: return idle.new()
	func activeBox() -> Array:
		if count > startUp && count < startUp + active + 1:
			return [true, hitboxXSize, hitboxYSize, hitboxXoffset, hitboxYoffset, hitStun, blockStun, pushback, damage, true]
		else: return [false, 0, 0, 0, 0]
		
class standingLight extends State:
	var animation = "light"
	var startUp = 4
	var active = 2
	var recovery = 4
	var hitboxXSize = 80
	var hitboxYSize = 80 
	var hitboxXoffset = 0
	var hitboxYoffset = -22
	var hitStun = 13
	var blockStun = 7
	var pushback = 2
	var damage = 10
	var length = startUp + active + recovery
	static var subState
	static var count = 0
	func enter(isPlayer1) -> void:
		subState = 0
		count = 0
	func activeState(playerString) -> State:
		count += 1
		if count < length: return null
		else:
			if Input.is_action_pressed(playerString + "Right"): 
				return movingRight.new()
			if Input.is_action_pressed(playerString + "Left"): 
				return movingLeft.new()
			if Input.is_action_pressed(playerString + "Light"): 
				return standingLight.new()
			if Input.is_action_pressed(playerString + "Medium"): 
				return standingMedium.new()
			if Input.is_action_pressed(playerString + "Heavy"): 
				return standingHeavy.new()
			else: return idle.new()
	func activeBox() -> Array:
		if count > startUp && count < startUp + active + 1:
			return [true, hitboxXSize, hitboxYSize, hitboxXoffset, hitboxYoffset, hitStun, blockStun, pushback, damage, false]
		else: return [false, 0, 0, 0, 0]

class standingMedium extends State: 
	var animation = "medium"
	var startUp = 7
	var active = 3
	var recovery = 15
	var hitboxXSize = 150
	var hitboxYSize = 60 
	var hitboxXoffset = 0
	var hitboxYoffset = -22
	var hitStun = 20
	var blockStun = 15
	var pushback = 2
	var damage = 20
	var length = startUp + active + recovery
	static var subState
	static var count = 0
	func enter(isPlayer1) -> void:
		subState = 0
		count = 0
	func activeState(playerString) -> State:
		count += 1
		if count < length: return null
		else:
			if Input.is_action_pressed(playerString + "Right"): 
				return movingRight.new()
			if Input.is_action_pressed(playerString + "Left"): 
				return movingLeft.new()
			if Input.is_action_pressed(playerString + "Light"): 
				return standingLight.new()
			if Input.is_action_pressed(playerString + "Medium"): 
				return standingMedium.new()
			if Input.is_action_pressed(playerString + "Heavy"): 
				return standingHeavy.new()
			else: return idle.new()
	func activeBox() -> Array:
		if count > startUp && count < startUp + active + 1:
			return [true, hitboxXSize, hitboxYSize, hitboxXoffset, hitboxYoffset, hitStun, blockStun, pushback, damage, false]
		else: return [false, 0, 0, 0, 0]
	func expandBox() -> Vector2:
		if count > startUp + active:
			return Vector2(3, 1)
		else: return Vector2(1, 1)
		

class standingHeavy extends State: 
	var animation = "heavy"
	var startUp = 10
	var active = 5
	var recovery = 20
	var hitboxXSize = 80
	var hitboxYSize = 100 
	var hitboxXoffset = 0
	var hitboxYoffset = 0
	var hitStun = 25
	var blockStun = 15
	var pushback = 2
	var damage = 30
	var length = startUp + active + recovery
	static var subState
	static var count = 0
	func enter(isPlayer1) -> void:
		subState = 0
		count = 0
	func activeState(playerString) -> State:
		count += 1
		if count < 3:
			if (playerString == "P1" && Input.is_action_pressed("P1Right")) || (playerString == "P2" && Input.is_action_pressed("P2Left")):
				return grabbing.new()
		if count < length: return null
		else:
			if Input.is_action_pressed(playerString + "Right"): 
				return movingRight.new()
			if Input.is_action_pressed(playerString + "Left"): 
				return movingLeft.new()
			if Input.is_action_pressed(playerString + "Light"): 
				return standingLight.new()
			if Input.is_action_pressed(playerString + "Medium"): 
				return standingMedium.new()
			if Input.is_action_pressed(playerString + "Heavy"): 
				return standingHeavy.new()
			else: return idle.new()
	func activeBox() -> Array:
		if count > startUp && count < startUp + active + 1:
			return [true, hitboxXSize, hitboxYSize, hitboxXoffset, hitboxYoffset, hitStun, blockStun, pushback, damage, false]
		else: return [false, 0, 0, 0, 0]
#class blocking extends State: 

class hit extends State:
	var animation = "hit"
	static var count = 0
	var pushback
	var stunDuration
	
	func isBlockingOrHit() -> bool:
		return true
	
	func enter(isPlayer1) -> void:
		count = 0
	
	func setVars(stun, push) -> void:
		stunDuration = stun
		if !stunDuration: stunDuration = 0
		pushback = push
		if !pushback: pushback = 0
	
	func activeState(playerString) -> State:
		count +=1
		if count < stunDuration: return null
		return idle.new()
	func activeVector(speed) -> Vector2:
		return Vector2(pushback, 0)

class blocking extends State:
	var animation = "blocking"
	static var count = 0
	var pushback
	var stunDuration
	
	func isBlockingOrHit() -> bool:
		return true
	
	func enter(isPlayer1) -> void:
		count = 0
	
	func setVars(stun, push) -> void:
		stunDuration = stun
		if !stunDuration: stunDuration = 0
		pushback = push
		if !pushback: pushback = 0
	
	func activeState(playerString) -> State:
		count +=1
		if count < stunDuration: return null
		return idle.new()
	func activeVector(speed) -> Vector2:
		return Vector2(pushback, 0)

func _on_area_entered(area: Area2D) -> void:
	if otherPlayer.isGrabbing:
		currentState = hit.new()
		otherPlayer.currentState.hitGrab = true
		hp -= otherPlayer.dealingDamage
		if isPlayer1: currentState.setVars(otherPlayer.dealingHitstun, -otherPlayer.dealingPushback)
		else: currentState.setVars(otherPlayer.dealingHitstun, otherPlayer.dealingPushback)
		currentState.enter(true)
	else:
		if isPlayer1 && Input.is_action_pressed("P1Left"):
			currentState = blocking.new()
			currentState.setVars(otherPlayer.dealingBlockstun, -otherPlayer.dealingPushback)
			currentState.enter(true)
		elif !isPlayer1 && Input.is_action_pressed("P2Right"):
			currentState = blocking.new()
			currentState.setVars(otherPlayer.dealingBlockstun, otherPlayer.dealingPushback)
			currentState.enter(true)
		else:
			currentState = hit.new()
			hp -= otherPlayer.dealingDamage
			if isPlayer1: currentState.setVars(otherPlayer.dealingHitstun, -otherPlayer.dealingPushback)
			else: currentState.setVars(otherPlayer.dealingHitstun, otherPlayer.dealingPushback)
			currentState.enter(true)
