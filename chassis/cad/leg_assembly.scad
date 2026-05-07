// leg_assembly.scad
// Free Humanoid Platform — Leg v0.1 — top-level assembly
//
// Imports all leg modules and renders one of:
//   view_mode = VIEW_ASSEMBLED  — full leg, hip → knee → ankle → foot
//   view_mode = VIEW_EXPLODED   — exploded along Z with translation offsets
//   view_mode = VIEW_KINEMATIC  — axes + origins only (no envelopes)
//   view_mode = VIEW_HIP_ONLY   — hip cluster only
//   view_mode = VIEW_KNEE_ONLY  — knee subassembly only
//   view_mode = VIEW_ANKLE_ONLY — ankle 2-DoF + foot only
//
// Render commands (assembled, exploded):
//   openscad -o leg_assembled.stl -D 'view_mode=0' leg_assembly.scad
//   openscad -o leg_exploded.png  -D 'view_mode=1' --imgsize=1600,1200 \
//            --camera=400,400,500,0,0,500,1500 leg_assembly.scad
//
// REFERENCE GEOMETRY — NOT VALIDATED BY PHYSICAL BUILD.

include <leg_params.scad>;
use <femur.scad>;
use <tibia.scad>;
use <hip.scad>;
use <knee.scad>;
use <ankle.scad>;
use <foot.scad>;

// Override on command line: openscad -D 'view_mode=1' ...
view_mode = VIEW_ASSEMBLED;

// Explosion factor: 0 = assembled, 1 = standard explode
explode = (view_mode == VIEW_EXPLODED) ? 1 : 0;

// --------------------------------------------------------------------------
// Z-coordinates for each subassembly (origin: hip center)
// --------------------------------------------------------------------------
z_hip_center      = 0;
z_femur_top       = z_hip_center      - hip_to_femur_top_z   - explode * 50;
z_femur_bottom    = z_femur_top       - femur_tube_length    - explode * 50;
z_knee_center     = z_femur_bottom    - 30                   - explode * 50;
z_tibia_top       = z_knee_center     - 30                   - explode * 50;
z_tibia_bottom    = z_tibia_top       - tibia_tube_length    - explode * 50;
z_ankle_center    = z_tibia_bottom    - 30                   - explode * 50;
z_foot_top        = z_ankle_center    - 80                   - explode * 30;

// --------------------------------------------------------------------------
// assembled_leg() — full chained leg
// --------------------------------------------------------------------------
module assembled_leg() {
    // Hip cluster at origin
    hip();

    // Femur tube
    translate([0, 0, z_femur_top])
        rotate([180, 0, 0])
            femur();

    // Knee at femur bottom
    translate([0, 0, z_knee_center])
        knee();

    // Tibia tube
    translate([0, 0, z_tibia_top])
        rotate([180, 0, 0])
            tibia();

    // Ankle at tibia bottom (note: ankle.scad models the cluster pointing
    // up; rotate so foot ends up below ankle in world frame)
    translate([0, 0, z_ankle_center])
        rotate([180, 0, 0])
            ankle();

    // Foot at the bottom
    translate([0, 0, z_foot_top])
        foot(view = "assembled");
}

// --------------------------------------------------------------------------
// kinematic_only() — wireframe of joint axes
// --------------------------------------------------------------------------
module kinematic_only() {
    // Hip center at origin: 3 intersecting axes
    color("Red") cylinder(h = 100, d = 4, center = true);                       // yaw axis (Z)
    rotate([0, 90, 0]) color("Green") cylinder(h = 100, d = 4, center = true);  // abd axis (X)
    rotate([90, 0, 0]) color("Blue") cylinder(h = 100, d = 4, center = true);   // flex axis (Y)

    // Femur (line from hip center to knee center)
    color("LightGray")
        translate([0, 0, z_knee_center / 2])
            cylinder(h = abs(z_knee_center), d = 4, center = true);

    // Knee axis (Y)
    translate([0, 0, z_knee_center])
        rotate([90, 0, 0])
            color("Blue") cylinder(h = 80, d = 4, center = true);

    // Tibia
    color("LightGray")
        translate([0, 0, (z_knee_center + z_ankle_center) / 2])
            cylinder(h = abs(z_knee_center - z_ankle_center), d = 4,
                      center = true);

    // Ankle pitch + roll (Y, X)
    translate([0, 0, z_ankle_center]) {
        rotate([90, 0, 0])
            color("Blue") cylinder(h = 80, d = 4, center = true);
        rotate([0, 90, 0])
            color("Green") cylinder(h = 80, d = 4, center = true);
    }

    // Foot footprint
    translate([0, 0, z_foot_top])
        color("DarkGray", 0.5)
            translate([-foot_plate_l / 2, -foot_plate_w / 2, 0])
                cube([foot_plate_l, foot_plate_w, foot_plate_t]);
}

// --------------------------------------------------------------------------
// main render
// --------------------------------------------------------------------------
if (view_mode == VIEW_ASSEMBLED || view_mode == VIEW_EXPLODED) {
    assembled_leg();
} else if (view_mode == VIEW_KINEMATIC) {
    kinematic_only();
} else if (view_mode == VIEW_HIP_ONLY) {
    hip();
} else if (view_mode == VIEW_KNEE_ONLY) {
    knee();
} else if (view_mode == VIEW_ANKLE_ONLY) {
    ankle();
    translate([0, 0, -100])
        foot();
} else {
    assembled_leg();
}

echo(str("leg_assembly.scad: target leg mass ", target_mass_total_g,
          " g (~", target_mass_total_g / 1000.0, " kg)"));
