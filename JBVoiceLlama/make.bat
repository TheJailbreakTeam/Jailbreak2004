@echo off

:: ============================================================================
:: Create Package
:: ============================================================================

echo Creating package...

cd ..\System
ucc pkg import sound ..\Sounds\JBVoiceBullwinkle ..\JBVoiceBullwinkle\Sounds

echo Done.


:: ============================================================================
:end