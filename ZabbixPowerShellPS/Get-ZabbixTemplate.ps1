Function Get-ZabbixTemplate {
  [CmdletBinding(DefaultParameterSetName="Default")]
  PARAM (
    [PARAMETER(Mandatory=$True, Position=0,HelpMessage = "Zabbix FQDN or IP address",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][PARAMETER(ParameterSetName='HostID')][String]$Zabbix,	
    [PARAMETER(Mandatory=$True, Position=1,HelpMessage = "Username",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][PARAMETER(ParameterSetName='HostID')][String]$Username,
    [PARAMETER(Mandatory=$True, Position=2,HelpMessage = "Password",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][PARAMETER(ParameterSetName='HostID')][String]$Password,
    [PARAMETER(Mandatory=$False,Position=3,HelpMessage = "Silent - if set then function will not show error messages",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][PARAMETER(ParameterSetName='HostID')][bool]$Silent=$false,
    [PARAMETER(Mandatory=$False,Position=4,HelpMessage = "Include Items",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][switch]$IncludeItems,
    [PARAMETER(Mandatory=$False,Position=5,HelpMessage = "Include Triggers",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][switch]$IncludeTriggers,
    [PARAMETER(Mandatory=$False,Position=6,HelpMessage = "Include Applications",ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][switch]$IncludeApplications,
	[PARAMETER(Mandatory=$True, Position=7,HelpMessage = "Template Id",ParameterSetName='ID')][int[]]$ID = $null,
	[PARAMETER(Mandatory=$True, Position=7,HelpMessage = "Host Id to get host's template only",ParameterSetName='HostID')][int[]]$HostID = $null,
	[PARAMETER(Mandatory=$True, Position=7,HelpMessage = "Template Name",ParameterSetName='Name')][String[]]$Name = $null
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
	      $TemplateJSON = @{
            "jsonrpc"= "2.0"
            "method"= "template.get"
            "params"= @{
			  filter = @{hostid=[array]$ID}
              output = "extend"
            }
            auth = $AuthToken
            id = Get-Random
          } | ConvertTo-Json -Depth 5
	    }
        'HostID' {
	      $TemplateJSON = @{
            "jsonrpc"= "2.0"
            "method"= "template.get"
            "params"= @{
			  hostids = [array]$HostID
              output = "extend"
            }
            auth = $AuthToken
            id = Get-Random
          } | ConvertTo-Json -Depth 5
	    }
        'Name' {
	      $TemplateJSON = @{
            "jsonrpc"= "2.0"
            "method"= "template.get"
            "params"= @{
			  filter = @{host=[array]$Name}
              output = "extend"
            }
            auth = $AuthToken
            id = Get-Random
          } | ConvertTo-Json -Depth 5
	    }
	    default { 
	      $TemplateJSON = @{
            "jsonrpc"= "2.0"
            "method"= "template.get"
            "params"= @{
              output = "extend"
            }
            auth = $AuthToken
            id = Get-Random
          } | ConvertTo-Json -Depth 5
        }
      }
      
	  if ($IncludeItems) {
	    $TempTemplateObj = $TemplateJSON | ConvertFrom-Json
		$TempTemplateObj.params |  Add-Member -NotePropertyName 'selectItems' -NotePropertyValue "extend"
		$TemplateJSON = $TempTemplateObj | ConvertTo-Json -Depth 5
	  }

	  if ($IncludeTriggers) {
	    $TempTemplateObj = $TemplateJSON | ConvertFrom-Json
		$TempTemplateObj.params |  Add-Member -NotePropertyName 'selectTriggers' -NotePropertyValue "extend"
		$TemplateJSON = $TempTemplateObj | ConvertTo-Json -Depth 5
	  }
	  
	  if ($IncludeApplications) {
	    $TempTemplateObj = $TemplateJSON | ConvertFrom-Json
		$TempTemplateObj.params |  Add-Member -NotePropertyName 'selectApplications' -NotePropertyValue "extend"
		$TemplateJSON = $TempTemplateObj | ConvertTo-Json -Depth 5
	  }	  

	  #$TemplateJSON
	  
	  $RM = Invoke-RestMethod -Method "POST" -Uri "$($Zabbix)" -ContentType "application/json" -Body $TemplateJSON
	  if ($RM.PSObject.Properties.Match('Result')) {
	    $RetVal = $RM.Result
	  }`
      else {
	    if (-not $Silent) {
	      write-host "ERROR (Get-ZabbixTemplate/Fetching): $($RM.error.code); $($RM.error.message); $($RM.error.data)" -foreground "Red"
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
	    write-host "ERROR (Get-ZabbixTemplate/Login): $($RM.error.code); $($RM.error.message); $($RM.error.data)" -foreground "Red"
	  }
    }
  }`	
  catch {
	$ExceptionDetails = $_.Exception
	if (-not $Silent) {
	  write-host "ERROR (Get-ZabbixTemplate): $ExceptionDetails" -foreground "Red"
	}	 
  }
  
  Return($RetVal)
}

