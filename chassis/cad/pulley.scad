// pulley.scad
// Free Humanoid Platform — Hand v0.1 — generic parametric pulley
//
// Module signature:
//   pulley(od, id, height, side_groove_radius)
//
// Models a flanged tendon pulley with a circumferential V-groove or U-groove
// suited to UHMWPE / Spectra cable. Used by palm.scad to instantiate the
// 12 PEEK pulleys called out in the BOM (Misumi MBPB8-3-2).
//
// v0.1.2 fix #15: flange thickness 0.6 → 1.0 mm to match the Misumi MBPB8-3-2
// datasheet (4 mm total = two 1 mm flanges + 2 mm groove body). Earlier 0.6 mm
// flanges left the cable seated against an under-spec flange wall and risked
// pop-off under wrap-angle stress.
//
// REFERENCE GEOMETRY — NOT VALIDATED BY PHYSICAL BUILD.

include <hand_params.scad>;

module pulley(od           = pulley_od,
              id           = pulley_id,
              height       = pulley_height,
              side_groove_radius = pulley_groove_r,
              flange_od    = pulley_flange_od)
{
    // v0.1.2 fix #15: flange thickness now 1.0 mm (was 0.6 mm).
    flange_t = 1.0;
    difference() {
        union() {
            // Two flanges separated by the body
            // bottom flange
            cylinder(d=flange_od, h=flange_t, $fn=$fn_hi);
            // body
            translate([0, 0, flange_t])
                cylinder(d=od, h=height - 2*flange_t, $fn=$fn_hi);
            // top flange
            translate([0, 0, height - flange_t])
                cylinder(d=flange_od, h=flange_t, $fn=$fn_hi);
        }
        // Bore
        translate([0, 0, -0.5])
            cylinder(d=id, h=height + 1, $fn=$fn_hi);
        // Cable groove — toroidal subtraction at body midline
        translate([0, 0, height/2])
            rotate_extrude($fn=$fn_hi)
                translate([od/2, 0, 0])
                    circle(r=side_groove_radius, $fn=$fn_lo);
    }
}

// --- self-test ---------------------------------------------------------------
// pulley();
// translate([15, 0, 0]) pulley(od=12, id=4, height=6, side_groove_radius=1.5);
