Function Get-ZabbixHostGroup {
  [CmdletBinding(DefaultParameterSetName="Default")]
  PARAM (
    [PARAMETER(Mandatory=$True, Position=0,HelpMessage = "Zabbix FQDN or IP address",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][PARAMETER(ParameterSetName='HostID')][String]$Zabbix,	
    [PARAMETER(Mandatory=$True, Position=1,HelpMessage = "Username",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][PARAMETER(ParameterSetName='HostID')][String]$Username,
    [PARAMETER(Mandatory=$True, Position=2,HelpMessage = "Password",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][PARAMETER(ParameterSetName='HostID')][String]$Password,
    [PARAMETER(Mandatory=$False,Position=3,HelpMessage = "Silent - if set then function will not show error messages",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][PARAMETER(ParameterSetName='HostID')][bool]$Silent=$false,
	[PARAMETER(Mandatory=$True, Position=4,HelpMessage = "Group Id",ParameterSetName='ID')][int[]]$ID = $null,
	[PARAMETER(Mandatory=$True, Position=4,HelpMessage = "Host Id to get host's group only",ParameterSetName='HostID')][int[]]$HostID = $null,
	[PARAMETER(Mandatory=$True, Position=4,HelpMessage = "Group Name",ParameterSetName='Name')][String[]]$Name = $null
  )
  $RetVal = $null
 
  $AuthToken = ''
  $UserLoginJSON = @{
    "jsonrpc"= "2.0"
    "method"= "user.login"
    "params"= @{
        user = "$($Username)"
        password = "$($Password)"
    }
	auth = $null
    id = Get-Random
  } | ConvertTo-Json -Depth 5

  try { 
    $RM = Invoke-RestMethod -Method "POST" -Uri "$($Zabbix)" -ContentType "application/json" -Body $UserLoginJSON
    if ($RM.Result -and ($RM.Result -match '^[A-F0-9]{32}$')) {   
      $AuthToken = $RM.Result

	  switch ( $PSCmdlet.ParameterSetName )
      {
        'ID' {
	      $HostGroupJSON = @{
            "jsonrpc"= "2.0"
            "method"= "hostgroup.get"
            "params"= @{
			  filter = @{hostid=[array]$ID}
              output = "extend"
            }
            auth = $AuthToken
            id = Get-Random
          } | ConvertTo-Json -Depth 5
	    }
        'HostID' {
	      $HostGroupJSON = @{
            "jsonrpc"= "2.0"
            "method"= "hostgroup.get"
            "params"= @{
			  hostids = [array]$HostID
              output = "extend"
            }
            auth = $AuthToken
            id = Get-Random
          } | ConvertTo-Json -Depth 5
	    }
        'Name' {
	      $HostGroupJSON = @{
            "jsonrpc"= "2.0"
            "method"= "hostgroup.get"
            "params"= @{
			  filter = @{host=[array]$Name}
              output = "extend"
            }
            auth = $AuthToken
            id = Get-Random
          } | ConvertTo-Json -Depth 5
	    }
	    default { 
	      $HostGroupJSON = @{
            "jsonrpc"= "2.0"
            "method"= "hostgroup.get"
            "params"= @{
              output = "extend"
            }
            auth = $AuthToken
            id = Get-Random
          } | ConvertTo-Json -Depth 5
        }
      }
      
	  #$HostGroupJSON
	  
	  $RM = Invoke-RestMethod -Method "POST" -Uri "$($Zabbix)" -ContentType "application/json" -Body $HostGroupJSON
	  if ($RM.PSObject.Properties.Match('Result')) {
	    $RetVal = $RM.Result
	  }`
      else {
	    if (-not $Silent) {
	      write-host "ERROR (Get-ZabbixHostGroup/Fetching): $($RM.error.code); $($RM.error.message); $($RM.error.data)" -foreground "Red"
	    }
      }	  
      
      $UserLogoffJSON = @{
        "jsonrpc"= "2.0"
        "method"= "user.logout"
        "params"= @{
        }
	    auth = "$($AuthToken)"
        id = Get-Random
      } | ConvertTo-Json -Depth 5
      $RM = Invoke-RestMethod -Method "POST" -Uri "$($Zabbix)" -ContentType "application/json" -Body $UserLogoffJSON	 

    }`
    else {
	  if (-not $Silent) {
	    write-host "ERROR (Get-ZabbixHostGroup/Login): $($RM.error.code); $($RM.error.message); $($RM.error.data)" -foreground "Red"
	  }
    }
  }`	
  catch {
	$ExceptionDetails = $_.Exception
	if (-not $Silent) {
	  write-host "ERROR (Get-ZabbixHostGroup): $ExceptionDetails" -foreground "Red"
	}	 
  }
  
  Return($RetVal)
}

