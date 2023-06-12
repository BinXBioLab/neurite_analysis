@echo off

REM Specify the input folder path
set "input_folder=C:\Users\Bin Xu\Desktop\fiji-win64\Fiji.app\macros\AutoneuriteJ_demo_data\my_test7\results_my_test7"

REM Iterate through TIFF files in the folder
for %%F in ("%input_folder%\Bin*.tif") do (

    REM Run Vaa3D-x.exe to process the TIFF file and generate the output SWC file
    "e:\Vaa3D\Vaa3D-x.1.1.2_Windows_64bit\Vaa3D-x.exe" /x vn2 /f app2 /i "%%F" /p NULL 0 10 1 2 1 1 3 1 1 0
)

for %%F in ("%input_folder%\Bin*app2.swc") do (
    REM Run Vaa3D-x.exe to process the TIFF file and generate the output SWC file
   "e:\Vaa3D\Vaa3D-x.1.1.2_Windows_64bit\Vaa3D-x.exe" /x standardize /f standardize  /i "%%F" "%%F" /o "%%F" /p 5 2
)