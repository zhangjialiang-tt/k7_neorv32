@echo off
set MODELSIM_ROOT=D:\Software\modeltech64_2020.4
set VSIM=%MODELSIM_ROOT%\win64\vsim.exe

REM 执行all目标
:all
%VSIM% -do "do run_image.do"
goto:eof

REM 执行run_sim目标
:run_sim
%VSIM% -do "do run_image.do"
goto:eof

REM 执行clean目标
:clean
del /F /S /Q modelsim.ini work *.wlf transcript *.out
goto:eof