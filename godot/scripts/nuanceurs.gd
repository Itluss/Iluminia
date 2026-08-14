class_name Nuanceurs
extends RefCounted
## L'IDENTITÉ VISUELLE d'Iluminia en shaders : « des êtres de lumière sur
## une île qui respire, sous un ciel d'aurores ».
##
## - `fresnel`  : le halo de bord qui nimbe chaque Lumin et le dragon — la
##   lumière qu'ils portent en eux déborde sur leur silhouette.
## - `sol`      : les veines lumineuses de l'île, des ondes concentriques
##   qui pulsent lentement depuis le sanctuaire central.
## - `ciel`     : dégradé de nuit + BANDES D'AURORE mouvantes + étoiles qui
##   scintillent — chaque thème d'arène teinte son aurore.
## - `vignette` : léger assombrissement des bords d'écran, concentre le
##   regard sur l'action (overlay CanvasItem du HUD).
##
## Tous compatibles GL Compatibility / web (pas de fonctions avancées).

const _CODE_FRESNEL := "
shader_type spatial;
render_mode blend_add, unshaded, cull_back, depth_draw_never;
uniform vec4 teinte : source_color = vec4(1.0);
uniform float intensite = 1.2;
void fragment() {
	float bord = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.6);
	float pulse = 0.85 + 0.15 * sin(TIME * 2.2);
	ALBEDO = teinte.rgb * intensite * pulse;
	ALPHA = bord;
}
"

const _CODE_SOL := "
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never;
uniform vec4 teinte : source_color = vec4(0.2, 0.8, 1.0, 1.0);
uniform vec4 teinte_bord : source_color = vec4(0.55, 0.35, 1.0, 1.0);
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) { discard; }
	float a = atan(p.y, p.x);
	// Ondes concentriques qui rayonnent du sanctuaire, ondulées par l'angle.
	float onde = sin(r * 22.0 - TIME * 0.9 + sin(a * 3.0 + TIME * 0.25) * 1.4);
	float veines = smoothstep(0.93, 1.0, onde) * smoothstep(0.10, 0.28, r);
	// Respiration discrète du bord de l'île.
	float bord = smoothstep(0.86, 1.0, r) * (0.30 + 0.14 * sin(TIME * 1.1));
	float fondu = 1.0 - smoothstep(0.965, 1.0, r);
	ALBEDO = teinte.rgb * veines * 0.4 + teinte_bord.rgb * bord * 0.35;
	ALPHA = (veines * 0.16 + bord * 0.18) * fondu;
}
"

const _CODE_CIEL := "
shader_type sky;
uniform vec4 haut : source_color = vec4(0.05, 0.09, 0.22, 1.0);
uniform vec4 horizon : source_color = vec4(0.29, 0.21, 0.52, 1.0);
uniform vec4 aurore : source_color = vec4(0.13, 0.81, 0.95, 1.0);
uniform vec4 aurore2 : source_color = vec4(0.54, 0.33, 0.96, 1.0);
void sky() {
	float h = clamp(EYEDIR.y, 0.0, 1.0);
	vec3 col = mix(horizon.rgb, haut.rgb, pow(h, 0.55));
	// Sous l'horizon : le vide sombre sous l'île flottante.
	if (EYEDIR.y < 0.0) { col = mix(horizon.rgb * 0.5, vec3(0.02, 0.03, 0.08), clamp(-EYEDIR.y * 3.0, 0.0, 1.0)); }
	// Deux nappes d'aurore qui ondulent lentement en travers du ciel.
	float m = smoothstep(0.08, 0.35, h) * smoothstep(0.95, 0.45, h);
	float b1 = sin(EYEDIR.x * 5.0 + TIME * 0.06 + sin(EYEDIR.z * 3.0 + TIME * 0.04) * 1.8) * 0.5 + 0.5;
	float b2 = sin(EYEDIR.z * 4.0 - TIME * 0.05 + sin(EYEDIR.x * 2.5) * 1.5) * 0.5 + 0.5;
	col += aurore.rgb * pow(b1, 3.0) * m * 0.38;
	col += aurore2.rgb * pow(b2, 3.0) * m * 0.30;
	// Étoiles : hachage par cellule de direction, scintillement individuel.
	vec3 cellule = floor(EYEDIR * 42.0);
	float g = fract(sin(dot(cellule, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
	if (g > 0.982 && h > 0.12) {
		float scint = 0.45 + 0.55 * sin(TIME * (1.5 + g * 3.0) + g * 40.0);
		col += vec3(0.9, 0.95, 1.0) * scint * smoothstep(0.12, 0.4, h);
	}
	COLOR = col;
}
"

const _CODE_VIGNETTE := "
shader_type canvas_item;
uniform float force = 0.5;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float v = smoothstep(0.75, 1.75, length(p));
	COLOR = vec4(0.02, 0.03, 0.09, v * force);
}
"


## Halo de bord d'un être de lumière (coque sphère légèrement plus grande).
static func fresnel(teinte: Color, intensite := 1.2) -> ShaderMaterial:
	var m := _mat(_CODE_FRESNEL)
	m.set_shader_parameter("teinte", teinte)
	m.set_shader_parameter("intensite", intensite)
	return m


## Veines lumineuses de l'île (quad posé sur la pelouse).
static func sol(teinte: Color, teinte_bord: Color) -> ShaderMaterial:
	var m := _mat(_CODE_SOL)
	m.set_shader_parameter("teinte", teinte)
	m.set_shader_parameter("teinte_bord", teinte_bord)
	return m


## Ciel-aurore d'un thème d'arène.
static func ciel(haut: Color, horizon: Color, aurore: Color, aurore2: Color) -> ShaderMaterial:
	var m := _mat(_CODE_CIEL)
	m.set_shader_parameter("haut", haut)
	m.set_shader_parameter("horizon", horizon)
	m.set_shader_parameter("aurore", aurore)
	m.set_shader_parameter("aurore2", aurore2)
	return m


## Vignette d'écran (ColorRect plein cadre dans le HUD).
static func vignette(force := 0.5) -> ShaderMaterial:
	var m := _mat(_CODE_VIGNETTE)
	m.set_shader_parameter("force", force)
	return m


static func _mat(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	return m
