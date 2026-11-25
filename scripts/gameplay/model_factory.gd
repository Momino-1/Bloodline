@tool
extends RefCounted
## Procedural meshes: the biconcave red blood cell and the little 3D illustrations used by the encyclopedia.

const OXY_COLOR := Color(0.88, 0.06, 0.08)
const DEOXY_COLOR := Color(0.36, 0.07, 0.24)


static func material(color: Color, roughness := 0.5, emission := 0.0, alpha := 1.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(color.r, color.g, color.b, alpha)
    m.roughness = roughness
    if emission > 0.0:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = emission
    if alpha < 1.0:
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    return m


static func cell_material(oxygenation := 1.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.roughness = 0.38
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    m.rim_enabled = true
    m.rim = 0.5
    m.rim_tint = 0.4
    m.emission_enabled = true
    apply_oxygenation(m, oxygenation)
    return m


## 0 = deoxygenated (dark purple-red), 1 = fully oxygenated (bright red).
static func apply_oxygenation(m: StandardMaterial3D, t: float) -> void:
    var c := DEOXY_COLOR.lerp(OXY_COLOR, clampf(t, 0.0, 1.0))
    m.albedo_color = c
    m.emission = c
    m.emission_energy_multiplier = 0.25


static func sphere(r: float) -> SphereMesh:
    var m := SphereMesh.new()
    m.radius = r
    m.height = r * 2.0
    m.radial_segments = 32
    m.rings = 16
    return m


static func add_mesh(parent: Node, mesh: Mesh, mat: Material, pos := Vector3.ZERO, scl := Vector3.ONE, rot_deg := Vector3.ZERO) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = mat
    mi.position = pos
    mi.scale = scl
    mi.rotation_degrees = rot_deg
    parent.add_child(mi)
    return mi


## Biconcave disc using the Evans–Fung erythrocyte profile.
static func biconcave_disc(radius := 1.0, rings := 28, segments := 44) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var half: Array = []
    for i in range(rings + 1):
        var rho := sin(float(i) / rings * PI * 0.5)
        var z := radius * 0.32 * sqrt(maxf(1.0 - rho * rho, 0.0)) * (0.2072 + 2.0026 * rho * rho - 1.1228 * pow(rho, 4.0))
        half.append([rho, z])
    for side in [1.0, -1.0]:
        for i in range(rings):
            for j in range(segments):
                var j1 := j + 1
                var a := _disc_pt(half[i], j, segments, radius, side)
                var b := _disc_pt(half[i + 1], j, segments, radius, side)
                var c := _disc_pt(half[i + 1], j1, segments, radius, side)
                var d := _disc_pt(half[i], j1, segments, radius, side)
                var tris := [a, b, c, a, c, d] if side > 0.0 else [a, c, b, a, d, c]
                for v in tris:
                    st.set_uv(Vector2(v.x, v.z) * 0.5 + Vector2(0.5, 0.5))
                    st.add_vertex(v)
    st.generate_normals()
    return st.commit()


static func _disc_pt(h: Array, j: int, segments: int, radius: float, side: float) -> Vector3:
    var th := TAU * float(j) / segments
    var rho: float = h[0]
    return Vector3(cos(th) * rho * radius, side * float(h[1]), sin(th) * rho * radius)


static func _tube(root: Node3D, outer_r: float, wall_color: Color, wall_alpha: float, cell_count: int, cell_r: float, lumen_color := Color(0.5, 0.05, 0.08)) -> void:
    var cyl := CylinderMesh.new()
    cyl.top_radius = outer_r
    cyl.bottom_radius = outer_r
    cyl.height = 2.8
    cyl.cap_top = false
    cyl.cap_bottom = false
    var wall := material(wall_color, 0.4, 0.2, wall_alpha)
    wall.cull_mode = BaseMaterial3D.CULL_DISABLED
    add_mesh(root, cyl, wall, Vector3.ZERO, Vector3.ONE, Vector3(0, 0, 90))
    var lumen := CylinderMesh.new()
    lumen.top_radius = outer_r * 0.62
    lumen.bottom_radius = outer_r * 0.62
    lumen.height = 2.75
    lumen.cap_top = false
    lumen.cap_bottom = false
    var lm := material(lumen_color, 0.5, 0.3, 0.35)
    lm.cull_mode = BaseMaterial3D.CULL_DISABLED
    add_mesh(root, lumen, lm, Vector3.ZERO, Vector3.ONE, Vector3(0, 0, 90))
    for i in cell_count:
        var x := -0.9 + 1.8 * float(i) / maxf(cell_count - 1, 1)
        add_mesh(root, biconcave_disc(cell_r), cell_material(1.0), Vector3(x, 0, 0), Vector3.ONE, Vector3(0, 0, 90))


static func make_model(shape: String) -> Node3D:
    var root := Node3D.new()
    match shape:
        "disc":
            add_mesh(root, biconcave_disc(1.1), cell_material(1.0), Vector3.ZERO, Vector3.ONE, Vector3(28, 0, 0))
        "haemoglobin":
            var cols := [Color(0.35, 0.55, 0.95), Color(0.55, 0.42, 0.92), Color(0.30, 0.75, 0.82), Color(0.78, 0.45, 0.88)]
            var dirs := [Vector3(-1, 1, 1), Vector3(1, 1, -1), Vector3(-1, -1, -1), Vector3(1, -1, 1)]
            for i in 4:
                var d: Vector3 = dirs[i].normalized()
                add_mesh(root, sphere(0.55), material(cols[i], 0.4), d * 0.5)
                add_mesh(root, sphere(0.2), material(Color(0.9, 0.1, 0.1), 0.3, 1.2), d * 0.98)
        "alveolus":
            var glass := Color(0.7, 0.88, 1.0)
            add_mesh(root, sphere(0.95), material(glass, 0.2, 0.3, 0.5))
            for i in 6:
                var a := TAU * i / 6.0
                add_mesh(root, sphere(0.42), material(glass, 0.2, 0.2, 0.45), Vector3(cos(a) * 1.15, sin(a * 2.0) * 0.5, sin(a) * 1.15))
            var tor := TorusMesh.new()
            tor.inner_radius = 0.95
            tor.outer_radius = 1.25
            var red := material(Color(0.8, 0.1, 0.14), 0.4, 0.6)
            add_mesh(root, tor, red)
            add_mesh(root, tor, red, Vector3.ZERO, Vector3.ONE, Vector3(90, 0, 30))
        "capillary":
            _tube(root, 0.30, Color(0.9, 0.5, 0.55), 0.5, 4, 0.18)
        "artery":
            _tube(root, 0.75, Color(0.65, 0.12, 0.16), 0.75, 3, 0.26)
        "vein":
            _tube(root, 0.8, Color(0.35, 0.3, 0.7), 0.45, 3, 0.26, Color(0.25, 0.1, 0.35))
            for s in [-1.0, 1.0]:
                add_mesh(root, sphere(0.25), material(Color(0.8, 0.75, 0.9), 0.4, 0.2, 0.8), Vector3(0.1, s * 0.35, 0), Vector3(0.4, 1.0, 0.5), Vector3(0, 0, s * 25))
        "mitochondrion":
            var cap := CapsuleMesh.new()
            cap.radius = 0.6
            cap.height = 2.4
            add_mesh(root, cap, material(Color(0.95, 0.55, 0.25), 0.4, 0.2, 0.45), Vector3.ZERO, Vector3.ONE, Vector3(0, 0, 90))
            for i in 7:
                var x := -0.8 + i * 0.27
                var cyl := CylinderMesh.new()
                cyl.top_radius = 0.42 - absf(x) * 0.1
                cyl.bottom_radius = cyl.top_radius
                cyl.height = 0.05
                add_mesh(root, cyl, material(Color(1.0, 0.45, 0.55), 0.4, 0.5), Vector3(x, (i % 2 - 0.5) * 0.12, 0), Vector3.ONE, Vector3(0, 0, 90))
        "atp":
            add_mesh(root, sphere(0.5), material(Color(0.4, 0.75, 1.0), 0.35, 0.4), Vector3(-1.2, 0, 0))
            for i in 3:
                var x := -0.3 + i * 0.7
                var col := Color(1.0, 0.8, 0.2) if i < 2 else Color(1.0, 0.4, 0.12)
                add_mesh(root, sphere(0.28), material(col, 0.3, 0.8), Vector3(x, 0, 0))
                var bond := CylinderMesh.new()
                bond.top_radius = 0.05
                bond.bottom_radius = 0.05
                bond.height = 0.5
                add_mesh(root, bond, material(Color(0.85, 0.85, 0.9), 0.5), Vector3(x - 0.38, 0, 0), Vector3.ONE, Vector3(0, 0, 90))
        "diffusion":
            var bm := BoxMesh.new()
            bm.size = Vector3(0.05, 2.2, 2.2)
            add_mesh(root, bm, material(Color(0.9, 0.5, 0.6), 0.5, 0.2, 0.4))
            var rng := RandomNumberGenerator.new()
            rng.seed = 11
            var pm := material(Color(0.55, 0.88, 1.0), 0.3, 1.5)
            for i in 28:
                add_mesh(root, sphere(0.09), pm, Vector3(rng.randf_range(-1.7, -0.15), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)))
            for i in 6:
                add_mesh(root, sphere(0.09), pm, Vector3(rng.randf_range(0.15, 1.7), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)))
        "cellular_respiration":
            for i in 6:
                var a := TAU * i / 6.0
                add_mesh(root, sphere(0.2), material(Color(0.95, 0.8, 0.5), 0.4, 0.3), Vector3(-1.5 + cos(a) * 0.5, sin(a) * 0.5, 0))
            var mito := make_model("mitochondrion")
            mito.scale = Vector3.ONE * 0.6
            mito.position = Vector3(0.9, 0, 0)
            root.add_child(mito)
            var o2 := material(Color(0.55, 0.88, 1.0), 0.3, 1.5)
            add_mesh(root, sphere(0.14), o2, Vector3(-0.35, 0.9, 0))
            add_mesh(root, sphere(0.14), o2, Vector3(-0.05, 0.9, 0))
        "heart_chambers":
            var blue := Color(0.35, 0.40, 0.90)
            var red := Color(0.85, 0.12, 0.15)
            add_mesh(root, sphere(0.5), material(blue.lightened(0.15), 0.4, 0.2), Vector3(-0.65, 0.6, 0))
            add_mesh(root, sphere(0.6), material(blue, 0.4, 0.2), Vector3(-0.6, -0.55, 0), Vector3(1.0, 1.2, 1.0))
            add_mesh(root, sphere(0.5), material(red.lightened(0.15), 0.4, 0.2), Vector3(0.65, 0.6, -0.1))
            add_mesh(root, sphere(0.65), material(red, 0.4, 0.2), Vector3(0.6, -0.5, 0), Vector3(1.1, 1.35, 1.1))
            var v1 := CylinderMesh.new()
            v1.top_radius = 0.14
            v1.bottom_radius = 0.14
            v1.height = 0.9
            add_mesh(root, v1, material(blue, 0.4, 0.2), Vector3(-0.95, 1.35, 0))
            add_mesh(root, v1, material(red, 0.4, 0.2), Vector3(0.1, 1.3, -0.2))
        _:
            add_mesh(root, sphere(0.8), material(Color(0.6, 0.6, 0.65), 0.5))
    return root
