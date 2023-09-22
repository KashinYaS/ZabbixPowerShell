Function Get-ZabbixItem {
  [CmdletBinding(DefaultParameterSetName="Default")]
  PARAM (
    [PARAMETER(Mandatory=$True, Position=0,HelpMessage = "Zabbix FQDN or IP address",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][PARAMETER(ParameterSetName='HostID')][String]$Zabbix,	
    [PARAMETER(Mandatory=$True, Position=1,HelpMessage = "Username",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][PARAMETER(ParameterSetName='HostID')][String]$Username,
    [PARAMETER(Mandatory=$True, Position=2,HelpMessage = "Password",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][PARAMETER(ParameterSetName='HostID')][String]$Password,
    [PARAMETER(Mandatory=$False,Position=3,HelpMessage = "Silent - if set then function will not show error messages",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][PARAMETER(ParameterSetName='HostID')][bool]$Silent=$false,
    [PARAMETER(Mandatory=$False,Position=4,HelpMessage = "Include Preprocessing",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][switch]$IncludePreprocessing,
	[PARAMETER(Mandatory=$True, Position=5,HelpMessage = "ID",ParameterSetName='ID')][int[]]$ID = $null,
	[PARAMETER(Mandatory=$True, Position=5,HelpMessage = "Name",ParameterSetName='Name')][String[]]$Name = $null,
	[PARAMETER(Mandatory=$True, Position=5,HelpMessage = "Host ID",ParameterSetName='HostID')][int[]]$HostID = $null
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
	      $ItemJSON = @{
            "jsonrpc"= "2.0"
            "method"= "item.get"
            "params"= @{
			  itemids=[array]$ID
              output = "extend"
            }
            auth = $AuthToken
            id = Get-Random
          } | ConvertTo-Json -Depth 5
	    }
        'Name' {
	      $ItemJSON = @{
            "jsonrpc"= "2.0"
            "method"= "item.get"
            "params"= @{
			  search = @{name=[array]$Name}
              output = "extend"
            }
            auth = $AuthToken
            id = Get-Random
          } | ConvertTo-Json -Depth 5
	    }
        'HostID' {
	      $ItemJSON = @{
            "jsonrpc"= "2.0"
            "method"= "item.get"
            "params"= @{
			  hostids=[array]$HostID
              output = "extend"
            }
            auth = $AuthToken
            id = Get-Random
          } | ConvertTo-Json -Depth 5
	    }
	    default { 
	      $ItemJSON = @{
            "jsonrpc"= "2.0"
            "method"= "item.get"
            "params"= @{
              output = "extend"
            }
            auth = $AuthToken
            id = Get-Random
          } | ConvertTo-Json -Depth 5
        }
      }
      
	  if ($IncludePreprocessing) {
	    $TempItemObj = $ItemJSON | ConvertFrom-Json
		$TempItemObj.params |  Add-Member -NotePropertyName 'selectPreprocessing' -NotePropertyValue "extend"
		$ItemJSON = $TempItemObj | ConvertTo-Json -Depth 5
	  }
	  
	  #$ItemJSON
	  
	  $RM = Invoke-RestMethod -Method "POST" -Uri "$($Zabbix)" -ContentType "application/json" -Body $ItemJSON
	  if ($RM.PSObject.Properties.Match('Result')) {
	    $RetVal = $RM.Result
	  }`
      else {
	    if (-not $Silent) {
	      write-host "ERROR (Get-ZabbixItem/Fetching): $($RM.error.code); $($RM.error.message); $($RM.error.data)" -foreground "Red"
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
	    write-host "ERROR (Get-ZabbixItem/Login): $($RM.error.code); $($RM.error.message); $($RM.error.data)" -foreground "Red"
	  }
    }
  }`	
  catch {
	$ExceptionDetails = $_.Exception
	if (-not $Silent) {
	  write-host "ERROR (Get-ZabbixItem): $ExceptionDetails" -foreground "Red"
	}	 
  }
  
  Return($RetVal)
}

