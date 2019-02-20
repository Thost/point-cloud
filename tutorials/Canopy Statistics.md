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





