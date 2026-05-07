// palm.scad
// Free Humanoid Platform — Hand v0.1 — palm chassis
//
// PA12 SLS-printed palm housing. Holds:
//   - 5 finger mount points (4 fingers + thumb opposed)
//   - central tendon-distribution channel
//   - motor mount bracket interface (4× M2.5 SHCS on palm_mount_pcd = 25 mm,
//     0/90/180/270; the smaller motor-face counterbore is on the bracket only)
//   - 3 in-palm tendon-routing pulleys (1 spool exit + 2 distribution junction)
//   - 5 MCP redirect pulley pockets (one per finger MCP mount)
//   - cable terminator anchor (synergy tendon's far end fixation)
//   - wrist interface (4× M2.5 PCD 18 mm + 2 mm keying pin)
//
// v0.1.1 fixes:
//   - #1: palm-side bolt circle now uses palm_mount_pcd (25 mm) at 0/90/180/270
//         to match motor_bracket.scad. The motor face PCD is on the bracket only.
//   - #4/#12: 8-equally-spaced palm pulleys reduced to 3 routed positions;
//             added MCP redirect pulley pockets to each finger_mcp_mount.
//   - #9: loadcell_cavity removed — load cell relocated forearm-side.
//   - #19: wrist flange now 4 bolts + 2 mm keying pin (was 3 bolts symmetric).
//   - #20: thumb CMC axle hole gets axle_to_bushing_clearance like other holes.
//
// REFERENCE GEOMETRY — NOT VALIDATED BY PHYSICAL BUILD.

include <hand_params.scad>;
use <pulley.scad>;

// --- helper modules ----------------------------------------------------------

module palm_shell() {
    // Rounded box, dorsal-palmar split implied along Z.
    hull() {
        for (x = [-palm_width/2 + 8, palm_width/2 - 8])
            for (y = [-palm_length/2 + 8, palm_length/2 - 8])
                translate([x, y, 0])
                    cylinder(d=16, h=palm_thickness, $fn=$fn_hi);
    }
}

module palm_hollow() {
    // Internal cavity for cable routing
    translate([0, 0, palm_wall_t])
        hull() {
            for (x = [-palm_width/2 + 8 + palm_wall_t,
                      palm_width/2 - 8 - palm_wall_t])
                for (y = [-palm_length/2 + 8 + palm_wall_t,
                          palm_length/2 - 8 - palm_wall_t])
                    translate([x, y, 0])
                        cylinder(d=14,
                                 h=palm_thickness - 2*palm_wall_t,
                                 $fn=$fn_hi);
        }
}

module finger_mcp_mount(x, y, splay_deg=0) {
    // A pair of joint-barrel ears at each finger MCP, with axle hole.
    // v0.1.1 fix #2: barrels are along X (lateral) so the axle pin shares
    // the X axis with the proximal phalanx joint barrel after rebuilt
    // finger.scad places the phalanx with its long axis along +Y.
    translate([x, y, palm_thickness/2])
        rotate([0, 0, splay_deg])
        {
            difference() {
                union() {
                    for (s = [-1, 1])
                        translate([s * 7, 0, 0])
                            rotate([0, 90, 0])
                                cylinder(d=joint_barrel_od,
                                         h=2.5, center=true, $fn=$fn_hi);
                }
                // axle hole (along X)
                rotate([0, 90, 0])
                    cylinder(d=axle_dia + axle_to_bushing_clearance,
                             h=20, center=true, $fn=$fn_hi);
                // bushing pockets
                for (s = [-1, 1])
                    translate([s * 6, 0, 0])
                        rotate([0, 90, 0])
                            cylinder(d=bushing_od + bushing_press_interference,
                                     h=bushing_length + 0.1,
                                     center=true, $fn=$fn_hi);
            }
        }
}

module thumb_cmc_block() {
    // CMC carpometacarpal block — the opposed thumb mount.
    // A small angled prism at the radial side of the palm.
    // v0.1.1 fix #2: CMC barrels along block's local X (matches rebuilt
    // finger.scad — long axis +Y, joint barrel along local X).
    translate([thumb_cmc_x, thumb_cmc_y, palm_thickness/2])
        rotate([0, 0, thumb_opposition_deg])
            difference() {
                union() {
                    // base block
                    translate([0, 0, 0])
                        cube([14, 16, 14], center=true);
                    // joint barrels (along local X)
                    for (s = [-1, 1])
                        translate([s * 7, 0, 0])
                            rotate([0, 90, 0])
                                cylinder(d=joint_barrel_od,
                                         h=2.5, center=true, $fn=$fn_hi);
                }
                // CMC axle hole — v0.1.1 fix #20: add axle_to_bushing_clearance
                // (was bare axle_dia → press fit; now slip fit).
                rotate([0, 90, 0])
                    cylinder(d=axle_dia + axle_to_bushing_clearance,
                             h=20, center=true, $fn=$fn_hi);
            }
}

module motor_mount_iface() {
    // v0.1.1 fix #1: 4× M2.5 holes on palm_mount_pcd (25 mm) at 0/90/180/270
    // to match motor_bracket.scad palm_mount_holes(). The smaller motor-face
    // pattern (PCD 27 / M3, Maxon GP 32 HP) is a separate counterbore on the
    // bracket itself; the palm only sees the palm-side bracket bolts.
    translate([0, -palm_length/2 + 18, palm_thickness - 2])
    {
        for (i = [0 : palm_mount_count - 1]) {
            rotate([0, 0, i * (360 / palm_mount_count)])
                translate([palm_mount_pcd/2, 0, 0])
                    cylinder(d=palm_mount_bolt_dia,
                             h=4.5, $fn=$fn_hi);
        }
        // central shaft clearance
        cylinder(d=motor_shaft_clear_dia + 1, h=4.5, $fn=$fn_hi);
    }
}

module wrist_interface() {
    // Proximal end of palm: circular flange with 4× M2.5 mounting holes
    // and one 2 mm keying pin offset between bolts (v0.1.1 fix #19 — was 3 bolts
    // symmetric, gave 3 install orientations; 4-bolt symmetric gives 4, so we
    // add the keying pin to lock orientation to a single install pose).
    translate([0, -palm_length/2 - 0.1, palm_thickness/2])
        rotate([90, 0, 0])
        {
            difference() {
                cylinder(d=wrist_iface_od, h=4, $fn=$fn_hi);
                for (i = [0 : wrist_iface_count - 1])
                    rotate([0, 0, i * (360 / wrist_iface_count)])
                        translate([wrist_iface_pcd/2, 0, -0.5])
                            cylinder(d=wrist_iface_bolt_m + 0.4,
                                     h=6, $fn=$fn_hi);
                // Keying pin hole: between bolts 0 and 1 (at +45°), on a
                // larger PCD so it does not collide with bolt clearance.
                rotate([0, 0, 45])
                    translate([wrist_iface_key_pcd/2, 0, -0.5])
                        cylinder(d=wrist_iface_key_dia + 0.2,
                                 h=6, $fn=$fn_hi);
            }
        }
}

// v0.1.1 fix #9: loadcell_cavity removed — Phidgets CZL635 load cell relocated
// to the forearm-side adjacent to the Moteus n1 (per assembly.md §5.4 forearm
// mounting). The forearm bracket housing the load cell is a forearm-subassembly
// artifact, not a hand v0.1.1 part. Module retained as a no-op stub for any
// caller that still includes it; the call site in palm() has been removed.
module loadcell_cavity() {
    // intentionally empty — see fix #9
}

module terminator_anchor() {
    // Far-end synergy tendon anchor: a small pocket with a cross-pin slot
    // for figure-8 knot retention.
    translate([0, palm_length/2 - 12, palm_thickness/2])
        difference() {
            cube([10, 12, 8], center=true);
            // tendon entry hole
            translate([0, -8, 0])
                rotate([90, 0, 0])
                    cylinder(d=tendon_hole_dia, h=20, center=true, $fn=$fn_lo);
            // knot pocket
            cube([6, 6, 5], center=true);
        }
}

module pulley_axle_hole(x, y) {
    translate([x, y, palm_wall_t - 0.1])
        cylinder(d=axle_dia, h=palm_thickness, $fn=$fn_hi);
}

// v0.1.1 fix #4: routing-driven 3-position layout (was 8-equally-spaced star).
// Pulley positions reference the cable path:
//   - p0: spool exit, just above motor mount (clears motor center by ≥ 8 mm)
//   - p1, p2: distribution junction, where the single tendon branches to the
//             5 sub-paths headed for each MCP redirect pulley
// Coordinates in palm frame (y positive = distal, x = lateral).
palm_pulley_positions = [
    [0,    -palm_length/2 + 30, 0],   // p0 — spool exit (8 mm beyond motor center y=-27)
    [-12,  -palm_length/2 + 50, 0],   // p1 — left branch of distribution junction
    [ 12,  -palm_length/2 + 50, 0],   // p2 — right branch of distribution junction
];

module palm_pulley_mounts() {
    for (p = palm_pulley_positions)
        pulley_axle_hole(p[0], p[1]);
}

// MCP redirect pulley pocket — added to each finger_mcp_mount per v0.1.1 fix #12.
// One pulley per finger handles the palm-channel-to-finger-channel transition.
module mcp_redirect_pulley_pocket(x, y) {
    // Pulley pivot just palmar of the MCP barrel (toward palmar tendon side).
    translate([x, y - 8, palm_thickness/2 - (palm_thickness/2 - 4)])
        cylinder(d=axle_dia + axle_to_bushing_clearance,
                 h=palm_thickness, $fn=$fn_hi);
}

// --- main palm module --------------------------------------------------------

module palm() {
    difference() {
        union() {
            palm_shell();
            // finger MCP mounts (index/middle/ring/pinky)
            for (i = [0 : 3]) {
                finger_mcp_mount(finger_mcp_x[i], finger_mcp_y[i]);
            }
            // thumb CMC block (opposed)
            thumb_cmc_block();
            // wrist flange
            wrist_interface();
        }
        // cavity for routing
        palm_hollow();
        // motor mount interface (back of palm)
        motor_mount_iface();
        // tendon central distribution channel
        translate([0, 0, palm_thickness/2])
            cube([tendon_channel_w, palm_length, tendon_channel_d],
                 center=true);
        // pulley axle holes (3 routing-driven positions; v0.1.1 fix #4)
        palm_pulley_mounts();
        // MCP redirect pulley axle holes (one per finger; v0.1.1 fix #12)
        for (i = [0 : 3])
            mcp_redirect_pulley_pocket(finger_mcp_x[i], finger_mcp_y[i]);
        // (load-cell cavity removed — v0.1.1 fix #9; lives forearm-side now)
        // terminator anchor pocket
        terminator_anchor();
        // wrist interface bolt clearances (already embedded in wrist_interface)
    }
}

// --- module to instantiate the routing pulleys for assembly view -------------
module palm_pulleys() {
    // 3 in-palm routing pulleys at routing-driven positions (v0.1.1 fix #4).
    for (p = palm_pulley_positions)
        translate([p[0], p[1], palm_wall_t + 0.5])
            pulley();
    // 5 MCP redirect pulleys, one per finger MCP (v0.1.1 fix #12).
    for (i = [0 : 3])
        translate([finger_mcp_x[i], finger_mcp_y[i] - 8, palm_wall_t + 0.5])
            pulley();
}

// --- self-test ---------------------------------------------------------------
palm();
