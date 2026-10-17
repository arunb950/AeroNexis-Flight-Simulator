extends RefCounted
class_name AeroNexisAerodynamics

## Simplified, physically based aerodynamic forces for a game flight model.
## Godot convention: aircraft forward is local -Z, right is +X, up is +Y.

static func calculate_forces(local_air_velocity: Vector3, config: Dictionary, air_density: float) -> Dictionary:
	var speed: float = local_air_velocity.length()
	if speed < 0.5:
		return {"lift": Vector3.ZERO, "drag": Vector3.ZERO, "angle_of_attack_deg": 0.0, "lift_coefficient": 0.0}

	var wing_area: float = float(config.get("wing_area_m2", 16.2))
	var lift_slope: float = float(config.get("lift_slope_per_rad", 4.8))
	var max_lift_coefficient: float = float(config.get("max_lift_coefficient", 1.35))
	var zero_lift_angle_deg: float = float(config.get("zero_lift_angle_deg", -2.0))
	var alpha_rad: float = atan2(-local_air_velocity.y, maxf(0.01, -local_air_velocity.z))
	var alpha_effective: float = alpha_rad - deg_to_rad(zero_lift_angle_deg)
	var alpha_stall_rad: float = deg_to_rad(float(config.get("stall_angle_deg", 16.0)))
	var cl_linear: float = lift_slope * alpha_effective
	var cl: float = clampf(cl_linear, -max_lift_coefficient, max_lift_coefficient)
	var stall_blend: float = smoothstep(alpha_stall_rad, alpha_stall_rad + deg_to_rad(10.0), absf(alpha_effective))
	if absf(alpha_effective) > alpha_stall_rad:
		cl = lerpf(cl, signf(alpha_effective) * max_lift_coefficient * 0.45, stall_blend)

	var dynamic_pressure: float = 0.5 * air_density * speed * speed
	var lift_magnitude: float = dynamic_pressure * wing_area * cl
	var lift_direction: Vector3 = Vector3.RIGHT.cross(local_air_velocity).normalized()
	if lift_direction.length_squared() < 0.001:
		lift_direction = Vector3.UP
	var lift: Vector3 = lift_direction * lift_magnitude

	var cd0: float = float(config.get("zero_lift_drag_coefficient", 0.032))
	var induced_factor: float = float(config.get("induced_drag_factor", 0.055))
	var cd: float = cd0 + induced_factor * cl * cl
	if absf(alpha_effective) > alpha_stall_rad:
		cd += float(config.get("stall_drag_increment", 0.35)) * stall_blend
	var drag: Vector3 = -local_air_velocity.normalized() * dynamic_pressure * wing_area * cd
	return {"lift": lift, "drag": drag, "angle_of_attack_deg": rad_to_deg(alpha_effective), "lift_coefficient": cl}
