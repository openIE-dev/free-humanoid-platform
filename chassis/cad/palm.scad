// palm.scad
// Free Humanoid Platform — Hand v0.1 — palm chassis
//
// PA12 SLS-printed palm housing. Holds:
//   - 5 finger mount points (4 fingers + thumb opposed)
//   - central tendon-distribution channel
//   - motor mount bracket interface (4× M2.5 holes on 22 mm BCD)
//   - 8 in-palm tendon-routing pulleys (12 PEEK pulleys total per BOM;
//     4 are non-palm spares + spool pulley)
//   - cable terminator anchor (synergy tendon's far end fixation)
//   - load-cell mount cavity (Phidgets CZL635)
//   - wrist interface (3× M2.5 PCD 18 mm)
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
    // A pair of joint-barrel ears at each finger MCP, with axle hole
    translate([x, y, palm_thickness/2])
        rotate([0, 0, splay_deg])
        {
            difference() {
                union() {
                    for (s = [-1, 1])
                        translate([0, s * 7, 0])
                            rotate([90, 0, 0])
                                cylinder(d=joint_barrel_od,
                                         h=2.5, center=true, $fn=$fn_hi);
                }
                // axle hole
                rotate([90, 0, 0])
                    cylinder(d=axle_dia + axle_to_bushing_clearance,
                             h=20, center=true, $fn=$fn_hi);
                // bushing pockets
                for (s = [-1, 1])
                    translate([0, s * 6, 0])
                        rotate([90, 0, 0])
                            cylinder(d=bushing_od + bushing_press_interference,
                                     h=bushing_length + 0.1,
                                     center=true, $fn=$fn_hi);
            }
        }
}

module thumb_cmc_block() {
    // CMC carpometacarpal block — the opposed thumb mount.
    // A small angled prism at the radial side of the palm.
    translate([thumb_cmc_x, thumb_cmc_y, palm_thickness/2])
        rotate([0, 0, thumb_opposition_deg])
            difference() {
                union() {
                    // base block
                    translate([0, 0, 0])
                        cube([16, 14, 14], center=true);
                    // joint barrels
                    for (s = [-1, 1])
                        translate([0, s * 7, 0])
                            rotate([90, 0, 0])
                                cylinder(d=joint_barrel_od,
                                         h=2.5, center=true, $fn=$fn_hi);
                }
                // CMC axle hole
                rotate([90, 0, 0])
                    cylinder(d=axle_dia, h=20, center=true, $fn=$fn_hi);
            }
}

module motor_mount_iface() {
    // 4× M2.5 holes on 22 mm BCD — direct interface for motor_bracket.
    // Located on the proximal-palm dorsal face (back of palm).
    translate([0, -palm_length/2 + 18, palm_thickness - 2])
    {
        for (i = [0 : 3]) {
            rotate([0, 0, i * 90 + 45])
                translate([motor_face_pcd/2, 0, 0])
                    cylinder(d=motor_face_bolt_dia,
                             h=4.5, $fn=$fn_hi);
        }
        // central shaft clearance
        cylinder(d=motor_shaft_clear_dia + 1, h=4.5, $fn=$fn_hi);
    }
}

module wrist_interface() {
    // Proximal end of palm: circular flange with 3× M2.5 mounting holes.
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
            }
        }
}

module loadcell_cavity() {
    // CZL635 cable-tension load cell pocket (S-type micro load cell).
    // Inline with the synergy tendon between motor spool and the
    // distribution junction.
    translate([0, -palm_length/2 + 30, palm_thickness/2])
        cube([loadcell_cavity_w,
              loadcell_cavity_l,
              loadcell_cavity_h],
             center=true);
    // mount bolts (M2.5)
    for (s = [-1, 1])
        translate([0, -palm_length/2 + 30 + s * loadcell_cavity_l/2,
                   palm_thickness/2])
            rotate([90, 0, 0])
                cylinder(d=loadcell_mount_bolt_m + 0.3,
                         h=8, center=true, $fn=$fn_hi);
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

module palm_pulley_mounts() {
    // 8 in-palm pulley pivot holes laid out on a rough star pattern
    // in the cable-routing cavity.
    for (i = [0 : palm_pulley_count - 1]) {
        ang = i * (360 / palm_pulley_count);
        r   = 18;
        x   = r * cos(ang);
        y   = r * sin(ang);
        pulley_axle_hole(x, y);
    }
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
        // pulley axle holes
        palm_pulley_mounts();
        // load-cell cavity
        loadcell_cavity();
        // terminator anchor pocket
        terminator_anchor();
        // wrist interface bolt clearances (already embedded in wrist_interface)
    }
}

// --- module to instantiate the routing pulleys for assembly view -------------
module palm_pulleys() {
    for (i = [0 : palm_pulley_count - 1]) {
        ang = i * (360 / palm_pulley_count);
        r   = 18;
        x   = r * cos(ang);
        y   = r * sin(ang);
        translate([x, y, palm_wall_t + 0.5])
            pulley();
    }
}

// --- self-test ---------------------------------------------------------------
palm();
