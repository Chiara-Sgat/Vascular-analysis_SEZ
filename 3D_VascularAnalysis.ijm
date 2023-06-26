/* Macro for the vascular analysis (Ly6c channel) in the SEZ

Author: Chiara Sgattoni 2023
Contact: chiara.sgattoni@uv.es */

setOption("BlackBackground", false);
run("Set Measurements...", "area mean integrated display redirect=None decimal=2");
path = getDirectory("Choose a folder with images");
list = getFileList(path);
//Create a table with all the results
Table.create("Vascular analysis");
//Open .oif images
for (i = 0; i < list.length; i++) {
	if (endsWith(list[i], ".oif")) {
		run("Bio-Formats Importer", "open=[" + path + File.separator+ list[i]+"] autoscale color_mode=Grayscale rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
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
		Table.set("Image", i, title);
		Table.set("Total vascular volume", i, totalA);
					
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
		selectWindow("Vascular analysis");
		Table.set("Total length", i, totalV);
		Table.set("Volume zona", i, totalAlv);
		Table.update;
		close("*");
		}
	}	
}			
//Save the table
selectWindow("Vascular analysis");
saveAs("results", path + File.separator+ "Vascular analysis.csv");
