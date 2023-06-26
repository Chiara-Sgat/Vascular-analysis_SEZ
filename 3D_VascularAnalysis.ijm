/* Macro for the vascular analysis (Ly6c channel) in the SEZ

Author: Chiara Sgattoni 2023
Contact: chiara.sgattoni@uv.es */

run("Close All");
setOption("BlackBackground", false);
run("Set Measurements...", "area mean integrated display redirect=None decimal=2");
path = getDirectory("Choose a folder with images");
list = getFileList(path);
//Create a table with all the results
Table.create("Vascular analysis");
//Open tif images
for (i = 0; i < list.length; i++) {
	if (endsWith(list[i], ".tif")) {
		open(path + File.separator+ list[i]);
		title = getTitle();
		run("Split Channels");
		selectWindow("C1-"+ title);
		run("Close");
		selectWindow("C2-"+ title);
		rename("AreaLV");
		selectWindow("C3-"+ title);
		rename("Ly6c");
		selectWindow("C4-"+ title);
		run("Close");
		//Pre-processing of Ly6c channel
		selectWindow("Ly6c");
		run("Duplicate...", "title=Redirected duplicate");
		titleb = getTitle();
		selectWindow(titleb);
		run("Enhance Contrast...", "saturated=0.3 normalize process_all");
		run("Gaussian Blur 3D...", "x=2 y=2 z=2");
		run("Subtract Background...", "rolling=50 stack");
		//Binarization
		setAutoThreshold("Li dark");
		run("Convert to Mask", "method=Li background=Dark");
		run("Fill Holes", "stack");
		run("Set Measurements...", "area mean integrated redirect=None decimal=2");
		run("Analyze Particles...", "size=10-Infinity display clear show=Masks stack");
		rename("TH_" + title);
							
		// Add summarized results in the table (Area & Mean grey value)
		selectWindow("Results");
		A = Table.getColumn("Area"); 
		M = Table.getColumn("Mean");
			
		totalA = 0;
		for (a = 0;a < A.length; a++){
			totalA=totalA + A[a];
		}
					
		totalM = 0;
		for (m = 0; m < M.length; m++) {
			totalM = totalM + M[m];
		}
		MeanAv = (totalM / M.length);
		selectWindow("Vascular analysis");
		Table.set("Image name", i, title);
		Table.set("Total vascular volume(um3)", i, totalA);
					
		//Measure area SEZ considered
		run("Clear Results");
		selectWindow("AreaLV");
		run("Gaussian Blur...", "sigma=8");
		run("Median...", "radius=5 stack");
		waitForUser("Manually threshold di image");
		run("Fill Holes", "stack");
		run("Analyze Particles...", "size=1000-Infinity show=Nothing display clear stack");
		selectWindow("Results");
		
		//Calculate overall area
		Alv = Table.getColumn("Area"); 
		totalAlv = 0;
		for (b = 0;b < Alv.length; b++){
			totalAlv=totalAlv + Alv[b];
		}
		//Calculate density using known Area
		density = (totalA/totalAlv);		
		selectWindow("Vascular analysis");
		Table.set("Vascular density", i, density);	
		selectWindow("Results");
		run("Close");
		//Measure skeleton (Length)
		selectWindow("TH_"+ title);
		run("Skeletonize (2D/3D)");
		run("Analyze Skeleton (2D/3D)", "prune=[shortest branch] calculate show display");
		selectWindow("Branch information");
		V = Table.getColumn("Branch length");
		totalV = 0;
		for (v = 0;v < V.length; v++){
			if (v > 3) {
			totalV=totalV + V[v];
			}
		}
		selectWindow("Vascular analysis");
		Table.set("Total vascular length(um)", i, totalV);
		Table.set("Volume SEZ(um3)", i, totalAlv);
		Table.update;
		//Diameter analysis
		selectWindow("Ly6c");
		run("Set Measurements...", "area mean standard centroid redirect=None decimal=3");
		run("Z Project...", "projection=[Max Intensity]");
		run("Median...", "radius=5");
		setAutoThreshold("Triangle dark");
		waitForUser("Check that the threshold is fine");
		run("Convert to Mask");
		run("Fill Holes");
		run("Analyze Particles...", "size=5-Infinity add");
		rename("mask_1");
		roiManager("Show None");
		run("Duplicate...", "title=mask_2");
		run("Skeletonize (2D/3D)");
		rename("skel");
		run("Geodesic Distance Map", "marker=skel mask=mask_1 distances=[Chessknight (5,7,11)] output=[32 bits] normalize");
		roiManager("Show All");
		roiManager("multi-measure measure_all append");
		selectWindow("Results");
		D = Table.getColumn("StdDev");
		totalD = 0;
		for (d = 0;d < D.length; d++){
			totalD=totalD + D[d];
			}
		MeanDv = (totalD / D.length);
		selectWindow("Vascular analysis");
		Table.set("Mean diameter(um)", i, MeanDv); 
		Table.update;
		roiManager("reset");
		close("*");
	}
}		
//Save the table
selectWindow("Vascular analysis");
saveAs("results", path + File.separator+ "Vascular analysis.csv");
