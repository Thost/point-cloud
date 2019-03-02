# Photogrammetric Point Clouds

```
Tools: LASview, LASinfo, LASsort, LASthin, LAScontrol, LASheight, LAScanopy, lASpublish
```

### Overview

This exercise is focused on integration of multiple types of point clouds. We will explore a photogrammetric point cloud that was produced from dense image matching of many overlapping UAS images. Some validation and pre-processing of the point cloud is required. Then we will calibrate the point cloud using a lidar dataset acquired approximately at the same time. Then we will normalize the point cloud to obtain height above ground measurements and summarize those measurements for a red pine plantation in the Hubachek Wilderness Research Center near Ely, MN. Finally, we will produce web-based point cloud visualization for the dataset. 

### Photogrammetric Point Cloud

Photogrammetry has been a established practice in remote sensing for many years. Traditionally, it was used to develop stereoscopic views from overlapping aerial images. It is the principal behind orthorectification for topographic displacement. Modern photogrammetry is computer driven by software that can compare two or more overlapping images, ‘match’ individual pixels, and locate them in three dimensional space. The product is a point cloud that is similar in appearance to a lidar derived point cloud. The main difference is that photogrammetric point clouds have poor foliage penetration (FOPEN). Where a lidar laser beam can pass through small gaps in the canopy, a photogrammetric point must be present in at least two different images to be identified as a match point. We can reduce this issue by increasing the overlap between images, but it is almost impossible to obtain ground points in closed canopy from the optical data. Fortunately, we can use these two different forms of 3D point clouds in conjunction with one another to obtain high accuracy height normalization, improve classification, and improve the spatial orientation of the data. 

But first, let’s start by visualizing the point cloud with LASview. 
```
lasview -i ../3/photogrammetric.laz
```

![](/tutorials/images/photogram.png "")  
Photogrammetric point cloud - Hubachek Wilderness Research Center


As the data appears in the view window, notice how the pattern in which the points are drawn. This corresponds with the point order within the LAZ file. Point order matters in a big way when it comes to reading and processing point clouds. This point cloud is not stored in the most spatially coherent order. The points are arranged in long vertical lines rather than small square cubes. We can reorder the points using the LASsort tool. 

### LASsort 

We call LASsort to reorder the point cloud into a spatially coherent order to improve processing speed and reduce file storage size. We also rescale coordinate resolution to centimeter (0.01 m) scale to further reduce file size. Photogrammetric point clouds don’t have multiple returns but they are similar to first returns in lidar. Set the return number to 1 for all points using ‘-set_return_number 1’. The output file is LAZ with ‘_s’ appended file name. Set the target EPSG to 6344 to project the data to the same CRS as the lidar. Finally, we specify -cpu64 to use the 64-bit version of the tool.
```
lassort -i ../3/photogrammetric.laz -rescale 0.01 0.01 0.01 -set_return_number 1 -olaz -odix _s -target_epsg 6344 -cpu64 
```


![](/tutorials/images/files.png "")  
Result: The output file takes up 35% less disk space and will read much faster in the additional processing steps. 

### Vertical datums

Now that we have that out of the way, let’s compare our point cloud with lidar ground points. Run the following command to view both together. 
```
lasview -i ../3/photogrammetric_s.laz -i lidar_ground.laz -faf
```
![](/tutorials/images/profile_ground.png "") 
Vertical profile of lidar and photogrammetric point clouds 

This doesn’t look good, the ground points are above the trees in our collect. What is going on here? 

The vertical displacement is the result of differing reference frames. One is measuring ellipsoidal height while the other is measuring orthometric (geoid) height. There are various models of the earth’s equipotential surface called geoids (the latest version is Geoid12B). Any GPS measurements are ellipsoidal height. We must convert these to orthometric height to compare the datasets. To do this, we will use lidar ground points with LAScontrol to calculate the difference and adjust the z-values in the photogrammetric point cloud. First we must obtain our control points from the lidar ground dataset. 

### LASthin

We need a list of control points to use as an input for LAScontrol. These must be well-distributed and in ASCII text format. We already have a good ground estimate from the lidar dataset but there are more points than we need. LASinfo will tell us that there are 1,782,896 ground points in the file lidar_ground.laz. We can use LASthin to greatly reduce this number and output this file as in plain text. We will keep one point every 20 meters using the flag ‘-step 20’ and ‘-otxt’ to output as a TXT file. 
```
lasthin -i ../3/lidar_ground.laz -step 20 -otxt
```
![](/tutorials/images/ground.png "") 
Thinned ground points

### LAScontrol 

This list of points will now be used as our control points in LAScontrol. We will use the flags ‘-step 1’ and ‘-keep_class 2 11’ to set a filter for to keep points within 1 meter of each control point and only points classified as ground (2) and road (11). The flags  ‘-adjust_z’, ‘-olaz’, and ‘-odix _adj’ are included so that a new LAZ with adjusted z-values is written as an output. 
```
lascontrol -i ../3/photogrammetric_s.laz -step 1 -keep_class 2 11 -cp ../3/lidar_ground_1.txt -adjust_z -olaz -odix _adj
```
You will get a long printout of all the points followed by:

WARNING: there were 492 control points without sufficient LIDAR coverage.
sampled TIN at 291 of 783 control points.
avgabs/rms/stddev/avg of elevation errors are 32.8305/32.8388/0.739218/-32.8305 feet. skew is 0.62846.


This tells us that 1) 492 control points are not within range of photogrammetric ground points, 2) 291 are within range sufficient ground points, 3) the error report for average absolute error, root mean square error, average elevation error, and skew. 

Check your directory for the output LAZ file that ends with ...adj.laz. Open this file and lidar_ground.laz with LASview to verify the results. They are now aligned to the same reference frame and we are able to normalize the point cloud. 

![](/tutorials/images/profile.png "") 
lidar points: red, photogrammetric points: green


### LASheight

We will use LASheight to normalize the points to the height above ground for each point. In this case, we use an external ground points file instead of the default which is ground classified points stored internally in the LAZ. 
```
lasheight -i ../3/photogrammetric_s_adj.laz -ground_points ../3/lidar_ground.laz -replace_z -odix _z -olaz -vv
```
first pass. reading 1782896 points to count ground points ...
took 1.961 sec. counted 1782896 ground points.
second pass. triangulating 1782896 ground points ...
took 4.368 sec. triangulated 1782896 points.
third pass. computing heights for 68042519 points ...
done with 'photogrammetric_s_adj_z.laz'. total time 65.833 sec.


Normalized photogrammetric point cloud


### LAScanopy

Now we can begin to calculate canopy metrics using the tool LAScanopy. There are many metrics that can be produced from the point cloud. A few of the most popular for forestry applications are average, 95th percentile, percent coverage, and standard deviation. We will first use a polygon shapefile as our AOI using the ‘-lop’ input which stands for ‘list of plots’ and takes a shapefile as an input. The shape file contains four 1/10 acre plots and a stand boundary. 

![](/tutorials/images/map.png "") 
Plots and stands for forestry metrics

Canopy metrics are calculated by filtering the points by a height threshold. This is to remove ground points from the calculation and more accurately describe the distribution of canopy points. The default for the height cutoff in LAScanopy is 1.37 m (4.5 ft; international breast height). If necessary, this can be changed using the ‘-height_cutoff’ but we will use the default settings for this example.
```
lascanopy -i ../3/photogrammetric_s_adj_z.laz -lop ../3/plots.shp -avg -p 95 -cov -std -ocsv
```

Next we will produce a raster output for each metric with the resolution set by the -step parameter. These can be calculated at various grid sizes (step) depending on (1) the density of the point cloud and (2) the resolution of the desired output. For modeling purposes, step sizes of 10 - 20 m are common because the grid size corresponds with the plot size used in building the model. For fine detail in mapping, smaller step sizes are used such as 1 - 10 m but require higher point cloud density to produce useful results. The point density of the photogrammetric point cloud is very high so we will use 1 meter resolution to produce rasters of average, 95th percentile, percent cover, and standard deviation. 
```
lascanopy -i ../3/photogrammetric_s_adj_z.laz -step 1 -avg -p 95 -cov -std -otif
```
![](/tutorials/images/1.png "")
![](/tutorials/images/2.png "")
![](/tutorials/images/3.png "")
![](/tutorials/images/4.png "") 


We can compare the raster values to the summary statistics in the CSV table. Which plot had the highest average? Which plot had the most variance? Do those make sense looking at the raster maps? 


### LASpublish

Finally, we will use LASpublish to create a web viewer to display point clouds. LASpublish is a tool that will build the HTML and associated files for a potree web viewer. Potree is an open-source and powerful WebGL point cloud viewer. We will use the adjusted photogrammetric point cloud and the lidar ground points. 
```
laspublish -i photogrammetric_s_adj.laz -i lidar_ground.laz -rgb -o portal.html
```
This will create a set of files in a new folder that is titled laspublish.xxxxx. Inside will be libs, pointclouds folders as well as portal.html and lasmap_portal.html. You can open the ‘portal.html’ file locally using Mozilla Firefox.
 
![](/tutorials/images/potree.png "") 
