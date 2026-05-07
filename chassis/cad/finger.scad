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

// v0.1.1 fixes applied to this module:
//   - #2: finger long axis is now +Y (was +X). Each phalanx is rotated 90°
//         about Z so its body (local +X) lays along finger frame +Y, and its
//         joint barrel (local +Y) aligns with finger frame +X — matching the
//         palm finger_mcp_mount barrels (also along X). Axle pin now shares
//         the X axis through palm MCP ear and proximal phalanx barrel.
//   - #6: MCP flex (flex_angles[0]) is now applied to the proximal phalanx.
//   - #7: DIP transform is nested inside PIP transform so PIP rotation
//         propagates to the distal phalanx position (kinematic chain),
//         instead of being a faked additive rotation in the parent frame.
//
// Flex axis: rotation about X (the joint barrel axis).
// All translations along +Y carry the chain distally.
module finger(thumb=false,
              splay_angle=0,
              flex_angles=[0, 0, 0])
{
    rotate([0, 0, splay_angle])
    {
        if (thumb) {
            // 2-phalanx thumb (proximal + distal). CMC block lives in palm.
            // MCP flex applied to proximal thumb phalanx (v0.1.1 fix #6).
            rotate([flex_angles[0], 0, 0])
                translate([0, thumb_proximal_length/2, 0])
                    rotate([0, 0, 90])
                        phalanx(length=thumb_proximal_length,
                                width=thumb_width,
                                height=thumb_height,
                                joint_type="THUMB_MCP",
                                tendon_side="palmar",
                                with_spring_pocket=true);

            // IP nested inside MCP transform (v0.1.1 fix #7).
            rotate([flex_angles[0], 0, 0])
                translate([0, thumb_proximal_length, 0])
                    rotate([flex_angles[1], 0, 0])
                        translate([0, thumb_distal_length/2 + 1, 0])
                            rotate([0, 0, 90])
                                phalanx(length=thumb_distal_length,
                                        width=thumb_width * 0.9,
                                        height=thumb_height * 0.9,
                                        joint_type="THUMB_IP",
                                        tendon_side="palmar",
                                        with_spring_pocket=true);
        }
        else {
            // 3-phalanx finger (proximal + middle + distal)

            // Proximal phalanx, hinged at MCP. v0.1.1 fix #6: apply MCP flex.
            rotate([flex_angles[0], 0, 0])
                translate([0, proximal_length/2, 0])
                    rotate([0, 0, 90])
                        phalanx(length=proximal_length,
                                width=proximal_width,
                                height=proximal_height,
                                joint_type="MCP",
                                tendon_side="palmar",
                                with_spring_pocket=true);

            // Middle phalanx, hinged at PIP — nested inside MCP transform.
            rotate([flex_angles[0], 0, 0])
                translate([0, proximal_length, 0])
                    rotate([flex_angles[1], 0, 0])
                        translate([0, middle_length/2 + 1, 0])
                            rotate([0, 0, 90])
                                phalanx(length=middle_length,
                                        width=middle_width,
                                        height=middle_height,
                                        joint_type="PIP",
                                        tendon_side="palmar",
                                        with_spring_pocket=true);

            // Distal phalanx, hinged at DIP — nested inside PIP, which is
            // nested inside MCP (v0.1.1 fix #7: kinematic chain composes).
            rotate([flex_angles[0], 0, 0])
                translate([0, proximal_length, 0])
                    rotate([flex_angles[1], 0, 0])
                        translate([0, middle_length + 2, 0])
                            rotate([flex_angles[2], 0, 0])
                                translate([0, distal_length/2, 0])
                                    rotate([0, 0, 90])
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
