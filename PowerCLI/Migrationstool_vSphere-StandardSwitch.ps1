<#    
Script Name:			Migrationstool_vSphere-StandardSwitch.ps1
Description:			Intern service script for Christian Kremer  Clone vSS from a esxi to a another esxi
Data:				21/Okt/2022
Version:			1.0
Author:				Christian Kremer
Email:				christian@kremer.systems
#> 


#General Vars
[string]$vcsafqdn = read-host -Prompt "Enter the VCSA FQDN"
[string]$sourceHostString = read-host -Prompt "Enter the source Host"
[string]$sourceVSwitchString = read-host -Prompt "Enter the Source Standard Virtual Switch"
[string]$destinationHostString = read-host -Prompt "Enter the Destination Host"


Write-Host "Connect to VMware vCenter" -ForegroundColor Green
Connect-VIServer -Server $vcsafqdn

#Get the destination host
$thisHost = get-vmhost $destinationHostString

#Get the source vSwitch and do error checking
$sVSwitch = get-vmhost -Name $sourceHostString | get-virtualswitch -name $sourceVSwitchString -errorAction silentlycontinue
if (!($sVSwitch))
{
   write-host "$sourceVSwitchString was not found on $sourceHostString" -foreground "red"
   exit 1
}
if ($sVSwitch.count -ne 1)
{
   write-host "'$sourceVswitchString' returned multiple vSwitches; please use a more specific string." -foreground "red"
   $sVSwitch
   exit 4
}
if ($thisHost | get-virtualSwitch -name $sourceVSwitchString -errorAction silentlycontinue)
{   
   if ((($thisHost | get-virtualSwitch -name $sourceVSwitchString).uid) -like "*DistributedSwitch*")
   {
      write-host "$sourceVSwitchString is a Distributed vSwitch, exiting." -foreground "red"
      exit 3
   }
   $continue = read-host "vSwitch $sourceVSwitchString already exists on $destinationHostString; continue? [yes|no]"
   if (!($continue -like "y*"))
   {
      exit 2
   }
}
else
{
   #If the VSS doesn't already exist, create it
   $thisHost | new-virtualSwitch -name $sVSwitch.name > $null
}

#Make new Port Groups on the VSS
$destSwitch = $thisHost | get-virtualSwitch -name $sVSwitch.name
foreach ($thisPG in ($sVSwitch | get-virtualportgroup))
{
   #Skip this Port Group if it already exists on the destination vSwitch
   if ($destSwitch | get-virtualportgroup -name "$($thisPG.Name)" -errorAction silentlycontinue)
   {
      echo "$($thisPG.Name) already exists, skipping."
   }
   else
   {
      echo "Creating Port Group: $($thisPG.Name)."
      new-virtualportgroup -virtualswitch $destSwitch -name "$($thisPG.Name)" > $null
      #Assign a VLAN tag if there is one on the source Port Group
      if ($thisPG.vlanid -ne 0)
      {
         get-virtualportgroup -virtualswitch $destSwitch -name "$($thisPG.Name)" | Set-VirtualPortGroup -vlanid $thisPG.vlanid > $null
      }      
   }
}

Disconnect-VIServer
