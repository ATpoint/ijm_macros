/*

	\\ DESCRIPTION:
    ImageJ macro for the analysis of IHC images towards macrophage (CD68), neutrophil (Ly6G) and SMC (a-SMA) numbers
    in atherosclerotic plaques. 
    First performs nucleus segmentation with StarDist based on a DAPI channel,
    then counts the number above cells and measures intima and cap area.
    
    \\ EXPECTS:
    - one folder per image, with folder name same as image base name, e.g. mouse_1_slide_1_section_1
      as folder name and then channels as mouse_1_slide_1_section_1_ch{00,01,02,03}.tif
    - *ch00.tif for DAPI
    - *ch01.tif for a-SMA
    - *ch02.tif for Ly6G
    - *ch03.tif for CD68
    - RoiSet.zip that contains at least "intima" and optionally "fc" as ROIs (need to be done manually before)
    - Thresholding information (tba...)
    
    \\ LIMITATIONS:
    - will not check that folder name and image base names are the same, will probably silently break or do nothing if not matching
    - will not explicitely do pre-flight checks or validation that "EXPECTS" content is present, so do that externally!
    - will not overwrite results and skip the sample if already present so manual cleanup in case of rerunning is necessary
    
    \\ USAGE:
    --| Modify the code and enter appropriate thresholds for the four channels in the "setThreshold()" lines
    --| Run the macro, will prompt the user for a parent directory and then loop through all folders "mouse_*".
    --| That's it.
    
    \\ OUTPUT:
	=> Output per folder:
	- results_mac_neu_smc.csv with the measurements
	- rois_mac_neu_smc.csv with the ROIs
	
	=> Output in the oarent directory:
	- timestamped *_log.txt with info about which samples were processed or skipped (the latter in case results already exist)
	
	\\ ABOUT:
    Author: Alexander Bender
    Last modified: 19.03.2024

*/

getDateAndTime(year, month, week, day, hour, min, sec, msec);
run("Fresh Start");
run("Input/Output...", "jpeg=85 gif=-1 file=.csv use_file save_column");

// Prompt user for parent directory
dir = getDirectory("Select directory containing folders with IHC images!")

// Get all folders within the user-defined directory matching the "mouse_*" prefix
list = getFileList(dir);
list_len = list.length;
filtered_list = newArray(0);

for (i = 0; i < list_len; i++) {

	if (startsWith(list[i], "mouse_") & File.isDirectory(dir + "/" + list[i])) {

        filtered_list = Array.concat(filtered_list, list[i]);        
        
    }
    
}

filtered_list_len = filtered_list.length;

// Iterate through folders, but only perform action if output file does not exist already
if(filtered_list_len > 0) {
	
	print("#-------------------------------------------------------------");
	print("");
	print("[Info] Found " + filtered_list_len + " folders to process in "+ dir);
	print("");
	
	for (i = 0; i < filtered_list_len; i++) {
		
		// Make sure things are clean before a new iteration starts
		//roiManager("Delete");
		Table.deleteRows(0, nResults);
		
		// Folder and names
		current_folder = dir + "/" + filtered_list[i];
		current_image_base  = replace(filtered_list[i], "/", "");
		current_output_roi = current_folder + "/" + "rois_mac_neu_smc.zip";
		current_output_results = current_folder + "/" + "results_mac_neu_smc.csv";
				
		// Only run main function if results do not exist already -- no automatic overwriting				
		if(!File.exists(current_output_results)) {
			
			print("[Info] Processing " + current_image_base);
			
			// Open all four channels and apply thresholds
			image_ch00 = current_folder + "/" + current_image_base + "_ch00.tif";
			image_ch01 = current_folder + "/" + current_image_base + "_ch01.tif";
			image_ch02 = current_folder + "/" + current_image_base + "_ch02.tif";
			image_ch03 = current_folder + "/" + current_image_base + "_ch03.tif";
			
			image_ch00_alone = current_image_base + "_ch00.tif";
			image_ch01_alone = current_image_base + "_ch01.tif";
			image_ch02_alone = current_image_base + "_ch02.tif";
			image_ch03_alone = current_image_base + "_ch03.tif";
			
			open(image_ch00);
			setThreshold(150, 65535, "raw");
					
			open(image_ch01);
			setThreshold(150, 65535, "raw");
			
			open(image_ch02);
			setThreshold(150, 65535, "raw");
			
			open(image_ch03);
			setThreshold(150, 65535, "raw");
			
			// Set measurements reproducibly, then open ch00, segmentate cells and rename ROIs to cell_n
			run("Set Measurements...", "area display redirect=None decimal=3");
			
			selectImage(image_ch00_alone);
			run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':" + image_ch00_alone + ", 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.5', 'nmsThresh':'0.4', 'outputType':'ROI Manager', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
			
			n_cells = RoiManager.size;
			for(k = 0; k < n_cells; k++) {
				
				roiManager("Select", k);
				roiManager("Rename", "cell_" + k);
				
			}
				
			// Load existing ROIs containing intima (and optionally more...)
			roiManager("Open", current_folder + "/RoiSet.zip");
			
			// Define array_roi as all content of the ROI manager, then run "measure" on everything
			n_roi = RoiManager.size;
			array_roi = newArray(n_roi);
			
			for (i = 0; i < n_roi; i++) {
				
				array_roi[i] = i;
			      
			}
			 
			// Measure area (not limited to threshold) for every ROI using ch00
			selectImage(image_ch00_alone);
			roiManager("select", array_roi);
			roiManager("Measure");
			
			// Measure area (now limited to threshold) for every ROI using ch01-03
			run("Set Measurements...", "area limit display redirect=None decimal=3");
			
			selectImage(image_ch01_alone);
			roiManager("select", array_roi);
			roiManager("Measure");
			
			selectImage(image_ch02_alone);
			roiManager("select", array_roi);
			roiManager("Measure");
			
			selectImage(image_ch03_alone);
			roiManager("select", array_roi);
			roiManager("Measure");
			
			// Save ROI and results
			roiManager("Save", current_output_roi);
			saveAs("Results", current_output_results);
						
			close("*");
			
		} else {
			
			print("[Info] Skipping " + current_image_base + " as results already exist!");
			
		}
		
	}
	
	
} else {
	
	print("No folders found matching the criteria!");
	exit();
	
}

print("");
print("[Info] Done processing!");
print("");
print("#-------------------------------------------------------------");

selectWindow("Log");
save(dir + "/" + year + "_" + month + "_" + day + "_" + hour + "h_" + min + "min_" + sec + "sec_log.txt");