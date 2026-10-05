// Geometry checks; execute with -D render_model=false.
// Empty intersections mean no collision; locked_x / locked_z must be non-empty.
include <../box.scad>
check = "closed";
offset = 0;

module positioned_lid(x=0, z=0) {
    translate([x,0,rim_z+vertical_clearance+z]) box_lid();
}

// Collision envelope after release: remove the deforming arm and hook from the
// unchanged panel, and translate that arm inward by the required release travel.
// This is a conservative motion-envelope check, not an FEA spring simulation.
module released_lid(x=0) {
    translate([x,0,rim_z+vertical_clearance]) {
        difference() {
            box_lid();
            translate([latch_root_x-eps,
                       lid_half_top-latch_root_thickness-latch_slot_gap,-eps])
                cube([outer_length,outer_width,top_thickness+2*eps]);
        }
        translate([0,-release_travel,0]) intersection() {
            box_lid();
            translate([latch_root_x-eps,
                       lid_half_top-latch_root_thickness-latch_slot_gap,-eps])
                cube([outer_length,outer_width,top_thickness+2*eps]);
        }
    }
}

if (check == "closed") intersection() { box_body(); positioned_lid(); }
else if (check == "released") intersection() { box_body(); released_lid(offset); }
else if (check == "locked_x") intersection() { box_body(); positioned_lid(end_clearance+0.3); }
else if (check == "locked_z") intersection() { box_body(); positioned_lid(0,1.2); }
else if (check == "rear_stop") intersection() { box_body(); positioned_lid(-end_clearance-0.3); }
else if (check == "coupon") intersection() {
    fit_test_body();
    translate([0,0,4+vertical_clearance]) fit_test_lid();
}
else if (check == "coupon_stop") intersection() {
    fit_test_body();
    translate([-end_clearance-0.3,0,4+vertical_clearance]) fit_test_lid();
}
else if (check == "coupon_lock") intersection() {
    fit_test_body();
    translate([end_clearance+0.3,0,4+vertical_clearance]) fit_test_lid();
}
