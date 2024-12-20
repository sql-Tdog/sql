az login
        
$policies = @()
#get the right subscription based on domain:
$domain = "TKAD" 
if ($domain -in "ADINTR2", "TKAD") {
    $subscriptionName = "Microservices"
} else {
    $subscriptionName = "Microservices-Prod-2"
}
if ($subscriptionName) {
    Set-AzContext -Subscription $subscriptionName | Out-Null
    $resourceGroups = Get-AzResourceGroup
    foreach ($resourceGroup in $resourceGroups) {
        $instances = Get-AzSqlInstance -ResourceGroupName $resourceGroup.ResourceGroupName -WarningAction:SilentlyContinue
        foreach ($instance in $instances) {
            $databases = $instance | Get-AzSqlInstanceDatabase
            foreach ($database in $databases) {
                $policy = Get-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy -ResourceGroupName $database.ResourceGroupName -InstanceName $database.ManagedInstanceName -DatabaseName $database.Name
                if (-not $policy) {
                    Write-Warning "Resource group [$($database.ResourceGroupName)] Instance [$($database.ManagedInstanceName)] Database [$($database.Name)] short term backup policy does not exist"
                    $policy += [PSCustomObject] @{
                        ResourceGroupName = $database.ResourceGroupName
                        InstanceName      = $database.ManagedInstanceName
                        DatabaseName      = $database.Name
                        DeletionDate      = $null
                        RetentionDays     = $null
                    }
                } elseif ($policy.RetentionDays -ne 21) {
                    Write-Warning "Resource group [$($database.ResourceGroupName)] Instance [$($database.ManagedInstanceName)] Database [$($database.Name)] short term backup policy days are [$($policy.RetentionDays)] instead of [21]"
                    $policies += $policy
                } else {
                    $policies += $policy
                }
            }
        }
    }
}
$policies | Add-Member -MemberType NoteProperty -Name DateChecked -Value ([DateTimeOffset]::Now) -PassThru | Format-Table -AutoSize
}

