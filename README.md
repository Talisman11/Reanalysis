# NCEP/NCAR Reanalysis Temporal Interpolation Program

NCEP/NCAR has been collecting Reanalysis data since 1948 of various atmospheric variables across the Earth, stored in surface level (3D) or multilevel (4D) formats and is used by scientists around the world for research and analysis. Although the data is abundant, it is also coarse-grained in temporal and spatial senses, at 4x Daily (6 hour intervals) and 2.5 x 2.5 degree resolution. This program handles the temporal problem through linear interpolation on multilevel files, and is intended for usage on UIUC's Blue Waters, but is extensible to local machines and other supercomputing clusters given the correct setup. As of August 18, 2017, an additional query program has been included to allow users to view data from the files without needing to use HDFView.

## Input:

The program requires `n+1` NetCDF input files for interpolation to correctly output `n` files. This is because interpolation of the data between the final time unit of one year requires the data of the following year's first time unit. These files are also expected to be multilevel files from NCEP/NCAR, and of the finest granularity available (Daily 4x = 6 hour interval data sampling). Note that this means surface-level files will not work (single level), as these files are 3D whereas multilevel are 4D. Also ensure that there are no unrelated files in the directory, such as `.txt` or `.log`, or other variables that require separate interpolation. 

## Output:

Given a combination of arguments through command line flags, the program will output `n` interpolated files of the specified temporal granularity, optionally labeled with a prefix and suffix for clarity/stockkeeping. Files preserve only the necessary data from the input file, i.e. values for each variable (`time, lvl, lat, lon`), but no attribute information.

## Execution Setup:

1) `SSH` into Blue Waters
2) `git clone [this repository]`
3) `module swap [current PrgEnv] PrgEnv-cray`
3) `module load cray-hdf5`
4) `module load cray-netcdf/4.4.1.1`
5) `make`
5) View/Modify and `qsub curl.pbs` to download data // modify range or path on NCEP/NCAR FTP server to download different files
6) View/Modify and `qsub reanalysis.pbs` with desired arguments

### Program Arguments:
- `./reanalysis` - **Required**: Runs the program (stops without any flags)
- `-t [temporal granularity]` - **Required**: Determines granularity of interpolated output. Must be a factor of 360. I.e. `-t 15` sets the new output to be 24 times more fine grained with 15 minute intervals
- `-i [input_dir]` - **Required**: Specifies where the program will read files from. Ensure this directory is clean and contains only the desired variables
- `-o [output_dir]` - *Recommended*: Specifies where files will be written to. Default is the input_dir but tends to get cluttered quickly
- `-p [prefix]` - Prepends this string to all output files. Does not need quotations
- `-s [suffix]` - Appends this string to all output files (before the `.nc` for the filetype). Default suffix is `.copy`. Does not need quotations
- `- d` - Disables the clobbering of NetCDF. By default, the program will overwrite interpolated files when run without this flag. As an aside and feature unrelated to the clobbering flag, if interpolated files are found within the input directory (presence of suffix or prefix), the program will attempt to skip these files.
- `-v` - Enables more verbose output from the program. Useful for viewing the dimension mapping and lengths of the variables.

### Example execution:

```
./reanalysis -t 90 -i ../scratch/ncar_files/pressure/ -o ../scratch/ncar_files/pressure_interpolated/ -p interp -s _90 -v -d
```

Runs the `./reanalysis` program found in the current directory for temporal granularity of 90 minutes from the `pressure/` sub-subdirectory of the (outer) `scratch/`, outputting the files into the `pressure_interpolated/`, prefixing the files with string `interp` and suffixing them with `_90`, generating verbose output and disabling the clobbering (prevents program from overwriting any previously generated files with same prefix or suffix). *Note that the ending `/` must be included for directories or else the program will fail.* Program usage requires `-t` and `-i` to be set; default output files have suffix `.copy` and output directory is the input directory (this can get messy after a few iterations; recommend to use GLOBUS or other file transfer to move the files out).

## HDFView Setup (Optional - Requires HDFView to be installed on local machine):

1) SFTP an HDFView directory or .tar file from local machine to BW directory
  - `put -r HDFView/` command fails if the directory does not exist on your BW directory
  - `mkdir HDFView`, then run `put` again. Generates some recursion errors but can be cleaned up and used
2) Run `.sh` file, follow prompts
3) Verify X11 `DISPLAY` variable has been set:
  - `echo $DISPLAY`
  - Lack of output indicates it has not been set
4) `export DISPLAY=:0.0` to set `DISPLAY` var
5) `ssh -X` into Blue Waters
6) `sh hdfview.sh` to confirm it is working

## Program Interpolation Explanation:

NCEP/NCAR multilevel files are 4D, namely `Time, Level, Latitude, Longitude`, for desired variables. Given a quadruple coordinate, there is a value for the desired variable (`air, hgt, vwnd`, etc) at that time and space. This program performs linear interpolation along the time dimension, and can be best understood as interpolating between cubes (3D) representing the Earth, where each time unit is a cube or snapshot of the Earth at that time. Standard files have dimensions following 1460 x 17 x 73 x 144, for the Time, Level, Latitude, and Longitude, respectively. Thus a file contains 1460 `Time` cubes of dimensions 17 x 73 x 144 (perhaps rectangular prism, but the gist is the same). To interpolate to a granularity of 90 minutes (from 360 minutes (Daily 4x = 6 hour intervals)), linear interpolation must generate 4 values for the new file - 3 being the interpolated values and 1 being the original value. I.e. to interpolate between (12, 1, 23, 50) and (13, 1, 23, 50), the slope is calculated between the respective values, then the slope-intercept equation (`y = mx + b`) is used to find the values for `T={12.25, 12.5, 12.75}` for the triple (1, 23, 50). Understanding this, the program is essentially taking two `Time` cubes, interpolates between all the 3D values to generate more `Time` cubes in between them, the amount dependent on the temporal granularity specified at runtime. Note that there is the edgecase on Dec 31st, where 18:00 is the last `Time` cube of the file, but there is no later information in the file for interpolation -- the program uses the following year's first `Time` cube to perform interpolation and complete the file.

## Program Code Flow (netCDF\_driver.c):

main()

... process\_arguments()

... open\_directory()

... for each file in directory - 1:

... ... Select one file, verify it is a .nc file

... ... Select the next file, verify again

... ... Generate relative paths for directories and files


... ... Primary function:

... ... ... Read in first file metadata

... ... ... Check next file is the same variable before interpolating

... ... ... Allocate memory for first file's variable data

... ... ... Create new file for interpolation output

... ... ... Define Dimensions and Variables (length determined by -t flag) 

... ... ... Set compression

... ... ... Populate variable values for Time, Level, Latitude, Longitude individually (i.e. hours, meters, degrees)

... ... ... Perform temporal interpolation 

... ... ... Clean up, close file handles


... ... Clear file names



... Clear allocated names of the directory

... Exit

*Created by Brandon Chen (bchen36@illinois.edu).*
