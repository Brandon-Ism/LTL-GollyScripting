# Capturing Boundary Coordinates of a Bug in Golly 

### For questions or concerns, contact Brandon I. (brandon.ismalej.671@my.csun.edu)
-----------------------------------------------------------------------------------------------
### The following steps of running scripts within the Golly environment allows the user to capture the inner or outer boundary points of a selected bug that is located on the Golly grid.
-----------------------------------------------------------------------------------------------

### The following scripts are neccessary:

* [BoundaryCellCapture.lua](BoundaryCellCapture.lua)

* [CSVplot.lua](CSVplot.lua) OR [CSVcenter_plot.lua](CSVcenter_plot.lua)

* [CaptureLiveCellstoCSV_AngularSort.lua](CaptureLiveCellstoCSV_AngularSort.lua)

-----------------------------------------------------------------------------------------------

## STEPS (in consecutive order):

1. Desired bug for capture must be stationary on the Golly grid. 

2. Select entire bug using the Golly select tool, located in the tool bar.

3. Run the script: [BoundaryCellCapture.lua](BoundaryCellCapture.lua)
   Ensure that the desired file name for the CSV file to be created is written into the script

   
   Line 73:
   ``` 
   writeCSV("boundary_points.csv", boundary_points)
   ```

   boundary_point.csv to be replaced by your_filename.csv (as desired/neccessary)


4. Once confirming that the CSV file has been created and contains boundary
   coorfinates.

   Locate the file location on your machine and 'copy' the filepath.

   On Windows: Select the csv file through File Explorer, then selected "Copy path" in the toolbar

   On Mac: Secondary click the file on Finder, then hold down the OPTION key\
   to reveal and select “Copy (item name) as Pathname”.

5. Paste the pathname into the script: CSVplot.lua OR CSVcenter_plot.lua

   Line 10:
   ```
   local file_path = 'your_filepath/../../boundary_points.csv'
   ```
   Ensure the path name is contained in single quotes, and uses only foward slashes
   '../../../..'

6. In Golly, run the [CSVplot.lua](CSVplot.lua) OR [CSVcenter_plot.lua](CSVcenter_plot.lua) script
   Ensure that the boundary coordinates have been plotted on the grid as live (1) cells.

7. Once the boundary points are on the grid
   Delete desried live (1) cells on grid, so that only the inner or outer boundary cells are located on the grid. 

8. Using the Golly select tool, select the entire region containg the inner/outer 
   live (1) cells desried. 

9. Run the script : [CaptureLiveCellstoCSV_AngularSort.lua](CaptureLiveCellstoCSV_AngularSort.lua)
   CSV file will be saved in the directory where the Golly.exe software is contained on your machine.
   
   If file name change is desired:

   Line 44: 
   ```
   local filename = g.getdir("app") .. "live_cells.csv"
   ```

   live_cells to be replaced by your_csvName.csv (as desried/neccessary)

10. Inner or outer boundary points have been captured to "live_cells.csv"

