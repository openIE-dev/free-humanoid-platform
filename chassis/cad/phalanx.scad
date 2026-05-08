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
    // v0.1.1 fix #10: add a Ø7 × 0.8 mm counterbore step at the outer face
    // of each pocket so the bushing flange seats flush instead of standing
    // proud — without this, flange fouls phalanx-to-phalanx mating face.
    for (s = [-1, 1]) {
        // Bore for the bushing body (sleeve)
        translate([0, s * (h/2 - bushing_length/2), 0])
            rotate([90, 0, 0])
                cylinder(d=bushing_od + bushing_press_interference,
                         h=bushing_length + 0.1,
                         center=true, $fn=$fn_hi);
        // Outer-face counterbore for the bushing flange
        translate([0, s * (h/2 - bushing_flange_t/2 + 0.05), 0])
            rotate([90, 0, 0])
                cylinder(d=bushing_flange_od,
                         h=bushing_flange_t + 0.1,
                         center=true, $fn=$fn_hi);
    }
}

module spring_pocket(angle=0) {
    // Cylindrical pocket for a torsion spring riding on the joint axle.
    // Aligned with the axle (Y-axis); active leg slot cut into the proximal face.
    rotate([90, angle, 0])
        cylinder(d=spring_pocket_dia,
                 h=spring_pocket_length,
                 center=true, $fn=$fn_hi);
    // active-leg engagement slot (small radial slot).
    // v0.1.1 fix #18: rotate the cube [90,0,0] so its long axis aligns with
    // the axle Y (the spring's plane), instead of standing along world Z.
    rotate([0, 0, angle])
        translate([spring_pocket_dia/2, 0, 0])
            rotate([90, 0, 0])
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

        // Tendon channel through full length.
        // v0.1.1 fix #11: moved z-position to just below the joint barrel
        // (-(height/2 - 1) on the palmar side), so the channel does NOT clip
        // through the barrel/bushing/axle bore. Plus a small dorsal-palmar
        // reroute segment at each joint to guide the tendon under the barrel.
        // v0.1.2 fix #26: assert that the offset distance leaves wall material
        // outside the channel. Channel sits at z = ±(height/2 - 1) with cable
        // dia 1.6 mm; we need at least 0.5 mm wall outboard, so height/2 - 1
        // must be ≥ tendon_hole_dia/2 + 0.5 → height ≥ 2*1.8 = 3.6 mm.
        // Current min phalanx height is distal_height = 14 mm — well above.
        // Guard fires only if a future tune drops a phalanx below ~4 mm thick.
        assert(height >= 2 * (tendon_hole_dia/2 + 0.5 + 1),
               "phalanx height too small for tendon-channel offset (height/2 - 1 must clear tendon_hole_dia/2)");
        side_offset = (tendon_side == "palmar") ? -1 : 1;
        z_main = side_offset * (height/2 - 1);
        // Main palmar/dorsal channel along X (full length)
        translate([0, 0, z_main])
            rotate([0, 90, 0])
                cylinder(d=tendon_hole_dia,
                         h=length + 2,
                         center=true, $fn=$fn_hi);
        // Small joint reroute: a short Z-direction segment at each joint
        // brings the tendon from the deep palmar channel up to the pulley
        // exit at the joint barrel underside.
        for (xs = [-1, 1]) {
            // skip distal reroute on tip phalanges (no distal joint)
            if (xs == 1 && (joint_type == "DIP" || joint_type == "THUMB_IP")) {
                // no distal reroute
            } else {
                translate([xs * length/2, 0, z_main + side_offset * -1.5])
                    cylinder(d=tendon_hole_dia,
                             h=3.0, center=true, $fn=$fn_hi);
            }
        }
    }

    // Skin attachment dimples (additive)
    skin_mount_features();
}

// --- self-test render --------------------------------------------------------
// Uncomment to preview a single phalanx in OpenSCAD:
// phalanx();
