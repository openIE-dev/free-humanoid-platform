// ankle.scad
// Free Humanoid Platform — Leg v0.1 — ankle 2-DoF QDD stack
//
// Serial 2-DoF cluster: pitch (sagittal) → roll (frontal). Each axis is a
// quasi-direct-drive (QDD) actuator: T-Motor U8 Lite KV150 outrunner BLDC
// (BOM ankle_*_qdd_motor) + Maxon GP 32 HP single-stage planetary 6.6:1
// (BOM ankle_*_qdd_planetary) + Moteus c1 (BOM ankle_*_controller) +
// AS5048A position sensor.
//
// Corpus: mini-cheetah (2019), cassie-osu, mit-cheetah-2 (2014).
// REFERENCE GEOMETRY — NOT VALIDATED BY PHYSICAL BUILD.

include <leg_params.scad>;

// --------------------------------------------------------------------------
// qdd_motor_envelope() — T-Motor U8 Lite outrunner (pancake form)
// --------------------------------------------------------------------------
module qdd_motor_envelope() {
    color("DarkOliveGreen")
        cylinder(h = qdd_motor_length, d = qdd_motor_od, center = false);
    // Output shaft
    color("Goldenrod")
        translate([0, 0, qdd_motor_length])
            cylinder(h = 8.0, d = qdd_motor_shaft_d, center = false);
}

// --------------------------------------------------------------------------
// qdd_planetary_envelope() — Maxon GP 32 HP 6.6:1
// --------------------------------------------------------------------------
module qdd_planetary_envelope() {
    color("DarkSlateGray")
        cylinder(h = qdd_planetary_length, d = qdd_planetary_od,
                  center = false);
}

// --------------------------------------------------------------------------
// moteus_c1_envelope() — small box on housing
// --------------------------------------------------------------------------
module moteus_c1_envelope() {
    color("ForestGreen")
        cube([moteus_c1_w, moteus_c1_l, moteus_c1_h], center = false);
}

// --------------------------------------------------------------------------
// ankle_pitch_housing() — milled aluminum 6061 (BOM ankle_pitch_housing)
// --------------------------------------------------------------------------
module ankle_pitch_housing() {
    color("Silver", 0.4)
    difference() {
        // Outer shell (rectangular bracket form)
        translate([-50, -45, 0])
            cube([100, 90, qdd_motor_length + qdd_planetary_length + 12]);
        // Hollow for motor + planetary
        translate([0, 0, -0.1])
            cylinder(h = qdd_motor_length + qdd_planetary_length + 12.2,
                     d = qdd_motor_od + 1.0, center = false);
    }
}

// --------------------------------------------------------------------------
// ankle_roll_yoke() — U-shape yoke (BOM ankle_roll_housing)
// --------------------------------------------------------------------------
module ankle_roll_yoke() {
    yoke_w = 110.0;
    yoke_l = 90.0;
    yoke_t = 10.0;
    arm_h  = qdd_motor_length + qdd_planetary_length + 15.0;

    color("Silver", 0.5)
    union() {
        // Bottom plate (mates to FT sensor / foot plate)
        translate([-yoke_w / 2, -yoke_l / 2, 0])
            cube([yoke_w, yoke_l, yoke_t]);
        // Two side arms (vertical), each holding one bearing for the
        // pitch-axis rotation
        for (sx = [-1, 1]) {
            translate([sx * (yoke_w / 2 - yoke_t / 2),
                       -yoke_l / 2, yoke_t])
                cube([yoke_t, yoke_l, arm_h]);
        }
    }
}

// --------------------------------------------------------------------------
// ankle_pitch_qdd() — single QDD stack for ankle-pitch
// --------------------------------------------------------------------------
module ankle_pitch_qdd() {
    // Motor
    qdd_motor_envelope();
    // Planetary stacked on top of motor (with shaft adapter — abstracted)
    translate([0, 0, qdd_motor_length + 2.0])
        qdd_planetary_envelope();
    // Moteus c1 on side of housing
    translate([qdd_motor_od / 2 + 5.0, -moteus_c1_l / 2,
               qdd_motor_length / 2])
        moteus_c1_envelope();
    // AS5048A on planetary output side
    translate([-as5048_pcb_w / 2, -as5048_pcb_l / 2,
               qdd_motor_length + qdd_planetary_length + 4.0])
        color("DarkRed")
            cube([as5048_pcb_w, as5048_pcb_l, as5048_pcb_h]);
}

// --------------------------------------------------------------------------
// ankle() — full 2-DoF ankle cluster
//   Pitch axis (Y, sagittal) is innermost (closer to tibia).
//   Roll axis (X, frontal) is outermost (closer to foot plate).
//   Axes intersect at the ankle center (~30 mm above the FT-sensor flange).
// --------------------------------------------------------------------------
module ankle() {
    // Roll yoke at base (mates to foot plate / FT sensor)
    ankle_roll_yoke();
    // Roll-axis QDD (mounted in one of the yoke arms, axis along +X)
    translate([55, 0, 30])
        rotate([0, 90, 0])
            ankle_pitch_qdd();
    // Pitch-axis QDD (mounted above the roll yoke, axis along +Y)
    translate([0, 55, 80])
        rotate([90, 0, 0])
            ankle_pitch_qdd();
    // Ankle-pitch housing (between pitch QDD and tibia end-cap)
    translate([0, 0, 110])
        ankle_pitch_housing();
}

// --------------------------------------------------------------------------
// Demo render
// --------------------------------------------------------------------------
echo(str("ankle.scad: pitch peak ", ankle_pitch_peak_torque_nm,
          " N·m, roll peak ", ankle_roll_peak_torque_nm,
          " N·m, ratio ", qdd_ratio, ":1"));
ankle();
