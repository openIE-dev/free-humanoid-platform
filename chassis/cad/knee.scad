// knee.scad
// Free Humanoid Platform — Leg v0.1 — knee 1-DoF joint
//
// Single revolute joint (sagittal-plane flexion) using cycloidal reducer
// (BOM knee_reducer, RV-E-30E-HT, 30:1) + Maxon EC-i 50 (BOM knee_motor)
// + Moteus n1 (BOM knee_controller) + AS5048A position sensor + optional
// strain-gauge bridge.
//
// Corpus: sumitomo-cyclo (1937).
// REFERENCE GEOMETRY — NOT VALIDATED BY PHYSICAL BUILD.

include <leg_params.scad>;
use <hip.scad>;   // reuse cycloidal_envelope, motor_envelope, moteus_n1_envelope

// --------------------------------------------------------------------------
// knee_housing() — milled aluminum housing (BOM knee_housing)
// --------------------------------------------------------------------------
module knee_housing() {
    body_od     = cyclo_30_body_od;
    body_length = cyclo_30_body_length + ec_i_50_length + 10.0;

    color("Silver", 0.4)
    difference() {
        // Outer shell
        cylinder(h = body_length, d = body_od + 8.0, center = false);
        // Hollow interior to fit cycloidal + motor
        translate([0, 0, -0.1])
            cylinder(h = body_length + 0.2, d = body_od + 0.5, center = false);
    }
}

// --------------------------------------------------------------------------
// knee_torque_sensor() — annular strain-gauge disk (optional, BOM
// knee_torque_sensor)
// --------------------------------------------------------------------------
module knee_torque_sensor() {
    color("Maroon", 0.7)
    difference() {
        cylinder(h = sg_disk_thickness, d = sg_disk_od, center = false);
        translate([0, 0, -0.1])
            cylinder(h = sg_disk_thickness + 0.2, d = sg_disk_id, center = false);
    }
}

// --------------------------------------------------------------------------
// knee() — full knee joint stack
// --------------------------------------------------------------------------
module knee() {
    // Housing
    knee_housing();
    // Cycloidal reducer (input/output along Z)
    cycloidal_envelope(ratio = 30, peak_nm = knee_peak_torque_nm);
    // Motor on the proximal end
    translate([0, 0, cyclo_30_body_length + 5.0])
        motor_envelope(motor_class = "EC-i-50");
    // Moteus n1 on housing wall
    translate([cyclo_30_body_od / 2 + 5.0, -moteus_n1_l / 2,
               cyclo_30_body_length / 2])
        moteus_n1_envelope();
    // Strain-gauge disk on output side (between cycloidal output and tibia
    // end-cap input)
    translate([0, 0, -sg_disk_thickness])
        knee_torque_sensor();
    // AS5048A PCB on output side
    translate([-as5048_pcb_w / 2, -as5048_pcb_l / 2,
               -sg_disk_thickness - as5048_pcb_h - 0.5])
        color("DarkRed")
            cube([as5048_pcb_w, as5048_pcb_l, as5048_pcb_h]);
}

// --------------------------------------------------------------------------
// Demo render
// --------------------------------------------------------------------------
echo(str("knee.scad: peak torque ", knee_peak_torque_nm, " N·m, ratio 30:1"));
knee();
