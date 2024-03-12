# ijm_macros
Random collection of ImageJ macros for personal use

- `colour_deconv_masson.ijm`  
Automated colour deconvolution of all ".tif" files in a user-defined directory, using the Masson's Trichrome preset.
It will only keep the "blue" channel representing collagen, and save it as `{filename%.tif}_blue.tif`, and to avoid conflicts
with existing `*_blue.tif` files it will ignore tif files with this suffix. Will also exit when no tif files can be
found in the user-defined directory. Progress is printed to the Log window.
