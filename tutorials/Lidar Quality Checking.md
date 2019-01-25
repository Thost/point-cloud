# Lidar Quality Checking
###### Adapted from April 20, 2013 by martin isenburg

```
Tools: LASview, LASinfo, LASoverlap, LAScontrol, LAStile, LASboundary, LASgrid
```

### Getting Started 
This is a guide for assessing the quality of a raw lidar flight strips, preparing the lidar for processing, and generating raster and vector derivative products such as DEMs, DSMs, CHMs, and building footprints. This guide uses the LAStools suite of powerful lidar processing tools. We will use the DOS command line version of LAStools to execute lastools commands but there are GUI versions for each of the LAStools. The latest version of LAStools can be downloaded here: https://rapidlasso.com/lastools/. To get started, download the LAStools file provided and move it to the root C: directory. There are 27 LAZ flight lines provided in the directory ‘.\lastools\bin\strips_raw.’ For simplicity we will work in the ‘.\lastools\bin’ directory, so open a DOS command line window and change directory to the lastools bin directory with the command: 
```
cd c:\lastools\bin
```

In this exercise, we will check that the lidar collection meets certain specifications, such as:

* Point density greater than 8 points/sq meter
* Vertical RMSE less than 15 cm
* Complete and consistent coverage of the UMN campus 

### LASview
Let's first inspect the point cloud from one flight line visually to see if the data makes sense. The command below will on-the-fly down-sample the data and display only around 5 million points:

```
Lasview -i strips_raw\flight_1222.laz
```

You can manipulate the point cloud by clicking and dragging in the window. Press the spacebar to change between “Pan”, “Translate”, “Zoom”, and “Tilt” modes of steering. Right-click in the window to bring up the more visualization options. Change the color scheme to “color by flightline.” Since this is one flight line, all the points should be the same color. You can also use the “c” hot-key to toggle through the coloring options. There are a few other visualization options. Coloring points by return turns single returns yellow, first of many returns red, and last of many returns blue. Pressing the “=” key increases the point size and the “-” key decreases the point size. Pressing the “t” key triangulates the points into a TIN used for surface modelling. “h” changes the shading of the TIN. “T” will remove the triangles.

![lasview](/images/lasview.png)
![lasview_options](/images/lasview_options.png)

Now start lasview with the GUI either by double-clicking the executable and using the ‘browse…’ button on the left panel to load the flight strips or by simply adding ‘-gui’ to the command line. 
```
Lasview -i strips_raw\*.laz -gui
```
![lasview_gui](/images/lasview_gui.png)

In the GUI above, you can see some key metadata information for the point clouds. The files x, y, and z scaling factors are set to 0.001 which means that points are stored with millimeter resolution. Because airborne LiDAR is far from being that accurate we will later change the scaling factor to a more appropriate centimeter resolution.

### LASinfo

Next, let’s run lasinfo on one of the strips and compute the point density with the ‘-compute_density’ flag.
```
Lasinfo -i strips_raw/flight_1314.laz -compute_density
```
This produces a standard output with information about the LAZ point cloud. Add ‘-otxt’ to the command above to write the report to a txt file.
