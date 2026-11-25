@tool
extends RefCounted
## Builds the organic blood-vessel tube procedurally.


static func build_tube(length: float, radius: float, rings := 100, segments := 40, seed_value := 7) -> ArrayMesh:
	var coarse := FastNoiseLite.new()
	coarse.seed = seed_value
	coarse.frequency = 0.045
	var fine := FastNoiseLite.new()
	fine.seed = seed_value + 5
	fine.frequency = 0.22
	var pts: Array = []
	var cols: Array = []
	for i in range(rings + 1):
		var z := -length * float(i) / rings
		var row_p := PackedVector3Array()
		var row_c := PackedColorArray()
		for j in range(segments):
			var th := TAU * float(j) / segments
			var cx := cos(th)
			var sy := sin(th)
			var n := coarse.get_noise_3d(cx * radius, sy * radius, z)
			var f := fine.get_noise_3d(cx * radius, sy * radius, z)
			var r := radius + n * 1.4 + f * 0.25
			row_p.append(Vector3(cx * r, sy * r, z))
			var t := clampf(0.5 + n * 0.9 + f * 0.4, 0.0, 1.0)
			row_c.append(Color(0.30, 0.04, 0.08).lerp(Color(0.436, 0.105, 0.146, 1.0), t))
		pts.append(row_p)
		cols.append(row_c)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(rings):
		for j in range(segments):
			var quad := [[i, j, j], [i + 1, j, j], [i + 1, (j + 1) % segments, j + 1],
						 [i, j, j], [i + 1, (j + 1) % segments, j + 1], [i, (j + 1) % segments, j + 1]]
			for k in quad:
				st.set_color(cols[k[0]][k[1]])
				st.set_uv(Vector2(float(k[2]) / segments * 4.0, -float(k[0]) / rings * length / 8.0))
				st.add_vertex(pts[k[0]][k[1]])
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


static func wall_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color.WHITE
	m.roughness = 0.4
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.clearcoat_enabled = true
	m.clearcoat = 0.5
	m.clearcoat_roughness = 0.3
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.5
	m.emission_enabled = true
	m.emission = Color(0.25, 0.02, 0.05)
	m.emission_energy_multiplier = 0.5
	var nt := NoiseTexture2D.new()
	var fn := FastNoiseLite.new()
	fn.frequency = 0.01
	nt.noise = fn
	nt.as_normal_map = true
	nt.seamless = true
	nt.width = 500
	nt.height = 500
	nt.bump_strength = 100
	m.normal_enabled = true
	m.normal_texture = nt
	m.normal_scale = 1
	return m
