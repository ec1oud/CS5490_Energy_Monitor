// This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
// https://creativecommons.org/licenses/by-sa/3.0/

// board dimensions
boardLength = 102;
boardWidth = 64;
// holes in board
boardWidthStandoffSpacing = 53;
boardHeightStandoffSpacing = 91;

board2dims = [34.25, 63.5, 2];

// DIN rail clamp thickness
clampThickness = 8;
// thickness of sled for board
sledThickness = 1.5;
// the top of the row of PowerPoles will be this far above the DIN rail
heightAboveRail = 10;
// how deep the bolt should go into the solid part, past the spring clip
boltHoleDepth = 10;
// diameter where the bolt passes through the spring clip
looseBoltDiameter = 3.2;
// diameter where the bolt should screw into the DIN holder body
tightBoltDiameter = 2.9;
// standoff dims
standoffDiameter = 8;
standoffScrewHoleDiameter = 3;
standoffHeight = 2.5;

$fn = 16;

// DIN rail clamp
// adapted from Thingiverse 101024 by Robert Hunt
// made with 1mm wider opening: my rail is bigger or my printer prints too small
// Dimensions: 19.74 x 41.355 x clampThickness
module din_clamp() {
	$fn = 24;
	translate([-9.72, -13.1, 0]) mirror([1, 0, 0])
	difference() {
		linear_extrude(height=clampThickness, convexity=5) {
			// imported Robert's DXF to Inkscape, adjusted, then exported via https://github.com/martymcguire/inkscape-openscad-poly
			polygon(points=
				[[-9.731, 16], [5.910, 16], [6.675, 15.848], [7.324, 15.415], [7.758, 14.766], [7.910, 14], [7.910, 10.855],
				[7.764, 10.502], [7.410, 10.355], [6.854, 10.355], [6.320, 10.510], [5.951, 10.925], [4.910, 13.105], [3.910, 13.106],
				[3.910, -21.394], [3.832, -21.783], [3.617, -22.101], [3.299, -22.315], [2.910, -22.394], [-5.372, -22.394], [-5.736, -22.550],
				[-5.852, -22.894], [-5.729, -23.238], [-5.372, -23.394], [5.160, -23.394], [5.160, -21.464], [5.302, -21.239], [5.566, -21.269],
				[9.561, -24.465], [9.730, -24.717], [9.721, -25.021], [9.538, -25.263], [9.249, -25.355], [-9.731, -25.355]]
				, paths=
				[[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 0]]
			);
		}
		translate([0, -22.5, clampThickness / 2]) {
			rotate([90, 90, 0]) {
				cylinder(h= boltHoleDepth, r = looseBoltDiameter / 2);
			}
		}
		translate([0, -22.5, clampThickness / 2]) {
			rotate([-90, 90, 0]) {
				cylinder(h= boltHoleDepth, r = tightBoltDiameter / 2);
			}
		}
	}
}
// End of DIN clamp by Robert Hunt

module roundCornersCube(x,y,z,r) {
        minkowski() {
                cube([x - 2 * r, y - 2 * r, z], center=true);
                cylinder(r=r, h=0.1);
        }
}

module pegs(dims) {
        radius = 4;
        translate([dims[0] / 2 - 2, dims[1] / 2 - 2, 3])
                roundCornersCube(8, 8, 6, 2, center=true);
        translate([dims[0] / 2 - 2, dims[1] / -2 + 2, 3])
                roundCornersCube(8, 8, 6, 2, center=true);
        translate([dims[0] / -2 + 2, dims[1] / 2 - 2, 3])
                roundCornersCube(8, 8, 6, 2, center=true);
        translate([dims[0] / -2 + 2, dims[1] / -2 + 2, 3])
                roundCornersCube(8, 8, 6, 2, center=true);
}

module boardCutout(dims, extra) {
        translate(extra / 2 + [0, 0, 4])
                cube(dims + extra, center=true);
        translate(extra / 2 + [0, 0, 5])
                cube(dims + extra - [1, 1, -2], center=true);
        translate(extra / 2 + [0, 0, sledThickness])
                cube(dims + extra - [2, 2, -1], center=true);
}

module zFillet(radius, length) {
	difference() {
		cube([radius, radius, length]);
		cylinder(r=radius, h=length);
	}
}

module yFillet(radius, length) {
	translate([radius, 0, radius])
	rotate([-90, 90, 0])
	zFillet(radius, length);
}

module standoffs4(xspacing, yspacing, dx, dy, diam, height) {
	translate([dx, dy, sledThickness]) {
		cylinder(d=diam, h=height);
		translate([xspacing, 0, 0])
			cylinder(d=diam, h=height);
		translate([xspacing, yspacing, 0])
			cylinder(d=diam, h=height);
		translate([0, yspacing, 0])
			cylinder(d=diam, h=height);
	}
}

module clampWithSled(heightAboveRailTop, height, stickOut) {
	sledBottom = heightAboveRailTop - height;
	difference() {
		union() {
			translate([0, sledBottom, 0]) {
				//~ standoffs4(boardWidthStandoffSpacing, boardHeightStandoffSpacing, 5, 5, standoffDiameter, standoffHeight);
				cube([stickOut, height, sledThickness]);
			}
			translate([30, -30, sledThickness])
				pegs(board2dims);
			din_clamp();
			translate([0, -38.5, sledThickness])
				yFillet(5, 41.355);
			translate([0, heightAboveRailTop - sledThickness, sledThickness]) {
				cube([boardWidth, sledThickness, 10]);
				rotate([0, 0, -90])
					yFillet(5, boardWidth);
			}
		}
		translate([0, sledBottom, -5])
			standoffs4(boardWidthStandoffSpacing, boardHeightStandoffSpacing, 5, 5, standoffScrewHoleDiameter, 10);
		translate([30, -30, sledThickness])
			boardCutout(board2dims, [0.25, 0.25, 0]);
		translate([5, heightAboveRailTop + 5, 5 + sledThickness]) rotate([90, 0, 0]) {
			cylinder(d=standoffScrewHoleDiameter, h=10);
			translate([boardWidthStandoffSpacing, 0, 0])
				cylinder(d=standoffScrewHoleDiameter, h=10);
		}
	}
}

mirror([1, 0, 0])
clampWithSled(heightAboveRail, boardLength, boardWidth);
