// skin_mold.scad
// Free Humanoid Platform — Hand v0.1 — two-part silicone mold for the hand skin
//
// Approximates the assembled-skeleton outer envelope by a parametric proxy
// (rounded rectangular palm + 5 capsule fingers). The actual mold should be
// derived from the assembled-hand outer surface once the hand is solid; this
// file is a parametric stand-in that demonstrates the mold topology.
//
// Features:
//   - inner cavity matching skeleton outline + skin_thickness offset
//   - top half / bottom half split along the dorsal-palmar plane (Z=0)
//   - 4× alignment pin / pin-hole pairs (per cad-references §1.3)
//   - 1× wrist pour port
//   - vent holes at fingertip cavities
//   - thumbscrew bolt-down clamp bosses
//   - v0.1.2 fix #17: 1× skeleton-registration peg (3 mm × 3 mm square)
//     at the wrist coupler, engaging a captive square hole in the bottom
//     mold half. Indexes the skeleton to the bottom mold half so the
//     skeleton cannot drift during silicone pour.
//
// ---------------------------------------------------------------------------
// v0.1.2 fix #16 — STATUS OF THIS FILE
// ---------------------------------------------------------------------------
// hand_envelope_proxy() below is a v0.1.x INTERMEDIATE. The dorsal knuckles,
// palmar tendon-routing bumps, thumb CMC angle, and finger-base convergence
// are NOT represented — the proxy uses rounded-rectangular palm + capsule
// fingers as a stand-in. Cast skin made from this mold will fit loosely on
// dorsal knuckles and tightly at palmar tendon-channel ridges.
//
// v0.2 plan: regenerate hand_envelope_proxy() from
//
//     minkowski(<skeleton_union>, sphere(skin_thickness))
//
// over the assembled skeleton. TODO list for v0.2:
//   1. Render hand_assembly.scad in VIEW_SKELETON mode and export the
//      union STL (about 1 MB; skeleton_only() module already in place).
//   2. Run minkowski externally (OpenSCAD's built-in minkowski on dense
//      unions can take 10+ minutes — practical workflow is to import
//      the skeleton STL and run a CGAL/Manifold minkowski offline,
//      then re-import the offset surface as the mold cavity).
//   3. Replace hand_envelope_proxy() with import("skeleton_offset.stl").
//   4. Re-cut the alignment-peg captive hole position once the
//      skeleton-derived envelope shifts the wrist face.
//
// Held in v0.1.x because: (a) the v0.1 mold is needed only for the
// initial cast-skin Stage 6 build, where dimensional accuracy at the
// dorsal knuckle is not critical for the runbook test; and (b) doing
// this rebuild in OpenSCAD natively risks hours-long renders that block
// other CAD iteration. The minkowski rebuild is a v0.2 first-class task.
// ---------------------------------------------------------------------------
//
// REFERENCE GEOMETRY — NOT VALIDATED BY PHYSICAL BUILD.

include <hand_params.scad>;

// --- skeleton outer envelope proxy -------------------------------------------

module hand_envelope_proxy(skin_offset=0) {
    // Palm + 5 finger capsules (very rough envelope)
    // Palm
    hull() {
        for (x = [-palm_width/2 + 10, palm_width/2 - 10])
            for (y = [-palm_length/2 + 10, palm_length/2 - 10])
                translate([x, y, 0])
                    cylinder(d=20 + 2*skin_offset, h=palm_thickness + 2*skin_offset, $fn=$fn_lo);
    }
    // Fingers (4): index/middle/ring/pinky
    finger_total = proximal_length + middle_length + distal_length + 4;
    for (i = [0 : 3]) {
        translate([finger_mcp_x[i], palm_length/2, palm_thickness/2])
            rotate([90, 0, 0])
                hull() {
                    cylinder(d=proximal_width + 2*skin_offset, h=0.1, $fn=$fn_lo);
                    translate([0, 0, finger_total])
                        cylinder(d=distal_width + 2*skin_offset, h=0.1, $fn=$fn_lo);
                }
    }
    // Thumb
    thumb_total = thumb_proximal_length + thumb_distal_length + 4;
    translate([thumb_cmc_x, thumb_cmc_y, palm_thickness/2])
        rotate([0, 0, thumb_opposition_deg])
            rotate([0, 90, 0])
                hull() {
                    cylinder(d=thumb_width + 2*skin_offset, h=0.1, $fn=$fn_lo);
                    translate([0, 0, thumb_total])
                        cylinder(d=thumb_width*0.85 + 2*skin_offset,
                                 h=0.1, $fn=$fn_lo);
                }
}

// --- mold halves -------------------------------------------------------------

module mold_box() {
    // Outer mold envelope, big enough to enclose the hand + skin offset + walls
    bx = palm_width + 60;
    by = palm_length + (proximal_length+middle_length+distal_length) + 60;
    bz = palm_thickness + 2 * (skin_thickness + mold_wall_t);
    translate([0, 0, bz/2 - palm_thickness/2 - skin_thickness])
        cube([bx, by, bz], center=true);
}

module alignment_pins(half="top") {
    // 4 corner pins; on top half they are positive, on bottom they are holes.
    bx = palm_width + 60;
    by = palm_length + (proximal_length+middle_length+distal_length) + 60;
    z  = (half == "top") ? -2 : 0;  // protrude/cut at parting line (Z=0)
    for (sx = [-1, 1])
        for (sy = [-1, 1])
            translate([sx * (bx/2 - 8), sy * (by/2 - 8), z])
                cylinder(d=mold_pin_dia,
                         h=8, $fn=$fn_hi);
}

module pour_port() {
    // Wrist-end pour port — hole through the proximal wall of the mold.
    translate([0, -palm_length/2 - 25, palm_thickness/4])
        rotate([90, 0, 0])
            cylinder(d=mold_pour_port_dia, h=20, center=true, $fn=$fn_hi);
}

module fingertip_vents() {
    // Distal-fingertip vent holes — 4 vents (one per finger) plus 1 thumb vent.
    finger_total = proximal_length + middle_length + distal_length + 4;
    for (i = [0 : 3]) {
        translate([finger_mcp_x[i],
                   palm_length/2 + finger_total + 8,
                   palm_thickness/2 + skin_thickness + 4])
            cylinder(d=mold_vent_dia, h=20, $fn=$fn_lo);
    }
    // thumb vent
    translate([thumb_cmc_x + 35, thumb_cmc_y + 35,
               palm_thickness/2 + skin_thickness + 4])
        cylinder(d=mold_vent_dia, h=20, $fn=$fn_lo);
}

// v0.1.2 fix #17: skeleton-registration features.
// A 3 mm × 3 mm square peg projecting from the wrist-coupler face of the
// palm engages a captive square hole in the bottom mold half. With the
// alignment_pins() pegs registering top↔bottom mold halves, this feature
// registers skeleton↔bottom-mold so the skeleton cannot drift laterally
// during silicone pour. (Vertical registration comes from the skeleton
// resting on the bottom mold cavity floor.)
//
// The peg itself is a feature on the printed palm (palm.scad's wrist face)
// — see assembly.md §6 for installation. This module renders only the
// captive hole in the bottom mold half.
skeleton_reg_peg_w   = 3.0;   // mm — square peg side
skeleton_reg_peg_h   = 4.0;   // mm — peg projection length
skeleton_reg_peg_clr = 0.2;   // mm — clearance per side in mold hole

module skeleton_registration_hole() {
    // Position: at the wrist-coupler centerline, projecting into the
    // bottom mold half along -Y (proximal direction).
    translate([0, -palm_length/2 - 2, -palm_thickness/4])
        rotate([90, 0, 0])
            cube([skeleton_reg_peg_w + 2*skeleton_reg_peg_clr,
                  skeleton_reg_peg_w + 2*skeleton_reg_peg_clr,
                  skeleton_reg_peg_h + 2],
                 center=true);
}

module clamp_bolts() {
    bx = palm_width + 60;
    by = palm_length + (proximal_length+middle_length+distal_length) + 60;
    // 6 bolts: 2 on each long side, 1 on each short side (rough)
    positions = [
        [-bx/2 + 4, -by/2 + 20],
        [-bx/2 + 4,  by/2 - 20],
        [ bx/2 - 4, -by/2 + 20],
        [ bx/2 - 4,  by/2 - 20],
        [0, -by/2 + 4],
        [0,  by/2 - 4],
    ];
    for (p = positions)
        translate([p[0], p[1], -palm_thickness])
            cylinder(d=mold_clamp_bolt_m + 0.4,
                     h=palm_thickness * 4, $fn=$fn_hi);
}

module mold_top() {
    difference() {
        intersection() {
            mold_box();
            translate([0, 0, 1000]) cube([2000, 2000, 2000], center=true);
            // top half: above Z=0
        }
        // skin cavity = hand envelope + skin_thickness offset
        hand_envelope_proxy(skin_offset=skin_thickness);
        // pour port + vents + clamps
        pour_port();
        fingertip_vents();
        clamp_bolts();
        // pin holes on bottom mating surface (top half receives pins from bottom)
        alignment_pins(half="bottom");
    }
}

module mold_bottom() {
    difference() {
        union() {
            intersection() {
                mold_box();
                translate([0, 0, -1000]) cube([2000, 2000, 2000], center=true);
            }
            // alignment pins (positive on bottom)
            alignment_pins(half="top");
        }
        hand_envelope_proxy(skin_offset=skin_thickness);
        pour_port();
        fingertip_vents();
        clamp_bolts();
        // v0.1.2 fix #17: captive hole receives the skeleton registration peg
        // (which is a 3 mm square peg printed on the palm wrist face).
        skeleton_registration_hole();
    }
}

// --- assembly view -----------------------------------------------------------

module skin_mold(view="closed") {
    if (view == "closed") {
        mold_top();
        mold_bottom();
    } else if (view == "exploded") {
        translate([0, 0, palm_thickness + 30]) mold_top();
        mold_bottom();
    } else if (view == "top") {
        mold_top();
    } else if (view == "bottom") {
        mold_bottom();
    }
}

// --- self-test ---------------------------------------------------------------
skin_mold(view="exploded");
