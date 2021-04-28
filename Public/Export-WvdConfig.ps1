function Export-WvdConfig {
    <#
    .SYNOPSIS
    Exports the WVD environment, based on the hostpool name.
    .DESCRIPTION
    The function will help you exporting the complete WVD environment to common output types as HTML and CSV.
    .PARAMETER HostpoolName
    Enter the WVD hostpoolname name.
    .PARAMETER ResourceGroupName
    Enter the WVD hostpool resource group name.
    .PARAMETER FileName
    Enter the filename. Based on the format parameter the function will create a correct file. Default filepath is in the execution directory.
    .PARAMETER Format
    Enter the format you like. For creating more formats use a comma. 
    .EXAMPLE
    Export-WvdConfig -Hostpoolname wvd-hostpool-001 -ResourceGroupName rg-wvd-001 -Format HTML -Verbose -Filename WVDExport
    .EXAMPLE
    Export-WvdConfig -HostPoolName wvd-hostpool-001 -ResourceGroupName rg-wvd-001 -Format HTML,JSON -Verbose -Filename WVDExport
    
    #>
    [CmdletBinding(DefaultParameterSetName = 'Hostpool')]
    param (
        [parameter(Mandatory, ParameterSetName = 'Hostpool')]
        [ValidateNotNullOrEmpty()]
        [string]$HostpoolName,

        [parameter(Mandatory, ParameterSetName = 'Hostpool')]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName,

        [parameter(Mandatory)]
        [string]$FileName,

        [parameter(Mandatory)]
        [ValidateSet("JSON", "HTML", "XLSX")]
        [array]$Format
    )

    Begin {
        Write-Verbose "Start searching"
        AuthenticationCheck
    }
    Process {
        $Parameters = @{
            HostpoolName      = $HostpoolName 
            ResourceGroupName = $ResourceGroupName 
        }
        $Content = [ordered]@{
            Hostpool     = Get-WvdHostPoolInfo @Parameters | Select-Object hostpoolName, hostpoolDescription, hostpoolLocation, resourceGroupName, resourceGroupLocation, domain, startVMOnConnect, expirationTime, validationEnvironment
            SessionHosts = Get-WvdImageVersionStatus @Parameters | Select-Object vmLatestVersion, vmName, resourceGroup, LastVersion, currentImageVersion, imageName, imageGallery, subscriptionId
            Network      = Get-WvdNetworkInfo @Parameters | Select-Object vmName, vmResourceGroup, ipAddress, nicName, nsgName, subnetName
        }
        $Format | foreach { Generate-Output -Format $_ -Content $Content -FileName $FileName -Hostpoolname $HostpoolName }
    }
    End {
    }
}