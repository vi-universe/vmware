<#    
Script Name:		kb96895_vsan_osa.ps1
Description:		Intern service script Christian Kremer 
Data:		        09/Feb/2024
Version:		    1.0
Author:			    Christian Kremer
Email:			    christian@kremer.systems    
#>     


import-module VMware.VimAutomation.Core
$vcsaparams = @{
    # vcsa ip address or fqdn
    Server   = ''
    # administrator@vsphere.local
    Username = 'administrator@vsphere.local'
    # administrator@vsphere.local password
    Password = ''

}

Function Get-lsomPlogZeropV2 {

    param (
        [CmdletBinding(SupportsShouldProcess = $False)]
        [parameter(Mandatory = $true, HelpMessage = 'vcsaparameters')]
        [ValidateNotNullorEmpty()]
        [hashtable] $vcsaparameters
		
    )
    if ('' -eq "$($vcsaparameters.Server)" -or '' -eq "$($vcsaparameters.Username)" -or '' -eq "$($vcsaparameters.Password)") {
        Write-Host "Please check your parameters:"
        $vcsaparameters
        return
    }
    
    Connect-VIServer @vcsaparams
    $esxihosts = Get-VMHost | Get-EsxCli -v2
    foreach ($esxihost in $esxihosts) {
        Write-Host = $esxihost.VMHost "/LSOM/lsomPlogZeropV2 IntValue state" -ForegroundColor Red
        $esxihost.system.settings.advanced.list.Invoke(@{option = "/LSOM/lsomPlogZeropV2" }) | Select-Object -Property Description, IntValue
        $value = $esxihost.system.settings.advanced.list.Invoke(@{option = "/LSOM/lsomPlogZeropV2" }) | Select-Object -Property IntValue
        $value = 1
        if ($value) {
            $esxihost.system.settings.advanced.Set.Invoke(@{option = "/LSOM/lsomPlogZeropV2"; intvalue = 0 })

            Write-Host = $esxihost.VMHost "/LSOM/lsomPlogZeropV2" -ForegroundColor cyan
            $esxihost.system.settings.advanced.list.Invoke(@{option = "/LSOM/lsomPlogZeropV2" }) | Select-Object -Property Description, IntValue
        }
         
    }





}

Get-lsomPlogZeropV2 -vcsaparameters $vcsaparams
