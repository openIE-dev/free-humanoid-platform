// femur.scad
// Free Humanoid Platform — Leg v0.1 — femur tube parametric
//
// Femur structural tube (BOM femur_tube) + two end-caps (BOM femur_endcap).
// Hip-side end-cap mates to hip-flex cycloidal output flange (cyclo_50).
// Knee-side end-cap mates to knee cycloidal input housing (cyclo_30).
//
// REFERENCE GEOMETRY — NOT VALIDATED BY PHYSICAL BUILD.

include <leg_params.scad>;

// --------------------------------------------------------------------------
// femur_tube_only() — bare aluminum tube
// --------------------------------------------------------------------------
module femur_tube_only(length = femur_tube_length) {
    color("LightSteelBlue")
    difference() {
        cylinder(h = length, d = femur_tube_od, center = false);
        translate([0, 0, -0.1])
            cylinder(h = length + 0.2, d = femur_tube_id, center = false);
    }
}

// --------------------------------------------------------------------------
// femur_endcap(side) — milled aluminum end-cap
//   side = "hip"  → mates cyclo_50 output flange (hip-flex)
//   side = "knee" → mates cyclo_30 input housing (knee)
// --------------------------------------------------------------------------
module femur_endcap(side = "hip") {
    pcd       = (side == "hip") ? cyclo_50_output_pcd : cyclo_30_mount_pcd;
    bolt_m    = (side == "hip") ? cyclo_50_output_bolt_m : cyclo_30_mount_bolt_m;
    bolt_n    = (side == "hip") ? cyclo_50_output_bolt_n : cyclo_30_mount_bolt_n;
    flange_od = femur_tube_od + 12.0;  // 6 mm radial extension for bolt heads

    color("Silver")
    difference() {
        union() {
            // Tube-insertion plug (press-fit into femur ID)
            cylinder(h = end_cap_axial_length,
                     d = femur_tube_id - end_cap_press_int * 2,
                     center = false);
            // Outer flange (sits proud of tube)
            translate([0, 0, end_cap_axial_length])
                cylinder(h = 8.0, d = flange_od, center = false);
        }
        // Central bore (cable/harness pass-through)
        translate([0, 0, -0.1])
            cylinder(h = end_cap_axial_length + 8.2,
                     d = femur_tube_id * 0.55, center = false);
        // Bolt circle
        for (i = [0 : bolt_n - 1]) {
            angle = i * 360 / bolt_n;
            translate([cos(angle) * pcd / 2,
                       sin(angle) * pcd / 2,
                       end_cap_axial_length - 0.1])
                cylinder(h = 8.5,
                         d = (bolt_m == 5) ? m5_clear_dia : m6_clear_dia,
                         center = false);
        }
    }
}

// --------------------------------------------------------------------------
// femur() — complete femur assembly: tube + 2 end-caps
//   knee_side at z=0; hip_side at z=femur_tube_length
// --------------------------------------------------------------------------
module femur() {
    // Tube
    femur_tube_only();
    // Knee-side end-cap (z=0, pointing down)
    rotate([180, 0, 0])
        femur_endcap(side = "knee");
    // Hip-side end-cap (z=length, pointing up)
    translate([0, 0, femur_tube_length])
        femur_endcap(side = "hip");
}

// --------------------------------------------------------------------------
// Demo render when run standalone
// --------------------------------------------------------------------------
femur();
