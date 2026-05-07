// foot.scad
// Free Humanoid Platform — Leg v0.1 — foot plate + silicone pad
//
// Foot plate (BOM foot_plate): aluminum 6061, 150 × 100 × 8 mm, milled with
//   - 4× M4 mount pattern for ATI Mini40 FT sensor (or in-house substitute)
//   - silicone-pad bond pattern on underside
// Foot pad (BOM foot_pad): Dragon Skin 50 cast onto plate underside
//
// REFERENCE GEOMETRY — NOT VALIDATED BY PHYSICAL BUILD.

include <leg_params.scad>;

// --------------------------------------------------------------------------
// foot_plate_only() — bare aluminum plate
// --------------------------------------------------------------------------
module foot_plate_only() {
    color("LightSteelBlue")
    difference() {
        translate([-foot_plate_l / 2, -foot_plate_w / 2, 0])
            cube([foot_plate_l, foot_plate_w, foot_plate_t]);
        // FT-sensor mount pattern (4× M4 on 30 mm PCD, centered)
        for (i = [0 : ft_mini40_mount_bolt_n - 1]) {
            angle = i * 360 / ft_mini40_mount_bolt_n + 45;
            translate([cos(angle) * ft_mini40_mount_pcd / 2,
                       sin(angle) * ft_mini40_mount_pcd / 2,
                       -0.1])
                cylinder(h = foot_plate_t + 0.2,
                         d = m4_clear_dia, center = false);
        }
        // Silicone-pad bond pattern: 6 × 4 grid of 4 mm dia × 1 mm deep
        // dimples on underside (mechanical interlock for Sil-Poxy bond)
        for (i = [-2 : 2])
        for (j = [-1.5, -0.5, 0.5, 1.5])
            translate([i * 25, j * 30, 0])
                cylinder(h = 1.0, d = 4.0, center = false);
    }
}

// --------------------------------------------------------------------------
// foot_pad_only() — silicone pad on underside
// --------------------------------------------------------------------------
module foot_pad_only() {
    color("DimGray", 0.85)
    translate([-foot_plate_l / 2 + 5, -foot_plate_w / 2 + 5,
               -foot_pad_thickness])
        cube([foot_plate_l - 10, foot_plate_w - 10, foot_pad_thickness]);
}

// --------------------------------------------------------------------------
// ft_sensor_envelope() — ATI Mini40 cylinder above foot plate
// --------------------------------------------------------------------------
module ft_sensor_envelope() {
    color("Crimson", 0.7)
        translate([0, 0, foot_plate_t])
            cylinder(h = ft_mini40_body_length,
                     d = ft_mini40_body_od, center = false);
}

// --------------------------------------------------------------------------
// foot(view) — assembly
//   view = "assembled" → plate + pad + FT sensor
//   view = "plate"     → plate only
//   view = "mold"      → casting dam for pad
// --------------------------------------------------------------------------
module foot(view = "assembled") {
    if (view == "assembled") {
        foot_plate_only();
        foot_pad_only();
        ft_sensor_envelope();
    } else if (view == "plate") {
        foot_plate_only();
    } else if (view == "mold") {
        // Casting dam: 3 mm tall containment wall around the foot-plate
        // perimeter, on the underside.
        translate([0, 0, -foot_pad_thickness])
        difference() {
            translate([-foot_plate_l / 2 - 3, -foot_plate_w / 2 - 3, 0])
                cube([foot_plate_l + 6, foot_plate_w + 6,
                       foot_pad_thickness + 3]);
            translate([-foot_plate_l / 2 + 5, -foot_plate_w / 2 + 5, -0.1])
                cube([foot_plate_l - 10, foot_plate_w - 10,
                       foot_pad_thickness + 3.2]);
        }
    } else {
        foot_plate_only();
        foot_pad_only();
    }
}

// --------------------------------------------------------------------------
// Demo render
// --------------------------------------------------------------------------
echo(str("foot.scad: ", foot_plate_l, "x", foot_plate_w, "x",
          foot_plate_t, " plate + ", foot_pad_thickness,
          " mm Dragon Skin ", foot_pad_durometer, " pad"));
foot();
