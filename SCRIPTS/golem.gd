extends CharacterBody2D


const SPEED = 400.0
const JUMP_VELOCITY = -400.0

var direction := 1

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
		velocity.x = direction * SPEED * delta

	move_and_slide()
