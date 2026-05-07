// hip.scad
// Free Humanoid Platform — Leg v0.1 — hip 3-DoF cluster
//
// Three serial revolute joints (yaw → abduction → flexion) clustered so
// their axes intersect at the hip center. Each joint = cycloidal reducer
// (BOM hip_*_reducer) + Maxon EC-i 50/52 BLDC motor + Moteus n1 + AS5048A
// + optional strain-gauge bridge.
//
// Module signature: hip(joint_torques = [yaw, abd, flex])
//                   Peak torques in N·m used to size envelopes; defaults
//                   come from leg_params.scad.
//
// Corpus: sumitomo-cyclo (1937) for cycloidal prior-art shielding.
// REFERENCE GEOMETRY — NOT VALIDATED BY PHYSICAL BUILD.

include <leg_params.scad>;

// --------------------------------------------------------------------------
// cycloidal_envelope(ratio, peak_torque) — cylindrical envelope of an
// Onvio / Sumitomo cycloidal reducer. ratio ∈ {30, 50}.
// --------------------------------------------------------------------------
module cycloidal_envelope(ratio = 30, peak_nm = 100) {
    od     = (ratio == 30) ? cyclo_30_body_od : cyclo_50_body_od;
    length = (ratio == 30) ? cyclo_30_body_length : cyclo_50_body_length;
    color("DarkSlateGray")
        cylinder(h = length, d = od, center = false);
    // Output flange (slightly larger disk on the output side)
    color("DimGray")
        translate([0, 0, length])
            cylinder(h = 8.0, d = od * 0.85, center = false);
}

// --------------------------------------------------------------------------
// motor_envelope(motor_class) — EC-i 50 or EC-i 52
// --------------------------------------------------------------------------
module motor_envelope(motor_class = "EC-i-50") {
    od     = (motor_class == "EC-i-52") ? ec_i_52_od : ec_i_50_od;
    length = (motor_class == "EC-i-52") ? ec_i_52_length : ec_i_50_length;
    color("Goldenrod")
        cylinder(h = length, d = od, center = false);
}

// --------------------------------------------------------------------------
// moteus_n1_envelope() — small box on housing wall
// --------------------------------------------------------------------------
module moteus_n1_envelope() {
    color("ForestGreen")
        cube([moteus_n1_w, moteus_n1_l, moteus_n1_h], center = false);
}

// --------------------------------------------------------------------------
// hip_joint_module(ratio, motor_class, joint_name)
//   One single hip-joint stack: cycloidal + motor + controller in housing.
// --------------------------------------------------------------------------
module hip_joint_module(ratio = 30, motor_class = "EC-i-50",
                         joint_name = "yaw") {
    body_od     = (ratio == 30) ? cyclo_30_body_od : cyclo_50_body_od;
    body_length = (ratio == 30) ? cyclo_30_body_length : cyclo_50_body_length;
    motor_length = (motor_class == "EC-i-52") ? ec_i_52_length : ec_i_50_length;

    // Housing (thin-walled aluminum shell wrapping the cycloidal + motor)
    color("Silver", 0.4)
    difference() {
        cylinder(h = body_length + motor_length + 10.0,
                 d = body_od + 8.0, center = false);
        translate([0, 0, -0.1])
            cylinder(h = body_length + motor_length + 10.2,
                     d = body_od + 0.5, center = false);
    }
    // Cycloidal reducer
    cycloidal_envelope(ratio = ratio,
                        peak_nm = (joint_name == "flex") ? hip_flex_peak_torque_nm
                                  : (joint_name == "abd") ? hip_abd_peak_torque_nm
                                  : hip_yaw_peak_torque_nm);
    // Motor on input side (proximal-axial)
    translate([0, 0, body_length + 5.0])
        motor_envelope(motor_class = motor_class);
    // Moteus n1 on the side of the housing
    translate([body_od / 2 + 5.0, -moteus_n1_l / 2, body_length / 2])
        moteus_n1_envelope();
    // AS5048A PCB on output side (distal-axial)
    translate([-as5048_pcb_w / 2, -as5048_pcb_l / 2, -3.0])
        color("DarkRed")
            cube([as5048_pcb_w, as5048_pcb_l, as5048_pcb_h]);
}

// --------------------------------------------------------------------------
// hip(joint_torques) — 3-DoF cluster with axes intersecting at hip center
//   joint_torques = [yaw_peak_nm, abd_peak_nm, flex_peak_nm]
//
// Layout: hip-yaw axis is vertical (Z). Hip-abd axis is X (frontal).
// Hip-flex axis is Y (sagittal). All three intersect at origin (hip center).
// Cycloidals are arranged so the joint stacks fan out radially from the
// hip center; this keeps the kinematic intersection clean while allowing
// physical envelopes to coexist.
// --------------------------------------------------------------------------
module hip(joint_torques = [hip_yaw_peak_torque_nm,
                             hip_abd_peak_torque_nm,
                             hip_flex_peak_torque_nm]) {
    // Compile-time ratio + motor selection per joint. Hard-coded to match
    // the v0.1 BOM; future variants can pass these in.
    yaw_ratio   = 30;   yaw_motor   = "EC-i-50";
    abd_ratio   = 50;   abd_motor   = "EC-i-50";
    flex_ratio  = 50;   flex_motor  = "EC-i-52";

    // Hip-yaw stack — axis along +Z, motor extending up out of pelvis
    translate([0, 0, 0])
        rotate([0, 0, 0])
            hip_joint_module(ratio = yaw_ratio, motor_class = yaw_motor,
                              joint_name = "yaw");

    // Hip-abd stack — axis along +X, mounted lateral
    translate([cyclo_30_body_od / 2 + 20, 0, 0])
        rotate([0, 90, 0])
            hip_joint_module(ratio = abd_ratio, motor_class = abd_motor,
                              joint_name = "abd");

    // Hip-flex stack — axis along +Y, mounted aft (sagittal)
    translate([0, cyclo_50_body_od / 2 + 20, 0])
        rotate([90, 0, 0])
            hip_joint_module(ratio = flex_ratio, motor_class = flex_motor,
                              joint_name = "flex");

    // Hip-torso mount plate (BOM hip_torso_mount_plate)
    translate([-hip_mount_plate_w / 2, -hip_mount_plate_l / 2,
               -hip_mount_plate_t - 5.0])
        color("Silver")
            difference() {
                cube([hip_mount_plate_w, hip_mount_plate_l,
                       hip_mount_plate_t]);
                // 4× M8 mount holes
                for (sx = [-1, 1])
                for (sy = [-1, 1])
                    translate([hip_mount_plate_w / 2 + sx * hip_mount_pcd / 2,
                               hip_mount_plate_l / 2 + sy * hip_mount_pcd / 2,
                               -0.1])
                        cylinder(h = hip_mount_plate_t + 0.2,
                                 d = m8_clear_dia, center = false);
            }
}

// --------------------------------------------------------------------------
// Sanity-check echo when standalone
// --------------------------------------------------------------------------
echo(str("hip.scad: peak torques = yaw:", hip_yaw_peak_torque_nm,
          " abd:", hip_abd_peak_torque_nm,
          " flex:", hip_flex_peak_torque_nm, " N·m"));

// --------------------------------------------------------------------------
// Demo render when standalone
// --------------------------------------------------------------------------
hip();
