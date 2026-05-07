// spool.scad
// Free Humanoid Platform — Hand v0.1 — synergy spool
//
// Two variants:
//   1. spool_single()      — single-tendon (synergy approach), 8 mm OD body,
//                            5 mm groove width, mounts on Maxon GP 32 HP output.
//   2. spool_multi()       — multi-tendon (future independent-tendon designs),
//                            5 narrow grooves for per-finger control.
//
// Both spool variants include:
//   - central H7 bore for shaft (6 mm)
//   - M3 set-screw boss (radial)
//   - rear pocket for the AS5048A diametric magnet (6 mm × 2.5 mm N35H)
//
// REFERENCE GEOMETRY — NOT VALIDATED BY PHYSICAL BUILD.

include <hand_params.scad>;

module setscrew_boss() {
    // M3 set-screw radial boss — through-tap into the bore.
    translate([spool_flange_od/2 - 4, 0, spool_flange_t/2])
        rotate([0, 90, 0])
            cylinder(d=spool_setscrew_m + 0.2, h=spool_flange_od/2, $fn=$fn_lo);
}

module magnet_pocket() {
    // Rear-face diametric-magnet pocket for AS5048A (6 mm × 2.5 mm).
    translate([0, 0, -0.05])
        cylinder(d=magnet_pocket_dia,
                 h=magnet_pocket_depth,
                 $fn=$fn_hi);
}

module spool_single() {
    total_length = spool_body_length + 2 * spool_flange_t;
    difference() {
        union() {
            // bottom flange
            cylinder(d=spool_flange_od, h=spool_flange_t, $fn=$fn_hi);
            // body
            translate([0, 0, spool_flange_t])
                cylinder(d=spool_od + 2*spool_groove_pitch, // valley OD ~ 8 mm + wraps
                         h=spool_body_length, $fn=$fn_hi);
            // top flange
            translate([0, 0, spool_flange_t + spool_body_length])
                cylinder(d=spool_flange_od, h=spool_flange_t, $fn=$fn_hi);
        }
        // central bore (shaft H7)
        translate([0, 0, -1])
            cylinder(d=spool_bore, h=total_length + 2, $fn=$fn_hi);

        // Spiral-ish wrap groove approximated as N stacked circumferential grooves.
        // Each groove is a torus subtraction; pitch = spool_groove_pitch.
        for (i = [0 : spool_wraps - 1]) {
            z = spool_flange_t + 1.0 + i * spool_groove_pitch;
            translate([0, 0, z])
                rotate_extrude($fn=$fn_hi)
                    translate([spool_od/2 + spool_groove_pitch/2, 0, 0])
                        circle(r=tendon_dia/2 + 0.1, $fn=$fn_lo);
        }

        // Set-screw clearance
        setscrew_boss();

        // Rear-face magnet pocket (centered on bottom flange face)
        magnet_pocket();
    }
}

module spool_multi(grooves   = multi_spool_grooves,
                   groove_w  = multi_spool_groove_w)
{
    body_l = grooves * (groove_w + 1.0) + 2*spool_flange_t;
    difference() {
        union() {
            cylinder(d=spool_flange_od, h=spool_flange_t, $fn=$fn_hi);
            translate([0, 0, spool_flange_t])
                cylinder(d=spool_od + 4, h=body_l - 2*spool_flange_t, $fn=$fn_hi);
            translate([0, 0, body_l - spool_flange_t])
                cylinder(d=spool_flange_od, h=spool_flange_t, $fn=$fn_hi);
        }
        // bore
        translate([0, 0, -1])
            cylinder(d=spool_bore, h=body_l + 2, $fn=$fn_hi);
        // intermediate flanges between grooves are subtractive:
        // we cut groove_w-wide channels at each level
        for (i = [0 : grooves - 1]) {
            z0 = spool_flange_t + 0.5 + i * (groove_w + 1.0);
            translate([0, 0, z0])
                difference() {
                    cylinder(d=spool_flange_od + 2,
                             h=groove_w, $fn=$fn_hi);
                    cylinder(d=spool_od, h=groove_w, $fn=$fn_hi);
                }
        }
        // bore (re-cut to be sure)
        translate([0, 0, -1])
            cylinder(d=spool_bore, h=body_l + 2, $fn=$fn_hi);
        // set-screw + magnet pocket
        setscrew_boss();
        magnet_pocket();
    }
}

// --- self-test ---------------------------------------------------------------
// spool_single();
// translate([35, 0, 0]) spool_multi();
