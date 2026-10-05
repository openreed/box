include <BOSL2/std.scad>

// OpenReed v2: captive sliding lid + an independent, press-to-release latch.
// Units: mm. Both parts are modeled in their support-free print orientation.

/*[形状参数 | Shape Parameters]*/
// 内部长度 | Usable inner length
inner_length = 132;
// 内部宽度 | Usable inner width
inner_width = 46;
// 内部高度（盖子下方净空间）| Clear height below the lid
inner_height = 52;
wall_thickness = 3.5;
bottom_thickness = 3.5;
top_thickness = 3.5;
inner_corner_radius = 10;
outer_corner_radius = 5;
bottom_chamfer = 2;

/*[连接部参数 | Connection Parameters]*/
// 导轨顶部的横向搭接深度 | Rail overlap, each side
rail_depth = 2;
// 每侧水平间隙，不是两侧总间隙 | Horizontal clearance PER SIDE
slide_clearance = 0.30;
// 盖子上下各自的间隙 | Vertical clearance, above AND below lid
vertical_clearance = 0.30;
// 前后定位间隙 | Rear stop and latch shoulder clearance
end_clearance = 0.30;

/*[锁舌参数 | Release Latch Parameters]*/
// 弹性臂沿 X 方向，弯曲发生在打印层平面内 | Beam bends in the XY plane
latch_length = 28;
latch_root_thickness = 2.0;
latch_tip_thickness = 1.6;
// 锁钩突出量；锁止面垂直于滑动方向 | Positive hook projection
latch_hook_depth = 1.2;
// 插入斜面的长度，只影响合盖 | Closing ramp length
latch_ramp_length = 2.4;
latch_land_length = 1.2;
// 弹性臂与盖子之间的槽宽，同时限制过量按压 | Release slot / travel stop
latch_slot_gap = 1.8;
// 锁钩距离开口端的距离 | Catch inset from front
latch_front_inset = 5;
// 拇指按压窗口长度 | Recessed thumb access window
latch_access_length = 12;

/*[OpenReed Logo 参数 | OpenReed Logo Parameters]*/
logo_ratio = 0.5;
logo_depth = 0.01;

/*[显示与导出 | Display and Export]*/
part = "print"; // [print,body,lid,assembled,exploded,section,fit_test,fit_test_body,fit_test_lid]
// 装配视图中的滑开距离 | Opening distance for assembly preview
lid_slide = 0;
print_gap = 10;
preview_quality = 96; // [32,64,96]

/*[内部参数 | Internal Parameters]*/
outer_length = inner_length + 2*wall_thickness;
outer_width = inner_width + 2*wall_thickness;
rim_z = bottom_thickness + inner_height;
rail_height = top_thickness + 2*vertical_clearance;
outer_height = rim_z + rail_height;
rail_slope = rail_depth / rail_height;
channel_half_bottom = inner_width / 2;
channel_half_top = channel_half_bottom - rail_depth;
lid_half_bottom = channel_half_bottom - rail_slope*vertical_clearance - slide_clearance;
lid_half_top = lid_half_bottom - rail_slope*top_thickness;
lid_x0 = -inner_length/2 + end_clearance;
lid_x1 = outer_length/2 - 0.4;
latch_x = outer_length/2 - latch_front_inset;
latch_root_x = latch_x - latch_length;
latch_lead_x = latch_x - latch_ramp_length - latch_land_length;
release_travel = latch_hook_depth - slide_clearance + 0.4;
coupon_x0 = latch_root_x - 5;
coupon_stop_thickness = 1.5;
coupon_floor_z = rim_z - 4;
eps = 0.01;
// Library/test use: -D render_model=false suppresses only top-level placement.
render_model = true;
$fn = preview_quality;

assert(inner_length > latch_length + latch_front_inset + 18,
    "Inner length too short for the release latch.");
assert(inner_width > 2*(rail_depth + slide_clearance + latch_root_thickness + latch_slot_gap + 4),
    "Inner width too small for rails and latch.");
assert(inner_height >= 6 && wall_thickness >= 2 && bottom_thickness >= 1.2 && top_thickness >= 2,
    "Insufficient wall, floor, lid thickness or clear height.");
assert(rail_depth > slide_clearance && rail_slope <= 1,
    "Rail must retain the lid and its overhang must be 45 degrees or steeper.");
assert(slide_clearance > 0 && vertical_clearance > 0 && end_clearance > 0,
    "All mating clearances must be positive.");
assert(latch_hook_depth > slide_clearance + 0.4 && latch_slot_gap > release_travel,
    "Hook engagement or release travel is insufficient.");
assert(latch_root_thickness >= latch_tip_thickness && latch_tip_thickness >= 1.2,
    "Latch must taper from a thicker root to a tip of at least 1.2 mm.");
assert(latch_ramp_length >= latch_hook_depth && latch_land_length > 0,
    "Closing ramp is too steep or has no land.");
assert(latch_front_inset > outer_corner_radius - 1 && latch_x + end_clearance < lid_x1,
    "Latch must remain behind the front corner and inside the lid.");
assert(latch_access_length >= latch_ramp_length+latch_land_length && latch_access_length < latch_length-3,
    "Thumb window must expose the hook while leaving the spring root guarded.");
assert(inner_corner_radius >= outer_corner_radius && inner_corner_radius < inner_width/2,
    "Inner corner radius must preserve the side walls.");
assert(bottom_chamfer >= 0 && bottom_chamfer < min(wall_thickness, bottom_thickness, outer_corner_radius),
    "Bottom chamfer removes too much material.");
assert(logo_depth >= 0 && logo_depth < top_thickness-1.2 && logo_ratio >= 0 && logo_ratio <= 0.8,
    "Logo must leave at least 1.2 mm of lid material.");
assert(lid_slide >= 0, "Slide direction is +X.");
assert(in_list(part, ["print","body","lid","assembled","exploded","section",
                     "fit_test","fit_test_body","fit_test_lid"]), "Unknown part selector.");

// Cross-section coordinates are [Y,Z]; the prism runs along X.
module x_prism(x0, x1, profile) {
    translate([x0,0,0]) rotate([90,0,90])
        linear_extrude(height=x1-x0) polygon(profile);
}

module openreed_logo(height, thickness) {
    linear_extrude(height=thickness)
        trapezoid(h=height, w1=height*2.4/6.2, w2=height*4.0/6.2);
}

// Matched 45-degree bottom chamfer; offset also reduces the corner radius.
module outer_shell() {
    if (bottom_chamfer > 0) {
        hull() {
            linear_extrude(height=eps)
                rect([outer_length-2*bottom_chamfer, outer_width-2*bottom_chamfer],
                     rounding=outer_corner_radius-bottom_chamfer);
            translate([0,0,bottom_chamfer]) linear_extrude(height=eps)
                rect([outer_length,outer_width], rounding=outer_corner_radius);
        }
        translate([0,0,bottom_chamfer])
            linear_extrude(height=outer_height-bottom_chamfer)
                rect([outer_length,outer_width], rounding=outer_corner_radius);
    } else {
        linear_extrude(height=outer_height)
            rect([outer_length,outer_width], rounding=outer_corner_radius);
    }
}

module slide_channel() {
    x_prism(-inner_length/2, outer_length/2+eps, [
        [-channel_half_bottom,rim_z], [channel_half_bottom,rim_z],
        [channel_half_top,outer_height], [channel_half_top,outer_height+eps],
        [-channel_half_top,outer_height+eps], [-channel_half_top,outer_height]
    ]);
}

module box_body() {
    difference() {
        outer_shell();
        translate([0,0,bottom_thickness])
            cuboid([inner_length,inner_width,inner_height+eps],
                   rounding=inner_corner_radius, edges="Z", anchor=BOTTOM);
        slide_channel();
        // Top-open catch pocket: no bridge or hidden support. Its +X wall
        // meets the hook's square shoulder, preventing lid withdrawal.
        translate([latch_x-latch_access_length, channel_half_top-0.5, rim_z-eps])
            cube([latch_access_length+end_clearance,
                  outer_width, rail_height+2*eps]);
        // Finger access under the front lip; retains the entire lower wall.
        translate([inner_length/2-eps,-9,rim_z-3])
            cube([wall_thickness+2*eps,18,rail_height+3+eps]);
    }
}

// Shear each layer to follow the rail profile, keeping a constant-thickness
// horizontal spring at every Z. All spring layers are printed flat.
module rail_aligned_extrude(height=top_thickness) {
    multmatrix([[1,0,0,0],[0,1,-rail_slope,0],[0,0,1,0],[0,0,0,1]])
        linear_extrude(height=height) children();
}

module release_slot() {
    // Rounded root, radius = slot_gap/2; no sharp-ended stress notch.
    r = latch_slot_gap/2;
    translate([0,0,-eps])
        rail_aligned_extrude(top_thickness+2*eps)
            hull() {
                translate([latch_root_x+r,
                           lid_half_bottom-latch_root_thickness-r]) circle(r=r);
                translate([lid_x1+r+eps,
                           lid_half_bottom-latch_tip_thickness-r]) circle(r=r);
            }
}

module latch_hook() {
    // The leading ramp permits closing; the rear face is perpendicular to X.
    rail_aligned_extrude()
        polygon([
            [latch_lead_x,lid_half_bottom-eps],
            [latch_x-latch_land_length,lid_half_bottom+latch_hook_depth],
            [latch_x,lid_half_bottom+latch_hook_depth],
            [latch_x,lid_half_bottom-eps]
        ]);
}

module box_lid() {
    difference() {
        union() {
            x_prism(lid_x0,lid_x1,[
                [-lid_half_bottom,0], [lid_half_bottom,0],
                [lid_half_top,top_thickness], [-lid_half_top,top_thickness]
            ]);
            latch_hook();
        }
        release_slot();
        if (logo_depth > 0)
            translate([0,0,top_thickness-logo_depth])
                openreed_logo(logo_ratio*inner_width,logo_depth+eps);
        // Three shallow grip grooves at the front, away from the spring.
        for (x=[lid_x1-6,lid_x1-4,lid_x1-2])
            translate([x,-7,top_thickness-0.4]) cube([0.7,14,0.4+eps]);
    }
}

// Small actual-geometry coupon, not a scaled imitation of the latch/rails.
// Added rear stop matches the cut lid length, so it clicks at full closure.
module fit_test_body() {
    translate([-coupon_x0,0,-coupon_floor_z])
        union() {
            intersection() {
                box_body();
                translate([coupon_x0,-outer_width/2-eps,coupon_floor_z])
                    cube([outer_length,outer_width+2*eps,outer_height-coupon_floor_z+eps]);
            }
            translate([coupon_x0,-outer_width/2,coupon_floor_z])
                cube([coupon_stop_thickness,outer_width,outer_height-coupon_floor_z]);
        }
}

module fit_test_lid() {
    translate([-coupon_x0,0,0])
        intersection() {
            box_lid();
            translate([coupon_x0+coupon_stop_thickness+end_clearance,-outer_width/2,0])
                cube([outer_length,outer_width,top_thickness+eps]);
        }
}

module assembly(opening=0, lift=0) {
    color("Gainsboro") box_body();
    translate([opening,0,rim_z+vertical_clearance+lift])
        color("DarkSlateGray") box_lid();
}

if (render_model)
if (part == "body") box_body();
else if (part == "lid") box_lid();
else if (part == "assembled") assembly(lid_slide);
else if (part == "exploded") assembly(lid_slide,18);
else if (part == "section")
    intersection() {
        assembly(lid_slide);
        translate([-outer_length,0,-eps]) cube([3*outer_length,outer_width,2*outer_height]);
    }
else if (part == "fit_test_body") fit_test_body();
else if (part == "fit_test_lid") fit_test_lid();
else if (part == "fit_test") {
    translate([0,-outer_width/2-print_gap/2,0]) fit_test_body();
    translate([0,outer_width/2+print_gap/2,0]) fit_test_lid();
} else {
    translate([0,-outer_width/2-print_gap/2,0]) box_body();
    translate([0,outer_width/2+print_gap/2,0]) box_lid();
}
