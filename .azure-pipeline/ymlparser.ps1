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
echo "##vso[task.setvariable variable=cloud;isOutput=true]$cloudVal"
echo "##vso[task.setvariable variable=accountType;isOutput=true]$accountTypeVal"
echo "##vso[task.setvariable variable=customerName;isOutput=true]$customerNameVal"
echo "##vso[task.setvariable variable=accountName;isOutput=true]$accountNameVal"
echo "##vso[task.setvariable variable=location;isOutput=true]'$locationVal"
echo "##vso[task.setvariable variable=email;isOutput=true]'$emailVal"
echo "##vso[task.setvariable variable=userName;isOutput=true]$userNameVal"
