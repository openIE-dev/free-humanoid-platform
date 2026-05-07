// tibia.scad
// Free Humanoid Platform — Leg v0.1 — tibia tube parametric
//
// Tibia structural tube (BOM tibia_tube) + two end-caps (BOM tibia_endcap).
// Knee-side end-cap mates to knee cycloidal output (cyclo_30 output flange).
// Ankle-side end-cap mates to ankle-pitch QDD planetary input frame.
//
// REFERENCE GEOMETRY — NOT VALIDATED BY PHYSICAL BUILD.

include <leg_params.scad>;

// --------------------------------------------------------------------------
// tibia_tube_only() — bare aluminum tube
// --------------------------------------------------------------------------
module tibia_tube_only(length = tibia_tube_length) {
    color("LightSteelBlue")
    difference() {
        cylinder(h = length, d = tibia_tube_od, center = false);
        translate([0, 0, -0.1])
            cylinder(h = length + 0.2, d = tibia_tube_id, center = false);
    }
}

// --------------------------------------------------------------------------
// tibia_endcap(side) — milled aluminum end-cap
//   side = "knee"  → mates cyclo_30 output flange
//   side = "ankle" → mates ankle-pitch QDD housing
// --------------------------------------------------------------------------
module tibia_endcap(side = "knee") {
    pcd       = (side == "knee") ? cyclo_30_output_pcd : qdd_motor_face_pcd;
    bolt_m    = (side == "knee") ? cyclo_30_output_bolt_m : qdd_motor_face_bolt_m;
    bolt_n    = (side == "knee") ? cyclo_30_output_bolt_n : qdd_motor_face_bolt_n;
    flange_od = tibia_tube_od + 12.0;

    color("Silver")
    difference() {
        union() {
            cylinder(h = end_cap_axial_length,
                     d = tibia_tube_id - end_cap_press_int * 2,
                     center = false);
            translate([0, 0, end_cap_axial_length])
                cylinder(h = 8.0, d = flange_od, center = false);
        }
        // Central harness bore
        translate([0, 0, -0.1])
            cylinder(h = end_cap_axial_length + 8.2,
                     d = tibia_tube_id * 0.55, center = false);
        // Bolt circle
        for (i = [0 : bolt_n - 1]) {
            angle = i * 360 / bolt_n;
            translate([cos(angle) * pcd / 2,
                       sin(angle) * pcd / 2,
                       end_cap_axial_length - 0.1])
                cylinder(h = 8.5,
                         d = (bolt_m == 5) ? m5_clear_dia
                            : (bolt_m == 4) ? m4_clear_dia
                            : m6_clear_dia,
                         center = false);
        }
    }
}

// --------------------------------------------------------------------------
// tibia() — complete tibia assembly
// --------------------------------------------------------------------------
module tibia() {
    tibia_tube_only();
    // Ankle-side end-cap (z=0, pointing down)
    rotate([180, 0, 0])
        tibia_endcap(side = "ankle");
    // Knee-side end-cap (z=length, pointing up)
    translate([0, 0, tibia_tube_length])
        tibia_endcap(side = "knee");
}

// --------------------------------------------------------------------------
// Demo render
// --------------------------------------------------------------------------
tibia();
