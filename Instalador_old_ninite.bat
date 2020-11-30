@echo off

bitsadmin.exe /transfer "DescargaScriptPowershell" https://cloudbox.altia.es/index.php/s/CSkNDHGYosrHYgF/download %USERPROFILE%\Downloads\script_ninite_ocs_domain.ps1

Powershell.exe -executionpolicy remotesigned -File %USERPROFILE%\Downloads\script_ninite_ocs_domain.ps1
