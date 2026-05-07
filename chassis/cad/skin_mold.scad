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
