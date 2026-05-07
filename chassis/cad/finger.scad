// finger.scad
// Free Humanoid Platform — Hand v0.1 — composed finger module
//
// Module signature:
//   finger(thumb=false, splay_angle=0, flex_angles=[0,0,0])
//
// Composes 3 phalanges (proximal, middle, distal) for index/middle/ring/pinky,
// or 2 phalanges (proximal, distal) for the thumb.
//
// flex_angles[i] applies a rotation at joint i (MCP, PIP, DIP) so the assembly
// can be rendered in any pose. Defaults to fully-extended (open hand).
//
// REFERENCE GEOMETRY — NOT VALIDATED BY PHYSICAL BUILD.

include <hand_params.scad>;
use <phalanx.scad>;

module finger(thumb=false,
              splay_angle=0,
              flex_angles=[0, 0, 0])
{
    rotate([0, 0, splay_angle])
    {
        if (thumb) {
            // 2-phalanx thumb (proximal + distal). CMC block lives in palm.
            // Proximal thumb phalanx
            phalanx(length=thumb_proximal_length,
                    width=thumb_width,
                    height=thumb_height,
                    joint_type="THUMB_MCP",
                    tendon_side="palmar",
                    with_spring_pocket=true);

            // Translate to the distal joint location and rotate by IP flex
            translate([thumb_proximal_length, 0, 0])
                rotate([0, flex_angles[0], 0])
                    translate([thumb_distal_length/2 + 1, 0, 0])
                        phalanx(length=thumb_distal_length,
                                width=thumb_width * 0.9,
                                height=thumb_height * 0.9,
                                joint_type="THUMB_IP",
                                tendon_side="palmar",
                                with_spring_pocket=true);
        }
        else {
            // 3-phalanx finger (proximal + middle + distal)

            // Proximal phalanx, hinged at MCP (whose axle is at the palm edge)
            phalanx(length=proximal_length,
                    width=proximal_width,
                    height=proximal_height,
                    joint_type="MCP",
                    tendon_side="palmar",
                    with_spring_pocket=true);

            // Middle phalanx, hinged at PIP
            translate([proximal_length, 0, 0])
                rotate([0, flex_angles[1], 0])
                    translate([middle_length/2 + 1, 0, 0])
                        phalanx(length=middle_length,
                                width=middle_width,
                                height=middle_height,
                                joint_type="PIP",
                                tendon_side="palmar",
                                with_spring_pocket=true);

            // Distal phalanx, hinged at DIP
            translate([proximal_length + middle_length + 2, 0, 0])
                rotate([0, flex_angles[1] + flex_angles[2], 0])
                    translate([distal_length/2 + 1, 0, 0])
                        phalanx(length=distal_length,
                                width=distal_width,
                                height=distal_height,
                                joint_type="DIP",
                                tendon_side="palmar",
                                with_spring_pocket=true);
        }
    }
}

// --- self-test ---------------------------------------------------------------
// Uncomment in OpenSCAD to preview an open finger and a flexed thumb:
// finger();
// translate([0, 40, 0]) finger(thumb=true, flex_angles=[30, 0, 0]);
