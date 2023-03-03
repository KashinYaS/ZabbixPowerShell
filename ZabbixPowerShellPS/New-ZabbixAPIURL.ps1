Function New-ZabbixAPIURL {
  [CmdletBinding(DefaultParameterSetName="Default")]
  PARAM (
    [PARAMETER(Mandatory=$True, Position=0, HelpMessage = "Zabbix FQDN or IP address", ParameterSetName='Default')][PARAMETER(ParameterSetName='ID')][PARAMETER(ParameterSetName='Name')][String]$Zabbix=''	
  )
  $RetVal = $Zabbix
  
  if ($RetVal -notmatch '^(http)s?://.+$') {
    $RetVal = 'https://' + $RetVal
  }
  
  if ($RetVal -notmatch '^.+/api_jsonrpc.php$') {
    if ($RetVal -like '*/') {
	  $RetVal += 'api_jsonrpc.php'
	}`
	else {
	  $RetVal += '/api_jsonrpc.php'
	}
  }  
  Return($RetVal)
}

