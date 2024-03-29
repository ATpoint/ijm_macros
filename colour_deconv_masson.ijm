/* 

   Perform colour deconvolution on Masson's Trichrome tif files based on the Masson Trichrome preset.
   - selects all ".tif" files in user-defined directory (upon prompt) that do not end with "_blue.tif"
   - will save the blue channel as {filename%.tif}_blue.tif to the same location as the original tif file
   - will overwrite existing "_blue.tif" files

  Author: Alexander Bender
  Last modified: 12.03.2024

*/

dir = getDirectory("Select directory with Masson's Trichrome .tif files for collagen deconvolution!")

list = getFileList(dir);
filtered_list = newArray(0);

for (i = 0; i < list.length; i++) {

    if (endsWith(list[i], ".tif") & !endsWith(list[i], "_blue.tif")) {

        filtered_list = Array.concat(filtered_list, list[i]);
    }
    
}

len_filtered_list = filtered_list.length;

if( len_filtered_list == 0) {

	print("No tif files found in the directory -- exiting!");
	exit();

} else {
	
	print("#-------------------------------------------------------------");
	print("[Info] Found " + len_filtered_list + " tif files in " + dir);
	print("[Info] Start deconvolution");
	print("");
	
}

// Close everything before the actual operation starts
close("*");

for (i = 0; i < len_filtered_list; i++) {
	
	tif_in = filtered_list[i];
	tif_out = replace(tif_in, "\\.tif", "") + "_blue.tif";
	print("[Processing] " + tif_in);
	
	open(dir + "/" + tif_in);
	run("Colour Deconvolution", "vectors=[User values] [r1]=0.83121943 [g1]=0.54205793 [b1]=0.12348068 [r2]=0.22908764 [g2]=0.9523519 [b2]=0.20135695 [r3]=0.43692058 [g3]=0.44746158 [b3]=0.7803067");
	selectImage(tif_in + "-(Colour_1)");
	saveAs("Tiff", dir + "/" + tif_out);
	close("*");
	
}

print("");
print("[Info] Done");
print("#-------------------------------------------------------------");
	
