<#    
Script Name:		Vmware vSphere-vDoc.ps1
Description:		Intern service script for Christian Kremer 
Data:			15/Jul/2022
Version:		1.0
Author:			Christian Kremer
Email:			christian@kremer.systems
#> 


<# 
Install requirements 
#>

write-Host "Install vDoc requirements" -ForegroundColor Green


Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force


if (!(Get-InstalledModule -Name VMware.PowerCLI -ErrorAction SilentlyContinue)) 
{
        Install-Module VMware.PowerCLI -Scope CurrentUser -Force
}

if (!(Get-InstalledModule -Name ImportExcel -ErrorAction SilentlyContinue)) 
{
        Install-Module ImportExcel -Scope CurrentUser -Force
}

if (!(Get-InstalledModule -Name vDocumentation -ErrorAction SilentlyContinue)) 
{
        Install-Module vDocumentation -Scope CurrentUser -Force
}

<#
variable declaration
#>

$vcsaFQDN="VCSA FWDN"
$ExportPath="C:\vDoc-Export"


if (!(Test-Path $ExportPath)) {New-Item -Path $ExportPath -ItemType Directory}


Write-Host "Connection vCenter" -ForegroundColor Green
Connect-VIServer -Server $vcsaFQDN

write-Host "Running vDoc data collection" -ForegroundColor Green


write-host "ESX Inventory" -ForegroundColor Green
Get-ESXInventory -ExportCSV -folderPath $ExportPath

write-host "ESX IO Device" -ForegroundColor Green
Get-ESXIODevice -ExportCSV -folderPath $ExportPath

write-host "ESX Networking" -ForegroundColor Green
Get-ESXNetworking -ExportCSV -folderPath $ExportPath

write-host "ESX Storage" -ForegroundColor Green
Get-ESXStorage -ExportCSV -folderPath $ExportPath

write-host "vSAN Info" -ForegroundColor Green
Get-vSANInfo -ExportCSV -folderPath $ExportPath

write-host "ESX Patching" -ForegroundColor Green
Get-ESXPatching -ExportCSV -folderPath $ExportPath

write-host "ESX Spectre and Meltdown mitigation" -ForegroundColor Green
Get-ESXSpeculativeExecution -ExportCSV -folderPath $ExportPath

write-host "VM Spectre and Meltdown mitigation" -ForegroundColor Green
Get-VM | Get-VMSpeculativeExecution-ExportCSV -folderPath $ExportPath

Write-Host "vSphere firewall rule set" -ForegroundColor Green

$fwruleset=Get-VMHost -PipelineVariable esx |

ForEach-Object -Process {

    $esxcli = Get-EsxCli -VMHost $esx -V2

    $esxcli.network.firewall.ruleset.rule.list.Invoke() |

    Select @{N='VMHost';E={$esx.Name}},RuleSet,

    @{N='Enabled';E={$esxcli.network.firewall.ruleset.list.Invoke(@{rulesetid="$($_.Ruleset)"}).Enabled}},

    Direction,Protocol,PortBegin,PortEnd,PortType

}

$fwruleset | Export-Csv $ExportPath\firewall-ruleset.csv


write-host "vDoc data collection is finished stop connection to vcenter" -ForegroundColor Green  
Disconnect-VIServer -Server * -Force -Confirm:$false

#get the list of csv files
$csvFiles = Get-ChildItem $ExportPath -Filter *.csv

foreach ($file in $csvFiles)
{
    
    [System.IO.FileInfo]$fileInfo = "$ExportPath\$file"

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    
    Import-Csv -Delimiter "," $fileInfo.FullName | ConvertTo-Html -Head $css -Body "<h2>vDocumentation - Christian Kremer</h2>`n<h5>Generated on $(Get-Date)" | Out-File "$ExportPath\$baseName.html" 
}