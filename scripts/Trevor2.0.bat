@echo off
title Trevor2.0
color 2
set path=%path%Y:\admin\installs\licensed\lastools64\bin

echo Welcome to point cloud processing
set /p pathname=enter pathname (copy and right click): 
cd /D %pathname%
set /p step=enter the step size (m):
set /p cores=enter the number of cores to use: 

echo zipping...
laszip -i *.las -olaz -rescale 0.01 0.01 0.01 -cores %cores% 2>NUL
echo creating boundary...
mkdir boundary
lasboundary -i *.laz -use_bb -labels -oshp -cores %cores% -odir boundary
echo creating density...
mkdir density
lasgrid -i *.laz -counter_16bit -step %step% -cores %cores% -otif -no_kml -odix _density -odir density
echo creating classification...
mkdir classification
lasgrid -i *.laz -classification -step %step% -cores %cores% -drop_classification 1 -otif -no_kml -odix _classification -odir classification 2>NUL
echo normalizing...
mkdir nlaz
lasheight -i *.laz -replace_z -class 2 11 -cores %cores% -olaz -odix _z -odir nlaz -cpu64
echo creating CHM...
mkdir CHM
lasgrid -i nlaz\*z.laz -elevation -max -step %step% -fill 3 -cores %cores% -otif -odix _chm -odir chm -no_kml
las2dem -i nlaz\*z.laz -spike_free 0.5 -step %step% -kill 2 -odix _max -odir nlaz -olaz -cores %cores% -cpu64 2>NUL
lasgrid -i nlaz\*max.laz -step %step% -otif -odix _sfchm -cores %cores% -odir chm -no_kml

echo done with processing
pause 
goto :eof
