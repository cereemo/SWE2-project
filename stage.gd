extends Node2D

@export var playerScene: PackedScene
@export var secondPlayerScene: PackedScene
var player1Health = 100
var player2Health = 100
var count = 0 
var count2 = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if count == 0:
		$CanvasLayer/Label.set_text("3")
	elif count == 60:
		$CanvasLayer/Label.set_text("2")
	elif count == 120:
		$CanvasLayer/Label.set_text("1")
	elif count == 180:
		$CanvasLayer/Label.set_text("GO!")
	elif count == 210:
		$CanvasLayer/Label.set_text("")
		var player2 = secondPlayerScene.instantiate()
		var player1 = playerScene.instantiate()
		player1.position = Vector2(275, 550)
		player1.otherPlayer = player2
		player2.otherPlayer = player1
		add_child(player1)
		
		player2.name = "Player2"
		player2.isPlayer1 = false
		player2.position = Vector2(815, 550)
		add_child(player2)
	elif count > 210:
		if $Player1.hp <= 0 || $Player2.hp <=0:
			$Player1.disable()
			$Player2.disable()
			if $Player1.hp > $Player2.hp:
				$CanvasLayer/Label.set_text("Player 1 wins!")
			else:
				$CanvasLayer/Label.set_text("Player 2 wins!")
			count2+=1
			if count2 == 60:
				get_tree().change_scene_to_file("res://menu.tscn")
		if player1Health != $Player1.hp:
			$CanvasLayer/p1foreground.size = Vector2($Player1.hp * 4, 30)
			player1Health = $Player1.hp
		if player1Health != $Player2.hp:
			$CanvasLayer/p2foreground.size = Vector2($Player2.hp * 4, 30)
			player1Health = $Player2.hp
	count +=1
