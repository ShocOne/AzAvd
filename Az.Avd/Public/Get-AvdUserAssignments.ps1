function Get-AvdUserAssignments {
    <#
    .SYNOPSIS
    Searches for session host and its assignments.
    .DESCRIPTION
    This function will search all the sessionhost from a specific Azure Virtual Desktop hostpool regarding a user assignment.
    .PARAMETER HostpoolName
    Enter the AVD Hostpool name
    .PARAMETER ResourceGroupName
    Enter the AVD Hostpool resourcegroup name
    .PARAMETER SessionHostName
    Enter the sessionhosts name
    .PARAMETER LoginName
    Enter the user principal name
    .EXAMPLE
    Get-AvdUserAssignments -HostpoolName avd-hostpool-personal -ResourceGroupName rg-avd-01 -SessionHostName avd-host-1.avd.domain
    .EXAMPLE
    Get-AvdUserAssignments -HostpoolName avd-hostpool-personal -ResourceGroupName rg-avd-01 -SessionHostName avd-host-1.avd.domain -LoginName user@domain.com
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param
    (
        [parameter(Mandatory, ParameterSetName = 'All')]
        [parameter(Mandatory, ParameterSetName = 'Hostname')]
        [ValidateNotNullOrEmpty()]
        [string]$HostpoolName,

        [parameter(Mandatory, ParameterSetName = 'All')]
        [parameter(Mandatory, ParameterSetName = 'Hostname')]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName,

        [parameter(Mandatory, ParameterSetName = 'Hostname')]
        [ValidateNotNullOrEmpty()]
        [string]$SessionHostName,

        [parameter(ParameterSetName = 'All')]
        [parameter(ParameterSetName = 'Hostname')]
        [ValidateNotNullOrEmpty()]
        [string]$LoginName,

        [parameter(ParameterSetName = 'Id')]
        [string]$SessionHostId
    )
    Begin {
        Write-Verbose "Start searching session hosts"
        AuthenticationCheck
        $token = GetAuthToken -resource $global:AzureApiUrl
        $baseUrl = $global:AzureApiUrl + "/subscriptions/" + $global:subscriptionId + "/resourceGroups/" + $ResourceGroupName + "/providers/Microsoft.DesktopVirtualization/hostpools/" + $HostpoolName + "/sessionHosts/"
        $apiVersion = "?api-version=2022-02-10-preview"
    }
    Process {
        switch ($PsCmdlet.ParameterSetName) {
            All {
                Write-Verbose "Searching for all sessions in $hostpoolName"
                $SessionHostNames = Get-AvdSessionHost -HostpoolName $hostpoolName -ResourceGroupName $ResourceGroupName
                $sessionHostUrl = [System.Collections.ArrayList]@()
                $SessionHostNames | ForEach-Object {
                    $url = "{0}{1}" -f $global:AzureApiUrl, $_.id
                    $sessionHostUrl.Add($url) | Out-Null
                }
            }
            Hostname {
                Write-Verbose "Looking for sessionhost $SessionHostName"
                $sessionHostUrl = "{0}{1}" -f $baseUrl, $SessionHostName
            }
            Id {
                Write-Verbose "Looking for sessionhost on ID $SessionHostId"
                $sessionHostUrl = "{0}{1}" -f $global:AzureApiUrl, $SessionHostId
            }

        }
        try {
            $sessionHostUrl | ForEach-Object {
                Write-Verbose "Looking for assignments at $($_.Split("/")[-2])"
                $parameters = @{
                    uri     = "{0}{1}" -f $_, $apiVersion
                    Method  = "GET"
                    Headers = $token
                }

                $assignmentList = [System.Collections.ArrayList]@()
                $assignmentList.Add((Request-Api @parameters)) | Out-Null
            }
            if ($LoginName) {
                $specificHosts = [System.Collections.ArrayList]@()
                Write-Verbose "Searching for user with UPN $LoginName"
                $assignmentList.ForEach({
                   $assignedHost = $_ | Where-Object { $_.Properties.assignedUser -eq $LoginName }
                   $specificHosts.Add($assignedHost) | Out-Null
                })
                if ($null -eq $assignmentList) {
                    Write-Information "User assigned user found with $LoginName at any session host in hostpool $HostpoolName"
                }
                else {
                    $specificHosts
                }
            }
            else {
                $assignmentList
            }
        }
        catch {
            "No sessions found. $_"
        }
    }
}