// leg_params.scad
// Free Humanoid Platform — Leg v0.1 — central parameter file
//
// REFERENCE PARAMETERS — NOT VALIDATED BY PHYSICAL BUILD.
// All dimensions in millimeters unless otherwise noted.
// Cross-references to chassis/leg-v0.1-BOM.csv noted inline.
//
// Other modules `include <leg_params.scad>;` and reference these constants.
// Edit values here only — never hard-code dimensions in primitive modules.
//
// License: CC0-1.0 (the .scad source travels with the descriptor;
//          CERN-OHL-S applies to the rendered hardware artifacts).
// Author: Free Humanoid Platform contributors, 2026-05-06.

// --------------------------------------------------------------------------
// 0. Render resolution
// --------------------------------------------------------------------------
$fn_lo = 24;   // low-res for previews
$fn_hi = 96;   // hi-res for export
$fn    = $fn_lo;

// --------------------------------------------------------------------------
// 1. Leg-segment lengths (sagittal-plane working lengths, hip → ankle)
//    Anchored to descriptor kinematics: L_thigh and L_shank centers are
//    each 380 mm from the proximal joint origin (descriptor lines ~106-108).
// --------------------------------------------------------------------------
femur_working_length  = 380.0;   // mm — hip-flex axis to knee axis
tibia_working_length  = 380.0;   // mm — knee axis to ankle-pitch axis
foot_height           = 50.0;    // mm — ankle-roll axis to ground (descriptor: L_ANKLE_to_foot z=-0.05)

// Tube stock geometry (BOM femur_tube, tibia_tube)
femur_tube_od         = 38.0;    // mm — McMaster 9056K84 1.5 in nominal
femur_tube_wall       = 3.2;     // mm
femur_tube_id         = femur_tube_od - 2 * femur_tube_wall;
femur_tube_length     = 450.0;   // mm — stock length, includes both end-cap allowances

tibia_tube_od         = 32.0;    // mm
tibia_tube_wall       = 3.0;     // mm
tibia_tube_id         = tibia_tube_od - 2 * tibia_tube_wall;
tibia_tube_length     = 420.0;   // mm

end_cap_axial_length  = 30.0;    // mm — typical end-cap insertion + flange
end_cap_press_int     = 0.05;    // mm — light press into tube ID

// --------------------------------------------------------------------------
// 2. Joint torque targets (per architectural commitment #1)
//    Used by hip.scad / knee.scad / ankle.scad to size envelopes and
//    cross-check at render time against catalog reducer ratings.
// --------------------------------------------------------------------------
hip_yaw_peak_torque_nm   = 80.0;
hip_abd_peak_torque_nm   = 120.0;
hip_flex_peak_torque_nm  = 150.0;
knee_peak_torque_nm      = 150.0;
ankle_pitch_peak_torque_nm = 40.0;
ankle_roll_peak_torque_nm  = 40.0;

// Continuous torque (45–55% of peak typical for cycloidal; 30% for QDD)
hip_yaw_cont_torque_nm   = 40.0;
hip_abd_cont_torque_nm   = 60.0;
hip_flex_cont_torque_nm  = 75.0;
knee_cont_torque_nm      = 75.0;
ankle_pitch_cont_torque_nm = 12.0;
ankle_roll_cont_torque_nm  = 12.0;

// --------------------------------------------------------------------------
// 3. Cycloidal reducer envelope (BOM hip_*_reducer, knee_reducer)
//    Onvio S-series / Sumitomo CYCLO catalog dimensions (RV-E-30E / -50E
//    class). All values approximate — VERIFY against vendor mounting drawing
//    before fabricating housings.
// --------------------------------------------------------------------------
// 30:1 hip-yaw / knee variant
cyclo_30_body_od        = 95.0;     // mm — outer diameter of cycloidal body
cyclo_30_body_length    = 65.0;     // mm — axial length
cyclo_30_input_shaft_d  = 14.0;     // mm — input shaft diameter (motor-side coupling)
cyclo_30_output_pcd     = 50.0;     // mm — output flange bolt circle
cyclo_30_output_bolt_m  = 5.0;      // M5 output flange bolts
cyclo_30_output_bolt_n  = 4;        // 4× output bolts
cyclo_30_mount_pcd      = 80.0;     // mm — body-to-housing mount bolt circle
cyclo_30_mount_bolt_m   = 5.0;      // M5
cyclo_30_mount_bolt_n   = 6;        // 6× mount bolts

// 50:1 hip-abd / hip-flex variant (slightly larger envelope)
cyclo_50_body_od        = 110.0;
cyclo_50_body_length    = 75.0;
cyclo_50_input_shaft_d  = 14.0;
cyclo_50_output_pcd     = 60.0;
cyclo_50_output_bolt_m  = 6.0;      // M6 for higher torque
cyclo_50_output_bolt_n  = 4;
cyclo_50_mount_pcd      = 92.0;
cyclo_50_mount_bolt_m   = 6.0;
cyclo_50_mount_bolt_n   = 6;

// --------------------------------------------------------------------------
// 4. Motor envelopes (BOM hip_*_motor, knee_motor)
//    Maxon EC-i 50 / EC-i 52 catalog dimensions. Approximate.
// --------------------------------------------------------------------------
// EC-i 50 (200 W)
ec_i_50_od            = 50.0;     // mm — stator OD
ec_i_50_length        = 90.0;     // mm — body length excluding shaft
ec_i_50_shaft_d       = 8.0;      // mm — output shaft
ec_i_50_face_pcd      = 35.0;     // mm — front-face mount bolt circle
ec_i_50_face_bolt_m   = 4.0;      // M4
ec_i_50_face_bolt_n   = 4;

// EC-i 52 (320 W) — slightly larger for hip-flex
ec_i_52_od            = 52.0;
ec_i_52_length        = 100.0;
ec_i_52_shaft_d       = 8.0;
ec_i_52_face_pcd      = 38.0;
ec_i_52_face_bolt_m   = 4.0;
ec_i_52_face_bolt_n   = 4;

// --------------------------------------------------------------------------
// 5. QDD ankle stack (BOM ankle_*_qdd_motor, ankle_*_qdd_planetary)
//    T-Motor U8 Lite + Maxon GP 32 HP 6.6:1
// --------------------------------------------------------------------------
qdd_motor_od          = 88.0;     // mm — U8 Lite outrunner OD
qdd_motor_length      = 30.0;     // mm — pancake form factor
qdd_motor_shaft_d     = 12.0;     // mm — U8 output shaft
qdd_motor_face_pcd    = 70.0;     // mm — U8 mount holes
qdd_motor_face_bolt_m = 4.0;
qdd_motor_face_bolt_n = 6;

qdd_planetary_od        = 32.0;   // mm — GP 32 HP body OD
qdd_planetary_length    = 35.0;   // mm — single-stage 6.6:1 axial length
qdd_planetary_input_d   = 4.0;    // mm — input shaft (mates to U8 via custom adapter)
qdd_planetary_output_d  = 8.0;    // mm — output shaft
qdd_planetary_face_pcd  = 22.0;
qdd_planetary_face_bolt_m = 3.0;
qdd_planetary_face_bolt_n = 4;

// QDD ratio
qdd_ratio = 6.6;

// --------------------------------------------------------------------------
// 6. Bearings (BOM hip_yaw_bearings = 6907, hip_flex_bearings = 6908,
//                  ankle_*_bearings = 6905)
// --------------------------------------------------------------------------
brg_6905_id    = 25.0;  brg_6905_od    = 42.0;  brg_6905_w = 9.0;
brg_6907_id    = 35.0;  brg_6907_od    = 55.0;  brg_6907_w = 10.0;
brg_6908_id    = 40.0;  brg_6908_od    = 62.0;  brg_6908_w = 12.0;

// --------------------------------------------------------------------------
// 7. Joint position sensor (BOM *_encoder = AS5048A)
//    Same SKU + magnet pocket on every joint.
// --------------------------------------------------------------------------
as5048_pcb_w        = 22.0;   // mm — PCB outline (placeholder)
as5048_pcb_l        = 22.0;
as5048_pcb_h        = 1.6;    // mm — FR4 thickness
as5048_air_gap      = 1.0;    // mm — magnet face to PCB IC
as5048_magnet_d     = 6.0;    // mm — diametric magnet
as5048_magnet_h     = 2.5;    // mm
as5048_magnet_pocket_d = 6.1; // mm — clearance fit
as5048_magnet_pocket_h = 2.6; // mm

// --------------------------------------------------------------------------
// 8. Moteus controller (BOM *_controller)
// --------------------------------------------------------------------------
moteus_n1_w   = 53.0;   // mm — n1 outline (mjbots datasheet)
moteus_n1_l   = 46.0;
moteus_n1_h   = 12.0;
moteus_n1_mount_bolt_m = 3.0;

moteus_c1_w   = 32.0;   // mm — c1 smaller form factor
moteus_c1_l   = 41.0;
moteus_c1_h   = 8.0;
moteus_c1_mount_bolt_m = 2.5;

// --------------------------------------------------------------------------
// 9. Torque sensor (BOM *_torque_sensor) — strain-gauge bridge
//    Mounted on cycloidal output flange; geometry is just a thin annular
//    instrumented disk between cycloidal output and load frame.
// --------------------------------------------------------------------------
sg_disk_od        = 70.0;     // mm
sg_disk_id        = 30.0;     // mm
sg_disk_thickness = 4.0;      // mm — sized so peak stress is in the gauge linear range

// --------------------------------------------------------------------------
// 10. Foot plate + pad (BOM foot_plate, foot_pad)
// --------------------------------------------------------------------------
foot_plate_l        = 150.0;   // mm — heel-to-toe
foot_plate_w        = 100.0;   // mm — medial-to-lateral
foot_plate_t        = 8.0;     // mm
foot_plate_material = "Aluminum 6061";
foot_pad_thickness  = 5.0;     // mm — Dragon Skin 50 cast on underside
foot_pad_durometer  = "50A";
foot_pad_density_g_cm3 = 1.07; // Dragon Skin specific gravity

// FT-sensor mount pattern on foot plate (ATI Mini40 standard)
ft_mini40_mount_pcd      = 30.0;  // mm
ft_mini40_mount_bolt_m   = 4.0;
ft_mini40_mount_bolt_n   = 4;
ft_mini40_body_od        = 40.0;  // mm
ft_mini40_body_length    = 12.2;  // mm

// --------------------------------------------------------------------------
// 11. Hip-torso interface plate (BOM hip_torso_mount_plate)
// --------------------------------------------------------------------------
hip_mount_plate_l      = 110.0;  // mm
hip_mount_plate_w      = 110.0;
hip_mount_plate_t      = 12.0;
hip_mount_pcd          = 80.0;   // mm — to-pelvis bolt circle
hip_mount_bolt_m       = 8.0;    // M8 SHCS to torso (BOM torso_iface_bolts)
hip_mount_bolt_n       = 4;

// --------------------------------------------------------------------------
// 12. Joint kinematic origins (axis offsets — distances between successive
//     joint centers within the hip cluster). The hip 3-DoF cluster is
//     designed so all three axes intersect at a single hip center.
// --------------------------------------------------------------------------
hip_yaw_axis_z      = 0.0;       // mm — origin
hip_abd_axis_z      = 0.0;       // mm — coincident with yaw at hip center
hip_flex_axis_z     = 0.0;       // mm — coincident with abd
hip_to_femur_top_z  = 60.0;      // mm — hip-flex center to femur upper end-cap face

// --------------------------------------------------------------------------
// 13. Mass / target budget (informational — not used by geometry)
// --------------------------------------------------------------------------
target_mass_femur_g       = 850;    // tube + 2 end-caps
target_mass_tibia_g       = 650;
target_mass_foot_g        = 420;    // plate + pad
target_mass_hip_cluster_g = 4500;   // 3 cycloidals + 3 motors + 3 controllers + housings + bearings + sensors
target_mass_knee_g        = 1500;   // cycloidal + motor + controller + housing + bearings + sensors
target_mass_ankle_g       = 1300;   // 2 QDDs + 2 controllers + housings + bearings
target_mass_harness_g     = 380;    // wires + connectors
target_mass_FT_g          = 240;    // ATI Mini40 (omit if substitution)
target_mass_total_g       = 9840;   // sum — ~9.8 kg per leg, ~19.6 kg pair
                                    // matches descriptor pelvis + leg link masses approximately

// --------------------------------------------------------------------------
// 14. View flags for leg_assembly.scad
// --------------------------------------------------------------------------
VIEW_ASSEMBLED  = 0;
VIEW_EXPLODED   = 1;
VIEW_KINEMATIC  = 2;   // axes + origins only, no envelopes
VIEW_HIP_ONLY   = 3;
VIEW_KNEE_ONLY  = 4;
VIEW_ANKLE_ONLY = 5;

// --------------------------------------------------------------------------
// 15. Fastener defaults
// --------------------------------------------------------------------------
m3_clear_dia = 3.4;    // close clearance hole for M3
m4_clear_dia = 4.5;
m5_clear_dia = 5.5;
m6_clear_dia = 6.6;
m8_clear_dia = 9.0;
shcs_head_dia_factor = 1.6;  // approximate head OD = factor * thread

// --------------------------------------------------------------------------
// 16. TUNING NOTES — dimensions known to be best-guess
// --------------------------------------------------------------------------
// • Cycloidal envelopes (cyclo_30_*, cyclo_50_*) are catalog approximations;
//   verify against the actual Onvio / Sumitomo mounting drawing before
//   fabricating hip_yaw_housing / hip_abd_housing / hip_flex_housing /
//   knee_housing.
// • EC-i 50 / EC-i 52 dimensions are catalog approximations; pull official
//   Maxon datasheet PDFs (catalog IDs in the BOM) and confirm before
//   fabricating motor mount faces.
// • U8 Lite face_pcd is approximate (T-Motor doesn't publish a CAD STEP
//   freely); confirm from physical part on receipt and respin
//   ankle_pitch_housing if needed.
// • foot_plate_l/w are anatomical proxies (~25th-percentile adult male foot
//   length 240 mm; v0.1 plate is shorter at 150 mm to keep the BOM tractable
//   and let v0.1 be a stand-and-balance demo, not a stride-cycle demo).
// • target_mass_* are best-effort estimates; confirm by weighing each
//   subassembly during physical bring-up and update.
// • hip_to_femur_top_z is a placeholder; depends on cycloidal output flange
//   thickness + femur end-cap geometry — confirm during Phase 5 mock-up.
// • The hip-cluster axes-coincident geometry is the kinematic ideal;
//   physical implementation will have ~5–10 mm offsets between successive
//   axes due to bearing pack widths. The descriptor will need updating with
//   the as-built offsets.
