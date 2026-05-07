// phalanx.scad
// Free Humanoid Platform — Hand v0.1 — single phalanx module
//
// Module signature:
//   phalanx(length, width, height, joint_type="MCP",
//           tendon_side="palmar", spring_pocket=true)
//
// joint_type ∈ {"MCP","PIP","DIP","THUMB_MCP","THUMB_IP"}
//   — currently affects only spring orientation and barrel placement.
// tendon_side ∈ {"palmar","dorsal"}
//   — palmar = flexor (default); dorsal = extensor (return-spring backup).
//
// REFERENCE GEOMETRY — NOT VALIDATED BY PHYSICAL BUILD.

include <hand_params.scad>;

// --- helper modules ----------------------------------------------------------

module joint_barrel(d=joint_barrel_od, h=joint_barrel_length) {
    // Cylindrical hub for a revolute joint, oriented along Y.
    rotate([90, 0, 0])
        cylinder(d=d, h=h, center=true, $fn=$fn_hi);
}

module axle_hole(d=axle_dia + axle_to_bushing_clearance, h=joint_barrel_length + 2) {
    rotate([90, 0, 0])
        cylinder(d=d, h=h, center=true, $fn=$fn_hi);
}

module bushing_pocket(h=joint_barrel_length) {
    // Two flanged-bushing pockets, one per side of the barrel.
    for (s = [-1, 1])
        translate([0, s * (h/2 - bushing_length/2), 0])
            rotate([90, 0, 0])
                cylinder(d=bushing_od + bushing_press_interference,
                         h=bushing_length + 0.1,
                         center=true, $fn=$fn_hi);
}

module spring_pocket(angle=0) {
    // Cylindrical pocket for a torsion spring riding on the joint axle.
    // Aligned with the axle (Y-axis); active leg slot cut into the proximal face.
    rotate([90, angle, 0])
        cylinder(d=spring_pocket_dia,
                 h=spring_pocket_length,
                 center=true, $fn=$fn_hi);
    // active-leg engagement slot (small radial slot)
    rotate([0, 0, angle])
        translate([spring_pocket_dia/2, 0, 0])
            cube([2.0, 1.5, spring_pocket_length], center=true);
}

module skin_mount_features() {
    // Small dimples / pegs on the dorsal face for skin Sil-Poxy bond points.
    for (s = [-1, 1]) {
        translate([s * 8, 0, 6])
            cylinder(d=2, h=1.2, $fn=16);
    }
}

// --- main phalanx module -----------------------------------------------------

module phalanx(length=proximal_length,
               width=proximal_width,
               height=proximal_height,
               joint_type="MCP",
               tendon_side="palmar",
               with_spring_pocket=true)
{
    difference() {
        union() {
            // Main body: rounded box extruded along X.
            hull() {
                for (x = [-length/2 + width/2, length/2 - width/2])
                    translate([x, 0, 0])
                        rotate([0, 90, 0])
                            cylinder(d=width, h=0.1, center=true, $fn=$fn_hi);
            }
            // Proximal joint barrel
            translate([-length/2, 0, 0])
                joint_barrel();
            // Distal joint barrel (smaller for distal phalanges)
            if (joint_type != "DIP" && joint_type != "THUMB_IP") {
                translate([length/2, 0, 0])
                    joint_barrel(d=joint_barrel_od * 0.85);
            } else {
                // Distal/IP fingertip: hemispherical cap
                translate([length/2, 0, 0])
                    sphere(d=width, $fn=$fn_hi);
            }
        }

        // Hollow the main body to phalanx_wall_t.
        translate([0, 0, 0])
            hull() {
                for (x = [-length/2 + width/2 + phalanx_wall_t,
                          length/2 - width/2 - phalanx_wall_t])
                    translate([x, 0, 0])
                        rotate([0, 90, 0])
                            cylinder(d=width - 2*phalanx_wall_t,
                                     h=0.1, center=true, $fn=$fn_hi);
            }

        // Proximal joint axle hole
        translate([-length/2, 0, 0]) axle_hole();
        // Proximal bushing pockets
        translate([-length/2, 0, 0]) bushing_pocket();
        // Distal joint axle hole (skip for fingertip)
        if (joint_type != "DIP" && joint_type != "THUMB_IP") {
            translate([length/2, 0, 0]) axle_hole();
            translate([length/2, 0, 0]) bushing_pocket();
        }

        // Spring pocket at proximal joint
        if (with_spring_pocket) {
            translate([-length/2, 0, 0]) spring_pocket();
        }

        // Tendon channel through full length
        // Manual channel because helper depends on local height var
        side_offset = (tendon_side == "palmar") ? -1 : 1;
        translate([0, 0, side_offset * (height/2 - 3.0)])
            rotate([0, 90, 0])
                cylinder(d=tendon_hole_dia,
                         h=length + 2,
                         center=true, $fn=$fn_lo);
    }

    // Skin attachment dimples (additive)
    skin_mount_features();
}

// --- self-test render --------------------------------------------------------
// Uncomment to preview a single phalanx in OpenSCAD:
// phalanx();
