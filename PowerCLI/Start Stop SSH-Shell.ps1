<#    
Script Name:			Start Stop Shell.ps1
Description:			Intern service script for Christian Kremer 
Data:					15/Jul/2022
Version:				1.0
Author:					Christian Kremer
Email:					christian@kremer.systems


TSM >>> ESXi Shell              
TSM-SSH >>> SSH       

#> 



$vCenterFQDN="vcenterfqdn"


write-host "Connecting to $vCenterFQDN" -ForegroundColor Green
Connect-VIServer $vCenterFQDN

 
function Show-CustomMenu
{
    param (
        [string]$menuname = 'Enable SSH and ESXi shell on all hosts'
    )
    Clear-Host
    Write-Host "================ $menuname ================"
    
    Write-Host "1: Choose '1' Enable SSH on all hosts"
    Write-Host "2: Choose '2' Enable Shell on all hosts"
    Write-Host "3: Choose '3' Disable SSH on all hosts"
    Write-Host "4: Choose '4' Disable Shell on all hosts"
    Write-Host "Q: Choose 'Q' Exit."
   
}


Show-CustomMenu –menuname 'Manage SSH and ESXi Shell'

$selection = Read-Host "Enter the option"
# choose option
switch ($selection){
     '1' {Get-VMHost | Get-VMhostService | Where-Object {$_.Key -eq "TSM-SSH"} | Start-VMHostService}
     '2' {Get-VMHost | Get-VMhostService | Where-Object {$_.Key -eq "TSM"} | Start-VMHostService}
     '3' {Get-VMHost | Get-VMhostService | Where-Object {$_.Key -eq "TSM-SSH"} | Stop-VMHostService}
     '4' {Get-VMHost | Get-VMhostService | Where-Object {$_.Key -eq "TSM"} | Stop-VMHostService}
     'q' {exit}
     }