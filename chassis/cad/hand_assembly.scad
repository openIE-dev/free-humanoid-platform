// hand_assembly.scad
// Free Humanoid Platform — Hand v0.1 — top-level assembly
//
// Imports all modules and renders one of:
//   view_mode = VIEW_ASSEMBLED  — closed-hand assembled view
//   view_mode = VIEW_EXPLODED   — exploded view with translation offsets
//   view_mode = VIEW_SKELETON   — bare skeleton only (no skin, no mold)
//   view_mode = VIEW_MOLD       — mold halves only
//
// Render commands:
//   openscad -o hand_assembled.stl -D 'view_mode=0' hand_assembly.scad
//   openscad -o hand_exploded.png  -D 'view_mode=1' --imgsize=1600,1200 \
//            --camera=0,0,0,55,0,25,400 hand_assembly.scad
//
// REFERENCE GEOMETRY — NOT VALIDATED BY PHYSICAL BUILD.

include <hand_params.scad>;
use <phalanx.scad>;
use <finger.scad>;
use <palm.scad>;
use <pulley.scad>;
use <spool.scad>;
use <motor_bracket.scad>;
use <skin_mold.scad>;

// Override on command line: openscad -D 'view_mode=1' ...
view_mode = VIEW_ASSEMBLED;

// Explosion factor: 0 = assembled, 1 = standard explode, 2 = wide.
explode = (view_mode == VIEW_EXPLODED) ? 1 : 0;

module assembled_hand() {
    // Palm at origin
    palm();

    // In-palm pulleys
    color("DarkOrange") palm_pulleys();

    // Motor bracket attached to palm dorsal-proximal face
    color("Silver")
        translate([0, -palm_length/2 + 18,
                   palm_thickness + explode * 30])
            motor_bracket();

    // Spool on motor output (sits inside bracket / palm cavity)
    color("Goldenrod")
        translate([0, -palm_length/2 + 18,
                   palm_thickness - 18 - explode * 10])
            rotate([0, 0, 0])
                spool_single();

    // 4 fingers (index, middle, ring, pinky) at palm distal edge
    for (i = [0 : 3]) {
        color("LightGray")
            translate([finger_mcp_x[i],
                       palm_length/2 + (explode * 10),
                       palm_thickness/2])
                rotate([0, 0, 90])
                    finger();
    }

    // Thumb (opposed)
    color("LightGray")
        translate([thumb_cmc_x - (explode * 15),
                   thumb_cmc_y - (explode * 15),
                   palm_thickness/2])
            rotate([0, 0, thumb_opposition_deg + 90])
                finger(thumb=true);
}

module skeleton_only() {
    palm();
    for (i = [0 : 3]) {
        translate([finger_mcp_x[i], palm_length/2, palm_thickness/2])
            rotate([0, 0, 90])
                finger();
    }
    translate([thumb_cmc_x, thumb_cmc_y, palm_thickness/2])
        rotate([0, 0, thumb_opposition_deg + 90])
            finger(thumb=true);
}

module mold_only() {
    skin_mold(view = (view_mode == VIEW_EXPLODED) ? "exploded" : "closed");
}

// --- main render -------------------------------------------------------------

if (view_mode == VIEW_ASSEMBLED) {
    assembled_hand();
} else if (view_mode == VIEW_EXPLODED) {
    assembled_hand();
} else if (view_mode == VIEW_SKELETON) {
    skeleton_only();
} else if (view_mode == VIEW_MOLD) {
    mold_only();
} else {
    // default
    assembled_hand();
}
