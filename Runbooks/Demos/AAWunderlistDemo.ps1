# ---------------------------------------------------
# Script: C:\Users\Stefan\Documents\GitHub\AzureAutomationDemo\Runbooks\Demos\AAWunderlistDemo.ps1
# Tags: Azure, AzureAutomation, Automation, PowerShell, Runbook
# Version: 0.1
# Author: Stefan Stranger
# Date: 08/08/2016 15:04:45
# Description: Azure Automation Runbook which checks for running VM and creates a Wunderlist Task if WM
#              is running.
# Comments:
# Changes:  
# Disclaimer: 
# This example is provided “AS IS” with no warranty expressed or implied. Run at your own risk. 
# **Always test in your lab first**  Do this at your own risk!! 
# The author will not be held responsible for any damage you incur when making these changes!
# ---------------------------------------------------

#region variables
$connectionName = "AzureRunAsConnection"
$ClientID = Get-AutomationVariable -Name "ClientID"
$AccessToken = Get-AutomationVariable -Name "AccessToken"
#endregion

#The PowerShell Wunderlist Module can use environment variables as input.
$Env:ClientID = $ClientID 
$Env:AccessToken = $AccessToken


#region Connect to Azure Automation Account

try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

#endregion 

#region Check Azure VMs in Each Resource Group

$ResourceGroups = Get-AzureRmResourceGroup 

foreach ($ResourceGroup in $ResourceGroups)
{
    $VMs = Get-AzureRmVM -ResourceGroupName $ResourceGroup.ResourceGroupName
    foreach($VM in $VMs)
    {
           $VMStatus = Get-AzureRmVM -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName -Status
           If (($VMStatus.Statuses[1].DisplayStatus) -ne "VM deallocated") 
            {       

                [string]$message =  "$($vm.name)" + " status is " + "$($VMStatus.Statuses[1].DisplayStatus)"               
                Write-Output  -InputObject $message
                #Create Wunderlist task for inbox (your listid may be different!)
                New-WunderlistTask -listid 122588396 -title $($message)
            }  
    }
}
#endregion

