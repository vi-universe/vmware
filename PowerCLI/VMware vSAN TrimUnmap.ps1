<#    
Script Name:		VMware vSAN TrimUnmap.ps1
Description:		Intern service script for Christian Kremer 
Data:				15/Jul/2022
Version:			1.0
Author:				Christian Kremer
Email:				christian@kremer.systems

Set vSAN Trim/Unmap

https://vi-universe.blogspot.com/2022/02/provisioning-ist-eine-moglichkeit.html

#> 



write-host "Specify vCenter FQDN" -ForegroundColor Green 
$vCenter= Read-Host "Enter your vCenter FQDN" 

write-host "Specify vSAN Cluster Name" -ForegroundColor Green 
$vSANClusterName= Read-Host "Enter your vSAN Cluster name"


write-host "Connecting to $vCenter" -ForegroundColor Green
Connect-VIServer $vCenter

 
function Show-CustomMenu
{
    param (
        [string]$menuname = 'vSAN Cluster Trim/Unmap option'
    )
    Clear-Host
    Write-Host "================ $menuname ================"
    
    Write-Host "1: Choose '1' Show Trim Unmap state"
    Write-Host "2: Choose '2' Activate Trim Unmap"
    Write-Host "3: Choose '3' Deactivate Trim Unmap"
    Write-Host "Q: Choose 'Q' um das Programm zu beenden."
   
}


Show-CustomMenu –menuname 'vSAN Cluster Trim/Unmap'

$auswahl = Read-Host "Enter the option"
# Optionen wählen
switch ($auswahl){
     '1' {Get-Cluster -Name $vSANClusterName |Get-VsanClusterConfiguration | ft GuestTrimUnmap}
     '2' {Get-Cluster -Name $vSANClusterName |Set-VsanClusterConfiguration -GuestTrimUnmap:$True}
     '3' {Get-Cluster -Name $vSANClusterName |Set-VsanClusterConfiguration -GuestTrimUnmap:$false}
     'q' {exit}
 }