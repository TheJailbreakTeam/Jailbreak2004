@echo off

:: ============================================================================
:: Create Package
:: ============================================================================

echo Creating package...

cd ..\System
ucc pkg import sound ..\Sounds\JBVoiceLlama ..\JBVoiceLlama\Sounds

echo Done.


:: ============================================================================
:end