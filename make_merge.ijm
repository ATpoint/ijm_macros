/*

    \\ DESCRIPTION:
    ImageJ macro to threshold a set of tif files and then create an overlay, leaving only the overlayed files open.
    Meant to be used for immediate downstream analysis, manually adding polygons to structures in the image that
    cannot straight-forwardly be segmented in any automated fashion.
    
    \\ EXPECTS:
    - one folder per image, with folder name same as image base name, e.g. mouse_1_slide_1_section_1
      as folder name and then channels as mouse_1_slide_1_section_1_ch{00,01,03}.tif
    - *ch00.tif for DAPI
    - *ch01.tif for a-SMA
    - *ch03.tif for CD68
        
    \\ LIMITATIONS:
    - just hit and run, no checking and validation at all...
    
    \\ USAGE:
    --| modify source so thresholds are appropriate for the channels
    --| run macro, then upon prompt select parent directory with per-specimen folders
    
    \\ OUTPUT:
    - tif file with the merged and thresholded channels in the same folder as the input tif files
 
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
		current_output = current_folder + "/" + current_image_base + "_thresholded_overlay.tif";
				
		// Only run main function if results do not exist already -- no automatic overwriting				
		if(!File.exists(current_output)) {
			
			print("[Info] Processing " + current_image_base);
			
			// Open all four channels and apply thresholds
			image_ch00 = current_folder + "/" + current_image_base + "_ch00.tif";
			image_ch01 = current_folder + "/" + current_image_base + "_ch01.tif";
			image_ch03 = current_folder + "/" + current_image_base + "_ch03.tif";
			
			open(image_ch00);
			setThreshold(160, 65535, "raw");
            run("Convert to Mask");
					
			open(image_ch01);
			setThreshold(190, 65535, "raw");
            run("Convert to Mask");
				
			open(image_ch03);
			setThreshold(180, 65535, "raw");
            run("Convert to Mask");

            image_ch00_alone = current_image_base + "_ch00.tif";
			image_ch01_alone = current_image_base + "_ch01.tif";
			image_ch03_alone = current_image_base + "_ch03.tif";
			
            // Overlay -- DAPI/00 is blue, SMA/01 is green, CD68/03 is yellow
            run("Merge Channels...", "c3=" + image_ch00_alone + " c2=" + image_ch01_alone + " c7=" + image_ch03_alone + " create");			
            saveAs("Tiff", current_folder + "/" + current_image_base +  "_overlay_0_1_3.tif");
			
		} else {
			
			print("[Info] Skipping " + current_image_base + " as overlay already exist!");
			
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