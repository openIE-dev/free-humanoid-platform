// motor_bracket.scad
// Free Humanoid Platform — Hand v0.1 — motor mount bracket
//
// Milled aluminum 6061-T6 bracket. Holds Maxon EC-i 30 + GP 32 HP motor stack
// to the palm chassis. ~80 g.
//
// Features:
//   - 4× M3 motor face holes on motor_face_pcd (27 mm BCD, Maxon GP 32 HP)
//   - 4× M2.5 mount holes to palm.scad (palm_mount_pcd, 25 mm BCD)
//   - thermal mass relief (lightening pockets / fins)
//   - cable management notch
//   - central clearance for motor planetary output shaft
//
// v0.1.1 fixes:
//   - #1/#3: motor face holes laid out at 0/90/180/270 (was 45/135/225/315),
//            PCD 27 mm M3 (was PCD 22 mm M2.5) per Maxon GP 32 HP cat 166940.
//   - #14: comment was "4× M3 mount holes to palm" but param is M2.5;
//          resolved to M2.5 to match palm_mount_bolt_m.
//
// REFERENCE GEOMETRY — NOT VALIDATED BY PHYSICAL BUILD.

include <hand_params.scad>;

module motor_face_holes() {
    // v0.1.1 fix #1/#3: 0/90/180/270 layout (was 45/135/225/315)
    // to match the palm-side 0/90/180/270 layout — bracket and palm share
    // the same angular pattern (different PCDs: motor face vs palm mount).
    for (i = [0 : 3]) {
        rotate([0, 0, i * 90])
            translate([motor_face_pcd/2, 0, -0.5])
                cylinder(d=motor_face_bolt_dia,
                         h=20, $fn=$fn_hi);
    }
}

module palm_mount_holes(plate_thickness=8) {
    for (i = [0 : palm_mount_count - 1]) {
        rotate([0, 0, i * (360 / palm_mount_count)])
            translate([palm_mount_pcd/2, 0, -0.5])
                cylinder(d=palm_mount_bolt_dia,
                         h=plate_thickness + 1, $fn=$fn_hi);
    }
}

module thermal_relief_pockets() {
    // Lightening pockets between bolt holes; reduces mass and increases
    // surface area for natural convection cooling.
    for (i = [0 : 7]) {
        rotate([0, 0, i * 45 + 22.5])
            translate([motor_face_pcd/2 + 4, 0, 1.5])
                cylinder(d=4, h=10, $fn=$fn_lo);
    }
}

module cable_notch() {
    // Side-exit notch for motor lead bundle and encoder cable
    translate([0, motor_stack_od/2 + 1, 4])
        rotate([0, 90, 0])
            cylinder(d=6, h=motor_stack_od + 4, center=true, $fn=$fn_lo);
}

module motor_bracket() {
    plate_t   = 8.0;       // mm — bracket plate thickness
    plate_od  = motor_stack_od + 12; // mm

    difference() {
        union() {
            // Main mounting plate (where palm bolts go)
            cylinder(d=plate_od, h=plate_t, $fn=$fn_hi);
            // Outer flange that bolts to palm — slight scallop for material
            cylinder(d=plate_od + 4, h=2.0, $fn=$fn_hi);
        }
        // Central clearance for planetary output shaft
        translate([0, 0, -0.5])
            cylinder(d=motor_shaft_clear_dia,
                     h=plate_t + 1, $fn=$fn_hi);
        // Motor face holes (M3 PCD 27 — for face screws into Maxon GP 32 HP)
        motor_face_holes();
        // Counterbore for motor face screws (M3 SHCS head ~5.5 mm dia)
        for (i = [0 : 3]) {
            rotate([0, 0, i * 90])
                translate([motor_face_pcd/2, 0, plate_t - 2.5])
                    cylinder(d=5.6, h=3, $fn=$fn_lo);
        }
        // Palm mount holes (M2.5 PCD 25)
        palm_mount_holes(plate_t);
        // Thermal relief pockets
        thermal_relief_pockets();
        // Cable management notch
        cable_notch();
    }
}

// --- self-test ---------------------------------------------------------------
motor_bracket();
