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
// REFERENCE GEOMETRY — NOT VALIDATED BY PHYSICAL BUILD.

include <hand_params.scad>;

module pulley(od           = pulley_od,
              id           = pulley_id,
              height       = pulley_height,
              side_groove_radius = pulley_groove_r,
              flange_od    = pulley_flange_od)
{
    difference() {
        union() {
            // Two flanges separated by the body
            // bottom flange
            cylinder(d=flange_od, h=0.6, $fn=$fn_hi);
            // body
            translate([0, 0, 0.6])
                cylinder(d=od, h=height - 1.2, $fn=$fn_hi);
            // top flange
            translate([0, 0, height - 0.6])
                cylinder(d=flange_od, h=0.6, $fn=$fn_hi);
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
