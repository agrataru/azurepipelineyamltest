$yamlFileDir=$args[0]
$yamlFileName=$args[1]
#echo "this is the path of the yaml $yamlFileName and $yamlFileName1 this is $PSScriptRoot"
Install-Module -Name FXPSYaml -Scope CurrentUser -Force
Import-Module FXPSYaml
[string[]]$fileContent = Get-Content "$yamlFileDir/$yamlFileName"
$content = ''
foreach ($line in $fileContent) { $content = $content + "`n" + $line }
$yaml = ConvertFrom-YAML $content
$accountTypeVal = $yaml.testconfig.accountType
$customerNameVal = $yaml.testconfig.customerName
$accountNameVal = $yaml.testconfig.accountName
$locationVal = $yaml.testconfig.location
$cloudVal = $yaml.testconfig.cloud
$emailVal = $yaml.testconfig.email
$userNameVal = $yaml.testconfig.userName
Write-Host '##vso[task.setvariable variable=accountType;]'$accountTypeVal
Write-Host '##vso[task.setvariable variable=customerName;]'$customerNameVal
Write-Host '##vso[task.setvariable variable=accountName;]'$accountNameVal
Write-Host '##vso[task.setvariable variable=location;]'$locationVal
Write-Host '##vso[task.setvariable variable=cloud;]'$cloudVal
Write-Host '##vso[task.setvariable variable=email;]'$emailVal
Write-Host '##vso[task.setvariable variable=userName;]'$userNameVal
