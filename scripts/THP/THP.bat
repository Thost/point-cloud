@echo off 
set file=%~n1
cd /d %~dp1
rem set file=WV03_20170502_104001002CC7F300_104001002B9AC700_501583029080_01_P002_501583033060_01_P002_0_dem.tif
set CP=%2
rem for example: L:\adjusted_dsms\reference_points\Canada\LongPoint_ref_points_xyz.csv
if [%1]==[] GOTO bad_file
if [%2]==[] GOTO bad_control
if not %~x1==.laz (GOTO bad_file) else (
if not %~x2==.csv (GOTO bad_control) else (echo starting %file%))

rem - tile and sort
mkdir %file%
echo tiling...
lastile -i %file%.laz -tile_size 4000 -olaz -odir %file%
lassort -i %file%\*.laz -olaz -odix _s -cores 15 -cpu64 2>NUL
lasindex -i %file%\*.laz -cores 15 -append 2>NUL

rem - ground class 
echo finding ground...
lasground_new -i %file%\*s.laz -buffered 100 -odir %file% -step 100 -offset 0.3 -refine 1 -olaz -odix _g100 -cores 15 -cpu64 2>NUL
lasgrid -i %file%\*g100.laz -step 2 -counter -keep_classification 2 -merged -o %file%_ground.tif -otif -no_kml 2>NUL
lasmerge -i %file%\*g100.laz -o %file%_g.laz -olaz 

rem - align
echo snapping...
lascontrol -i *g.laz -cp %CP% -step 10 -keep_class 2 -olaz -adjust_z -odix _adj -v 1>NUL 2>%file%_offset.txt
lascontrol -i *adj.laz -cp %CP% -step 10 -keep_class 2 -v 1>NUL 2>%file%_accuracy.txt
lasgrid -i *adj.laz -step 2 -merged -o %file%_adj.tif -otif -no_kml 2>NUL

echo done with %file%
rmdir /s/q %file%

goto :eof


:bad_file
echo input one must be laz
pause
:eof

:bad_control
echo input two must be csv control points
pause
:eof
