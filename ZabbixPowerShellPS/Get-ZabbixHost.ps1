Function Get-ZabbixHost {
  [CmdletBinding(DefaultParameterSetName="Default")]
  PARAM (
    [PARAMETER(Mandatory=$True, Position=0,HelpMessage = "Zabbix FQDN or IP address",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][String]$Zabbix,	
    [PARAMETER(Mandatory=$True, Position=1,HelpMessage = "Username",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][String]$Username,
    [PARAMETER(Mandatory=$True, Position=2,HelpMessage = "Password",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][String]$Password,
    [PARAMETER(Mandatory=$False,Position=3,HelpMessage = "Silent - if set then function will not show error messages",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][bool]$Silent=$false,
    [PARAMETER(Mandatory=$False,Position=4,HelpMessage = "IncludeTemplateID",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][switch]$IncludeTemplateID,
	[PARAMETER(Mandatory=$True, Position=5,HelpMessage = "ID",ParameterSetName='ID')][int[]]$ID = $null,
	[PARAMETER(Mandatory=$True, Position=5,HelpMessage = "Name",ParameterSetName='Name')][String[]]$Name = $null
  )
  $RetVal = $null
 
  $Zabbix = New-ZabbixAPIURL -Zabbix $Zabbix
  
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
	      $HostJSON = @{
            "jsonrpc"= "2.0"
            "method"= "Host.get"
            "params"= @{
			  filter = @{hostid=[array]$ID}
              output = "extend"
            }
            auth = $AuthToken
            id = Get-Random
          } | ConvertTo-Json -Depth 5
	    }
        'Name' {
	      $HostJSON = @{
            "jsonrpc"= "2.0"
            "method"= "Host.get"
            "params"= @{
			  filter = @{host=[array]$Name}
              output = "extend"
            }
            auth = $AuthToken
            id = Get-Random
          } | ConvertTo-Json -Depth 5
	    }
	    default { 
	      $HostJSON = @{
            "jsonrpc"= "2.0"
            "method"= "Host.get"
            "params"= @{
              output = "extend"
            }
            auth = $AuthToken
            id = Get-Random
          } | ConvertTo-Json -Depth 5
        }
      }
      
	  if ($IncludeTemplateID) {
	    $TempHostObj = $HostJSON | ConvertFrom-Json
		$TempHostObj.params |  Add-Member -NotePropertyName 'selectParentTemplates' -NotePropertyValue @('templateid')
		$HostJSON = $TempHostObj | ConvertTo-Json -Depth 5
	  }
	  #$HostJSON
	  
	  $RM = Invoke-RestMethod -Method "POST" -Uri "$($Zabbix)" -ContentType "application/json" -Body $HostJSON
	  if ($RM.PSObject.Properties.Match('Result')) {
	    $RetVal = $RM.Result
	  }`
      else {
	    if (-not $Silent) {
	      write-host "ERROR (Get-ZabbixHost/Fetching): $($RM.error.code); $($RM.error.message); $($RM.error.data)" -foreground "Red"
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
	    write-host "ERROR (Get-ZabbixHost/Login): $($RM.error.code); $($RM.error.message); $($RM.error.data)" -foreground "Red"
	  }
    }
  }`	
  catch {
	$ExceptionDetails = $_.Exception
	if (-not $Silent) {
	  write-host "ERROR (Get-ZabbixHost): $ExceptionDetails" -foreground "Red"
	}	 
  }
  
  Return($RetVal)
}

