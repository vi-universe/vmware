<#    
Script Name:		Build VM Start Policy based on Tags.ps1
Description:		Intern service script for Christian Kremer 
Data:				01/Jan/2023
Version:			1.0
Author:				Christian Kremer
Email:				christian@kremer.systems


#> 



$vcsaFQDN = "vcsa FQDN"
$Cluster = "Cluster"



Write-Host "Connection vCenter" -ForegroundColor Green
Connect-VIServer -Server $vcsaFQDN

<# Create the tags once
$Category="Autostart-priority"


$TagArray = @('StartPrio-Critical', 'StartPrio-High', 'StartPrio-Medium', 'StartPrio-Low', 'StartPrio-Manually')

write-host "Create category for autostart tags" -ForegroundColor Green
New-TagCategory -Name $Category -Cardinality "Single" -EntityType "VirtualMachine" -Description "Autostart priority category"

write-host "Create autostart priority tags" -ForegroundColor Green
foreach ($tags in $TagArray) 
{
    Get-TagCategory -Name $Category | New-Tag -Name $tags -Description "VM $tags" 
}

#>

Get-Cluster $Cluster | Get-VMHost | Get-VMHostStartPolicy | Set-VMHostStartPolicy -Enabled:$true

function AutoStartCritical {
 param(
		$StartAction,
		$startOrder,
		$StartDelay,
		$StopAction,
		$StopDelay,
		$StartPolicy
        
	)
	Set-VMStartPolicy -StartPolicy $StartPolicy -StartAction $StartAction -StartOrder $StartOrder -StartDelay $StartDelay  -StopAction $StopAction  -StopDelay $StopDelay
}

function AutoStartHigh {
 param(
		$StartAction,
		$startOrder,
		$StartDelay,
		$StopAction,
		$StopDelay,
		$StartPolicy
        
	)
	Set-VMStartPolicy -StartPolicy $StartPolicy -StartAction $StartAction -StartOrder $StartOrder -StartDelay $StartDelay  -StopAction $StopAction  -StopDelay $StopDelay
}

function AutoStartMedium {
 param(
		$StartAction,
		$startOrder,
		$StartDelay,
		$StopAction,
		$StopDelay,
		$StartPolicy
        
	)
	Set-VMStartPolicy -StartPolicy $StartPolicy -StartAction $StartAction -StartOrder $StartOrder -StartDelay $StartDelay  -StopAction $StopAction  -StopDelay $StopDelay
}

function AutoStartLow {
 param(
		$StartAction,
		$startOrder,
		$StartDelay,
		$StopAction,
		$StopDelay,
		$StartPolicy
        
	)
	Set-VMStartPolicy -StartPolicy $StartPolicy -StartAction $StartAction -StartOrder $StartOrder -StartDelay $StartDelay  -StopAction $StopAction  -StopDelay $StopDelay
}



#Set VM Start Policy based on the assigned tag
Write-Host "Set vm autostart settings based on a tag" -ForegroundColor Yellow
$VMs = Get-Cluster $Cluster | Get-VM | Get-TagAssignment


foreach ($VM in $VMs) {
 $VMStartPolicy = Get-VMStartPolicy -VM $VM.Entity.Name
	Switch ($VM.tag.name) {
		"StartPrio-Critical" { AutoStartCritical -StartPolicy $VMStartPolicy -StartAction PowerOn -startOrder 1 -StartDelay 120 -StopAction GuestShutdown -StopDelay 120 }
		"StartPrio-High" { AutoStartHigh -StartPolicy $VMStartPolicy -StartAction PowerOn -startOrder 2 -StartDelay 120 -StopAction GuestShutdown -StopDelay 120 }
		"StartPrio-Medium" { AutoStartMedium -StartPolicy $VMStartPolicy -StartAction PowerOn -startOrder 3 -StartDelay 120 -StopAction GuestShutdown -StopDelay 120 }
		"StartPrio-Low" { AutoStartLow -StartPolicy $VMStartPolicy -StartAction PowerOn -startOrder 4 -StartDelay 120 -StopAction GuestShutdown -StopDelay 120 }
		"StartPrio-Manually" { $VMSPManually = Get-Cluster $Cluster | Get-VM | Select-Object -ExpandProperty Name | Where-Object { (get-tagassignment $_ -Tag "StartPrio-Manually") } }
	} 
}

Write-Host 'VM with StartPrio-Manually tag' $VMSPManually -ForegroundColor Red

Disconnect-VIServer