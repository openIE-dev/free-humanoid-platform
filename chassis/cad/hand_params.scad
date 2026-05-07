// hand_params.scad
// Free Humanoid Platform — Hand v0.1 — central parameter file
//
// REFERENCE PARAMETERS — NOT VALIDATED BY PHYSICAL BUILD.
// All dimensions in millimeters unless otherwise noted.
// Cross-references to chassis/hand-v0.1-BOM.csv noted inline.
//
// Other modules `include <hand_params.scad>;` and reference these constants.
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
// 1. Phalanx envelope dimensions
//    Anatomical proxies for first build; tune to physical CAD later.
//    NOTE: real human phalanx lengths follow a ~0.6 ratio chain
//    (proximal : middle : distal ≈ 5 : 3 : 2.5). Values here approximate that.
// --------------------------------------------------------------------------
proximal_length = 50;   // mm — index/middle/ring/pinky proximal phalanx
proximal_width  = 18;
proximal_height = 18;

middle_length   = 30;
middle_width    = 16;
middle_height   = 16;

distal_length   = 25;
distal_width    = 14;
distal_height   = 14;

// Thumb (anatomically 2 phalanges; CMC block is part of palm)
thumb_proximal_length = 35;
thumb_distal_length   = 30;
thumb_width           = 18;   // thumb is generally thicker than fingers
thumb_height          = 18;
thumb_opposition_deg  = 80;   // angle of thumb axis vs. palm long axis

// --------------------------------------------------------------------------
// 2. Joint mechanics
//    BOM joint_axle = Misumi PB3-30-NN-A: 3 mm dia x 30 mm hardened dowel pin
//    BOM bushing    = SAE 841 bronze flanged sleeve, 3 mm ID x 5 mm OD x 4 mm L
// --------------------------------------------------------------------------
axle_dia          = 3.0;     // mm — joint pin (BOM joint_axle)
axle_length       = 30.0;    // mm — pin length (BOM)
bushing_id        = 3.0;     // mm — matches axle dia
bushing_od        = 5.0;     // mm — bushing outer diameter
bushing_length    = 4.0;     // mm — bushing axial length
bushing_flange_od = 7.0;     // mm — flange OD (estimated; verify vendor drawing)
bushing_flange_t  = 0.8;     // mm — flange thickness (estimated)

// Fits (ISO 286):
//   axle (3 mm h6) into bushing ID (3 mm H7) → H7/h6 slip fit
//   bushing OD (5 mm k6) press into PA12 bore (5 mm H7) → H7/k6 light press
axle_to_bushing_clearance     = 0.02;   // mm (H7/h6 nominal)
bushing_press_interference    = 0.03;   // mm (H7/k6 nominal; PA12 elastic)

// Joint barrel geometry (the PA12 part that hosts the bushings)
joint_barrel_od     = 12.0;     // mm — outer diameter of the joint hub
joint_barrel_length = 10.0;     // mm — axial length (sized for two flanged bushings + spring stack)

// Return spring — Lee Spring LTR-040A-04S
// 0.040 in wire, 0.187 in OD, 90° free angle.
spring_wire_dia      = 1.02;    // mm (0.040 in)
spring_od            = 4.75;    // mm (0.187 in)
spring_id            = 2.71;    // mm (≈ OD − 2*wire)
spring_free_angle    = 90;      // deg
spring_pocket_dia    = 5.5;     // mm (spring OD + clearance)
spring_pocket_length = 5.0;     // mm (axial)

// --------------------------------------------------------------------------
// 3. Tendon
//    BOM tendon_line_alt = Honeywell Spectra HL-25 (~1.5 mm working dia)
//    BOM tendon_line     = Samson AmSteel-Blue 1.5 mm UHMWPE 12-strand
// --------------------------------------------------------------------------
tendon_dia          = 1.5;     // mm — nominal cable dia
tendon_hole_dia     = 1.6;     // mm — through-hole for tendon (slip)
tendon_channel_w    = 4.0;     // mm — palm channel slot width
tendon_channel_d    = 2.0;     // mm — palm channel slot depth
tendon_min_bend_r   = 8.0;     // mm — 8x cable dia (Samson spec safety margin)

// --------------------------------------------------------------------------
// 4. Pulleys & spool
//    BOM pulley = Misumi MBPB8-3-2: 8 mm OD x 3 mm bore x 2 mm flange
// --------------------------------------------------------------------------
pulley_od            = 8.0;
pulley_id            = 3.0;
pulley_height        = 4.0;     // mm — total stack height including flange
pulley_groove_r      = 1.0;     // mm — half of cable dia + creep margin
pulley_flange_od     = 9.5;     // mm — outer flange diameter (groove walls)

// Spool (motor output)
spool_od             = 8.0;     // mm — body OD (groove valley)
spool_flange_od      = 22.0;    // mm — end-flange OD per cad-references §1.4
spool_flange_t       = 1.5;     // mm
spool_body_length    = 12.0;    // mm — body axial length
spool_groove_w       = 5.0;     // mm — groove width (single-tendon variant)
spool_bore           = 6.0;     // mm — H7 to motor shaft
spool_setscrew_m     = 3.0;     // mm — M3 set-screw
spool_groove_pitch   = 1.8;     // mm — spiral wrap pitch (multi-wrap synergy)
spool_wraps          = 5;       // number of cable wraps in groove

// Multi-tendon spool variant (future independent-tendon design)
multi_spool_grooves  = 5;       // one groove per finger
multi_spool_groove_w = 3.0;     // narrower groove for independent control

// Magnet pocket (AS5048A diametric magnet, 6 mm × 2.5 mm)
magnet_pocket_dia    = 6.1;     // mm — clearance fit
magnet_pocket_depth  = 2.6;     // mm

// --------------------------------------------------------------------------
// 5. Skin
//    BOM skin = Smooth-On Dragon Skin 30 platinum-cure silicone
// --------------------------------------------------------------------------
skin_thickness          = 1.5;     // mm — dorsal/palmar/lateral default
skin_thickness_fingertip= 3.0;     // mm — fingertip pad
skin_density_g_cm3      = 1.07;    // Dragon Skin 30 ~specific gravity

// --------------------------------------------------------------------------
// 6. Skeleton material
// --------------------------------------------------------------------------
skel_material         = "PA12-SLS";
skel_density_g_cm3    = 1.06;       // PA12 nominal
phalanx_wall_t        = 3.0;        // mm — parametric wall thickness
palm_wall_t           = 3.5;        // mm — palm structural wall

// --------------------------------------------------------------------------
// 7. Motor mount — Maxon GP 32 HP face
//    Maxon GP 32 catalog: 4× M3 face holes on PCD ~22 mm (verify against
//    Maxon mounting drawing 166940 prior to ordering bracket stock).
//    cad-references.md §1.5 calls out 4× M2.5 to palm chassis.
// --------------------------------------------------------------------------
motor_face_pcd        = 22.0;       // mm — bolt circle diameter on motor face
motor_face_bolt_m     = 2.5;        // mm — M2.5 face screws
motor_face_bolt_dia   = 2.7;        // mm — clearance hole (M2.5 close fit)
motor_shaft_clear_dia = 11.0;       // mm — central clearance for planetary output

palm_mount_pcd        = 25.0;       // mm — mount-to-palm bolt circle (cad-ref §1.5)
palm_mount_bolt_m     = 2.5;        // mm — M2.5 to palm
palm_mount_bolt_dia   = 2.7;        // mm — clearance for M2.5
palm_mount_count      = 4;

// Motor stack approximate envelope (EC-i 30 + GP 32 HP combined)
motor_stack_od        = 32.0;       // mm — stator OD
motor_stack_length    = 70.0;       // mm — combined motor + planetary head
                                    // (estimate — verify against Maxon spec sheet
                                    //  before motor_bracket fab)

// --------------------------------------------------------------------------
// 8. Palm chassis
// --------------------------------------------------------------------------
palm_length    = 90.0;     // mm — overall palm long-axis
palm_width     = 75.0;     // mm — overall palm width
palm_thickness = 30.0;     // mm — dorsal-palmar
palm_finger_count = 5;

// Finger MCP attachment offsets along palm distal edge (anatomical proxy):
//   index, middle, ring, pinky equally spaced; thumb opposed.
// Adjust these arrays in palm.scad consumer; provide defaults here.
finger_mcp_x = [-30, -10, 10, 30];   // mm (lateral) for index..pinky
finger_mcp_y = [palm_length/2, palm_length/2, palm_length/2, palm_length/2];

thumb_cmc_x = -palm_width/2 + 10;
thumb_cmc_y = palm_length/2 - 25;

// 12 PEEK pulleys per BOM: 1 spool + 2 distribution + 5 MCP redirect + 4 spare
// In palm.scad we instantiate 8 (the in-palm fixed routing pulleys).
palm_pulley_count    = 8;

// Load cell — Phidgets CZL635 cavity (S-type micro load cell)
loadcell_cavity_l    = 38.0;    // mm — body length (estimate; verify CZL635 drawing)
loadcell_cavity_w    = 12.7;    // mm
loadcell_cavity_h    = 12.7;
loadcell_mount_bolt_m= 2.5;

// Wrist interface (mates to forearm wrist coupler)
wrist_iface_od       = 30.0;    // mm — circular flange
wrist_iface_pcd      = 18.0;    // mm — bolt circle (cad-references §1.1)
wrist_iface_bolt_m   = 2.5;
wrist_iface_count    = 3;

// --------------------------------------------------------------------------
// 9. Skin mold (two-part silicone mold for hand skin)
// --------------------------------------------------------------------------
mold_wall_t          = 6.0;     // mm — outer mold shell
mold_pin_dia         = 6.0;     // mm — alignment pins (cad-references §1.3)
mold_pin_count       = 4;       // per side
mold_pour_port_dia   = 12.0;    // mm — wrist pour port
mold_vent_dia        = 2.0;     // mm — fingertip vents
mold_clamp_bolt_m    = 3.0;
mold_clamp_count     = 6;

// --------------------------------------------------------------------------
// 10. Mass / target budget (informational — not used by geometry)
// --------------------------------------------------------------------------
target_mass_total_g     = 350;    // skeleton + skin
target_mass_skel_g      = 250;
target_mass_skin_g      = 100;

// --------------------------------------------------------------------------
// 11. View flags for hand_assembly.scad
// --------------------------------------------------------------------------
VIEW_ASSEMBLED = 0;
VIEW_EXPLODED  = 1;
VIEW_SKELETON  = 2;
VIEW_MOLD      = 3;

// --------------------------------------------------------------------------
// 12. TUNING NOTES — dimensions known to be best-guess
// --------------------------------------------------------------------------
// • Phalanx envelopes (proximal/middle/distal lengths and widths) are anatomical
//   proxies; tune against an actual hand cast or anthropometric reference data.
// • bushing_flange_od and bushing_flange_t are estimated — verify Bunting /
//   McMaster 8458K71 vendor drawing.
// • motor_stack_length is a rough estimate; pull from Maxon EC-i 30 + GP 32 HP
//   combined-stack spec sheet before fabricating motor_bracket.
// • finger_mcp_x array assumes equally spaced fingers; real hands have
//   converging finger bases (~5° per finger). Refine in palm.scad.
// • spring_pocket_dia and spring_pocket_length are clearance estimates;
//   confirm against Lee Spring LTR-040A-04S free-state geometry.
// • loadcell_cavity_l/w/h are placeholders; verify Phidgets CZL635 datasheet.
// • palm_finger_count == 5 but finger_mcp_x has 4 entries (thumb separate).
//   palm.scad iterates fingers and thumb separately.
