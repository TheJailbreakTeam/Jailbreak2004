@echo off
if "%1"=="copygroup" goto copygroup

:: ============================================================================
:: Configuration
:: ============================================================================

:: whitespace-separated list of all static mesh groups to add to the package
set groups=Doors


:: ============================================================================
:: Create Package
:: ============================================================================

echo Preparing source files...

mkdir TempSourceFiles
for %%g in (%groups%) do call %0 copygroup %%g


echo Creating package...

:: prevent warning when overwriting with smaller file
if exist ..\StaticMeshes\JBStaticMeshes.usx del ..\StaticMeshes\JBStaticMeshes.usx

cd ..\System
ucc editor.batchimport ..\StaticMeshes\JBStaticMeshes.usx staticmesh ..\JBStaticMeshes\TempSourceFiles\*.ase


echo Cleaning up...
del ..\JBStaticMeshes\TempSourceFiles\* /q
rmdir ..\JBStaticMeshes\TempSourceFiles


echo Done.
pause > nul

goto :end


:: ============================================================================
:: Copy Group
:: ============================================================================

:copygroup

cd StaticMeshes\%2
for %%f in (*.ase) do copy %%f ..\..\TempSourceFiles\%2.%%f > nul
cd ..\..


:: ============================================================================
:end