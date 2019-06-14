**adjust SETSM dem products to a set of XYZ control points**
Trevor Host 06/14/2019

reqs:  
(1) must be connected to the Y:  
(2) the first argument must be a 2m SETSM laz  
(3) the second argument must be csv control points  

how to use:  
open a command terminal  
Run the following command  
Z:\adjusted_dsms\process\THP.bat <file.laz> <control_points.csv>

file.laz - the full path of a 2m SETSM dem in LAZ format 
*Z:\adjusted_dsms\process\test\W1W2_20100617_102001000E228200_10300100054B2E00_seg1_2m_dem_1.laz*
	
control_points - the full path of a list of XYZ control points. Try one from these options depending on region
*Z:\adjusted_dsms\reference_points\NGS\NGS_UTM15N_xyz.csv*
*Z:\adjusted_dsms\reference_points\NGS\NGS_UTM16N_xyz.csv*
*Z:\adjusted_dsms\reference_points\NGS\NGS_UTM17N_xyz.csv*
*Z:\adjusted_dsms\reference_points\NGS\NGS_UTM18N_xyz.csv*
*Z:\adjusted_dsms\reference_points\Canada\LongPoint_ref_points_xyz.csv*
*Z:\adjusted_dsms\reference_points\Canada\LakeStClaire_ref_points_xyz.csv*

example:  
Z:\adjusted_dsms\process\THP.bat Z:\adjusted_dsms\process\test\W1W2_20100617_102001000E228200_10300100054B2E00_seg1_2m_dem_1.laz Z:\adjusted_dsms\reference_points\NGS\NGS_UTM15N_xyz.csv

This will create a temp folder with the same name as the laz file and output the ground points and adjusted files in the same location as the input file. The temp folder will be automatically be removed after completion.

products:  
file_g_adj.tif -	vertically adjusted dem in tif format + tfw world file  
file_g_adj.laz - 	vertically adjusted dem in laz format  
file_g.laz - 	laz rough ground points used in alignment (not useful for bare-earth dem)  
file_ground.tif - 	count of ground points tif used in alignment (not useful for bare-earth dem) + tfw world file  
file_accuracy.txt - vertical accuracy report: average absolute, RMS, standard deviation, average of elevation errors  
file_offset.txt - vertical offset report: value calculated for vertical offset  

