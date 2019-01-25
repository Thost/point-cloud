# Lidar Processing
###### Adapted from [October 13, 2013](https://rapidlasso.com/2013/10/13/tutorial-lidar-preparation/) by [martin isenburg]()
```
Tools: LASground_new, LASnoise, LASheight, LASclassify, LAS2dem, LASgrid, LASview, LASboundary
```


This is a continuation of the tutorial on lidar quality checking and preparation. We will use the spatially-coherent tiled LAZ dataset for further processing such as point cloud classification using ASPRS standards and normalization. Then we will create derived products such as building footprint feature extraction, normalized digital surface models, and tree crown modelling using multi-core batch processing. Before we begin, check that you have the tiled LAZ dataset in the ‘C:\lastools\bin\tiles’ folder.

Open and a command prompt and run the following command:
```
cd C:\lastools\bin
```
###LASground_new
Now that the point cloud has been tiled appropriately, we can begin to assign classes to the points. We start with identifying ground points with the “lasground_new” tool. This tool fits a horizontal plane to the points starting with a coarse estimate of the low points and finds ground points based on how well they fit to the initial ground plane and neighboring points. The step command is very important here as it determines the size of the coarse ground estimate. The gui version of the tool has options such as -wilderness (3m), -nature (5m), -town (10m), -city (25m), and -metro (50m) for the size of the initial ground estimate. In this urban scene, we will use a step size of 100 to avoid classifying building rooftops as ‘ground’ and the ‘ultra fine’ option for the initial ground estimate. There are detailed descriptions for the many options available for this command in the README.txt file. The ‘-compute_height’ flag will calculate the vertical height difference from each point to the ground surface and store this value in the ‘user_data’ field. This is a necessary before running the lasclassify tool. Make sure to use the multi-core functionality here as this command is processing-intensive. If the point cloud contains more than 20 million points, LASground will fail to allocate enough memory. To fix this issue, either reduce your tile size or subset the point cloud by thinning. 

```
Lasground_new -i tiles\*.laz -step 100 -ultra_fine -compute_height -olaz -odix _g -cores 7
```

Check to see how well the ground classification worked by viewing one tile and coloring by classification. Look for tops of buildings that are erroneously classified as ground, these errors are common and can negatively impact further surface modeling. Use the ‘g’ hotkey to display only ground points and use ‘t’ to create a TIN from the ground points. Press ‘-’ hide the points. Press ‘h’ to apply shading to the TIN. ‘=’ will make the points larger. All of these options can be found by right-clicking as well.

Run lasview on one of the tiles.

![allpoints](/images/allpoints.png)
        All points
	![groundpoints](/images/groundpoints.png)
	Ground points 
	![Classification](/images/classification.png)
	Classification

###LASnoise
You might notice that there are points below the ground or very high in the air. These can come from a variety of sources ranging from sensor miscalibration, reflectance off bright-surface features, even birds that get in the way! Usually these points are removed or classified as noise. The most egregious noise in the point cloud can be filtered out by using height thresholds but sometime that is aggressive. This tools works by counting the number of neighboring points in a specified 3D window. If the threshold number of neighboring points is not met, the point will be assigned to the noise class. These points will be assigned the class 7 which is designated for ‘noise’ points but they will not be removed from the point cloud. Any points less than -2 meters or greater than 60 meters from the ground surface will be classified as noise. The height threshold may need to be changed depending on the height of features in the landscape. 
```
Lasnoise -i tiles\*g.laz -step_xy 4 -step_z 2 -isolated 5 -olaz -odix _n -cores 7
```
How would you figure out how many points were classified as noise?



### LASclassify
Now to classify returns from surface features, we employ the LASclassify tool. LASclassify is an automated point cloud classification tool that uses planar-fitting and height to assign class 5 and 6 to points (high vegetation and buildings, respectively). This command uses two key parameters to distinguish between buildings and tall vegetation. The ‘planar’ parameter sets tolerance for neighboring points that are in a linear plane (building rooftops). The ‘rugged’ parameter is the tolerance for deviation from the linear plane and assigns these points to class 5 ‘vegetation’. The defaults for these parameters are shown in the graphic below. By raising the ‘-planar’ value, more points will be assigned class 6. By lowering the ‘-rugged’ threshold, more points will be assigned class 5. Any points that don’t meet the planar, rugged, or ground offset threshold remain unclassified (1). The step parameter we have seen before but here it sets the window size for computing planarity or ruggedness. The default step is 2 meters. Increasing the step size will reduce false positives but might miss smaller buildings. As with all tools, there is a detailed [README.txt](http://lastools.org/download/lasclassify_README.txt) file for more parameter information. 


![ClassGraphic](/images/classGraphic.png)
Run lasclassify with the default parameters. 
```
Lasclassify -i tiles\*n.laz -ignore_class 7 -step 2 -planar 0.1 -rugged 0.4 -ground_offset 2 -olaz -odix _c -cores 7
```
Then use lasview to see the classification results
![Class](/images/class.png)
![ClassB](/images/classB.png)
Ground + Buildings 
![ClassT](/images/classT.png)
Ground + Vegetation

We can visually check individual tiles for errors but it is hard to inspect the whole dataset this way. Let’s create a raster image using the classification flag to inspect the classification results over the whole area.
```
Lasgrid -i tiles\*c.laz -classification -merged -drop_withheld -odir products -otif -o classification.tif -utm 15N -nad83
```
Open the raster file in ArcMap and chance the Symbology to “unique values” and set the color scheme to display the results.
![ArcMapSymb](/images/ArcMapSymb.png)


### Building footprints
Once the buildings and trees have been classified, we can extract building footprints. We will call again on the LASboundary tool that was used to create the tile index. LASboundary creates a concave hull around the boundary of points. This time, we will filter only the points classified as building (6). We will also add the flag ‘-disjoint’ to separate the polygons. The ‘-concavity’ parameter of 2.5 meters sets the size of the smallest distance between two features. This value needs to be 2 to 3 times the average point spacing. If it is set too small, the boundary will cut into the building and create irregular edges. If it is set too large, adjacent buildings will be merged. Try different values with the concavity parameter to see how it changes the results.
```
Lasboundary -i tiles\*c.laz -disjoint -concavity 2.5 -keep_classification 6 -overview -oshp -o products\buildings.shp
```
![BuildFP](/images/BuildFPb.png)
Building footprints shapefile	
![BuildFP_class](/images/BuildFP_class.png)
Overlay on classification


### Height Normalize
Creating an elevation raster is one of the most common uses of aerial lidar. There are many terms that are used to describe different representations of 3D terrain. You will see DSM, DTM, DEM, CHM, DBM, nDSM and more. Sometimes these terms have different meanings so the best way to distinguish between them is rigorous documentation in how the model is created and the intended application. 
![vertical](/images/vertical.png)

The most basic method to generate a Digital Surface Model (DSM) raster from the point cloud is to use the highest elevation value from all points that fall in each grid cell. However, this only works at resolutions that are much coarser than the point spacing. To produce higher resolution surface models, we will need to interpolate between points. The interpolation method employed in LAStools is 2D Delaunay triangulation which produces a Triangular Irregular Network (TIN) that is then rasterized using a user-defined resolution. A normalized DSM (nDSM) is created in a similar way but the elevations are height normalized to the ground surface (DEM). This normalization is often completed using the raster products where DSM - DEM = nDSM. The ‘normalized DSM’ then represents height rather than elevation. However, we can also normalize the point cloud directly. This can be useful for detailed forestry analysis where the height and structure above ground level is more relevant than elevation. 

The following command will normalize our classified LAZ dataset to the ground. It will make use of the points that were assigned class 2 using the LASground command from before.
```
lasheight -i tiles\*c.laz -replace_z -odix _z -cores 7 -olaz
```

![HeightNorm](/images/heightNorm.png)
Height normalized point cloud 

### Spike-free DSM
Next, we will create a surface model from the normalized LAZ using the spike-free method in las2dem. Instead of using only the first returns to create the DSM, this method uses all relevant returns. In many tutorials, the first returns are assumed to represent the highest features on the landscape. In the real world, this is not necessarily the case. The biggest issue is that some first returns will reach the ground either by penetrating through the tree canopy or from off-nadir scan angle. The result is very steep ‘spike’ triangles that occur in vegetation and on the edges of buildings. These turn into ‘data pits’ in the generated surface model that do not represent the 3D surface of the landscape. By using the ‘spike-free’ flag with las2dem, we eliminate the spikes and interpolate relevant returns in a stepwise fashion beginning with the highest z-value points, triangulating the proximate points, and proceeding downwards. 

![firstreturn](/images/firstreturn.png)
First Return 
![spikefree](/images/spikefree.png)
Spike-free DSM


The key parameter for the spike-free method is the ‘freeze constraint’ which is the threshold value for the edge length of any triangle in meters. Once a triangle exceeds the threshold, it is frozen in place. The appropriate value for the ‘freeze-constraint’ depends on the pulse-density. The recommended value is about three times the average pulse spacing. 

You can visualize the spike-free TIN by running lasview with the flag  ‘-spike_free 2’ and pressing the “y” key many times to generate the TIN in steps in a top-down fashion. Frozen triangles are green while temporary triangles are orange.

We will choose a step size of 1 meter and spike-free freeze constraint of 2 meters. The ‘-kill’ parameter eliminates any triangles with an edge length longer than 5 meters. 
```
Las2dem -i tiles\*z.laz -step 1 -spike_free 2 -kill 5 -odix _nDSM -obil -cores 7
Lasgrid -i tiles\*nDSM.bil -merged -o products\nDSM.bil -obil -utm 15N -nad83
```

### Tree Crown Model
While a nDSM is great for modeling height of trees, the height model ignores the fact that the tree canopy doesn’t extend to the ground in the real world. In the point cloud, we can clearly see the gap between the lowest hanging branches and the ground, so let’s try to model the underside of the tree crown as well. For this to work, the point density must be sufficient enough to provide returns from the inner branches of the tree. Attempting to model the interior of the tree crown also depends on leaf-off conditions to allow laser penetration to the lower branches. 
	

![treecrown](/images/treecrown.png)
To create the minimum height model, we will use the same las2dem command but we are going to trick it by inverting the normalized point cloud. The spike-free surface model is built from the top-down so by inverting the point cloud we are now surface modeling from the bottom-up. To invert the point cloud, simply use the generic las2las and multiply the z value by -1 with the flag ‘-scale_z -1’ and we will remove all points below the threshold of 1 meter (returns on the ground) using ‘-drop_z_below 1’. The las2dem command is the same as before with a freeze constraint of 2 meters, step size of 1, and kill triangles larger than 5 meters. The final step will re-vert the surface model to be right-side up again.

Flip the point cloud and remove points below 1 meter
```
las2las -i tiles\*z.laz -scale_z -1 -drop_z_below 1 -odix _f -olaz -cores 7
```
Create the minimum surface model on tiles 
```
las2dem -i tiles\*f.laz -step 1 -spike_free 2 -kill 5 -odix _m -olaz -cores 7
```
Merge and ‘unflip’ the tiles 
```
lasgrid -i tiles\*m.laz -scale_z -1 -merged -o products\minimum.bil -obil
```



To visualize a cross-section of a point cloud in LASview, press the “x” key to bring up an overview, press “x” again to filter points using the red cross-section window, and use the arrowkeys to ‘walk-through’ the point cloud. Use the “0” key and the “1” to switch between the two surface models. 
```
lasview -i products\minimum.bil -i products\ndsm.bil -faf
```
![invert](/images/invert.png)
Inverted point cloud 
![minimum](/images/minimum.png)
Minimum surface model 
![profile](/images/profile.png)
Profile of max and min height model

Additional raster processing can be completed in a more suitable raster process environment. Subtract the raster layers ndsm.bil and minimum.bil to product the ‘crown height’ raster model. Set any nodata values to 0. 



I.E. 
```
raster calculator	 "nDSM.bil"-"minimum.bil" = CrownHeight.tif 
raster calculator 	“Con(IsNull("CrownHeight.tif "),0,"CrownHeight.tif”) 
```

![CrownModel](/images/CrownModel.png)
Crown Height Raster

More resources
These are some of the applications of LAStools but there are many others as well. There is an active user forum (http://groups.google.com/forum/#!forum/lastools) that has useful additional knowledge and answers to all types of point cloud related questions. 
