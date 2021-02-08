$cloudVal=$args[0]
if ($cloudVal -like 'public'){
    Write-Host '##vso[task.setvariable variable=connectedServiceNameARM;]26e35a82-77e5-49a3-be01-746aa941c154'
    echo "the service is public"
} else {
    Write-Host '##vso[task.setvariable variable=connectedServiceNameARM;]3ae9f719-bb32-4b5e-82c2-7dc5e4d47bcb'
    echo "the service is private"
}