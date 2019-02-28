# Point Cloud Canopy Statistics
```
Tools: LASview, LASinfo, LASgrid, LASheight, LASclip, LAScanopy, LASboundary

```

### Overview

In this exercise, you will learn how to prepare and analysis a lidar point cloud to extract commonly measured attributes related to forest inventory using LAStools. We will compare grid metrics with polygon stand boundaries. This example uses a high-density lidar sample but the approach is transferable to any point cloud dataset with accurately classified ground points. 


### Single Photon Lidar 

In this exercise, we will use one tile from a 2017 single photon lidar acquisition in the Superior National Forest. Single photon lidar is collected using a different mode than the traditional linear lidar but the resultant point cloud has been pre-processed and can be used with existing tools. For more information about the differences between lidar modes, see this presentation. 

The LAZ file name is 15TWP59253107.laz. This area contains mixed forest cover types, including a red pine plantation, and is located in the Hubachek Wilderness Research Center. Navigate to the directory location in the command line window and run lasview to visualize the data. 


![SPL](/tutorials/images/SPL.png "")
15TWP59253107.laz - SPL from Fall 2017 colorized with concurrent RGB imagery 

You will notice that this lidar has natural color imagery mapped onto the points in the red, green, and blue channels. There is also near-infrared (NIR) imagery stored in the NIR channel. The point density of this dataset is quite high. To determine the point density we will first run the lasinfo command and create a raster map of the density using the lasgrid command. Run lasinfo with ‘-cd’ to compute the density. Run LASgrid with the -counter option and -step 1 to create a raster of number of points per 1 m grid cell.  

```
Lasinfo -cd -i 15TWP59253107.laz
Lasgrid -i 15TWP59253107.laz -counter -step 1 -otif 
```

>*point density: all returns 39.11 last only 34.62 (per square units)  
>       spacing: all returns 0.16 last only 0.17 (in units)*

Note that there are a number of classes assigned to the points including ground (2) and keypoints (8). We will use these in the next step. 

![density](/tutorials/images/density.png "")
Number of points per square meter (blue to red) 

### Height normalization

Before calculating any canopy metrics we must normalize the point cloud and recode the z elevation values with z height values. To do this, the LASheight tool is the best option since we already have ground classified points. We will call the LASheight tool with the agruments -replace_z to recode the z coordinate, '-class 2 8' to specify the ground points we would like to use, 0utput as a new LAZ point cloud, and append '_z' to the file name with '-odix _z'. 

```
lasheight -i 15TWP59253107.laz -replace_z -class 2 8 -olaz -odix _z -v 
```

### Canopy Statistics

Now we can begin to calculate canopy metrics using the tool LAScanopy. There are many metrics that can be produced from the point cloud. A few of the most popular for forestry applications are average, 95th percentile, percent coverage, and standard deviation. These can be calculated at various grid sizes (step) depending on (1) the density of the point cloud and (2) the resolution of the desired output. For modeling purposes, step sizes of 10 - 20 m are common because the grid size corresponds with the plot size used in building the model. For fine detail in mapping, smaller step sizes are used such as 1 - 10 m but require higher point cloud density to produce useful results. Canopy metrics are calculated by filtering the points by a height threshold. This is done to remove ground points from the calculation and more accurately describe the distribution of canopy points. The default for the height cutoff in LAScanopy is 1.37 m (4.5 ft; international breast height). If necessary this can be changed using the ‘-height_cutoff’ but we will use the default settings for this example. 

```
lascanopy -i *z.laz -step 2 -avg -p 95 -cov -std -otif -drop_classification 6 7 9 10 19
```





