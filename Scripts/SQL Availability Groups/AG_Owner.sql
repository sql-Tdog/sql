SELECT  QUOTENAME(ag.name) AS AvailabilityGroupName,
        QUOTENAME(SUSER_SNAME(0x01)) AS ExpectedOwner,
        QUOTENAME(sp.name) AS ActualOwner,
        dhars.role_desc AS RoleDescription, is_distributed
FROM    sys.availability_replicas ar
JOIN    sys.availability_groups ag
ON      ar.group_id = ag.group_id
JOIN    sys.dm_hadr_availability_replica_states dhars
ON      ar.replica_id = dhars.replica_id
AND     ag.group_id = dhars.group_id
LEFT JOIN sys.server_principals sp
ON      ar.owner_sid = sp.sid
WHERE   dhars.is_local = 1


--change owner of the AG:
ALTER AUTHORIZATION ON AVAILABILITY GROUP::$AGname1 TO [sa]


--view existing endpoints and their owners:
SELECT  SUSER_NAME(principal_id) AS endpoint_owner, name AS endpoint_name, state_desc
FROM sys.database_mirroring_endpoints;


ALTER AUTHORIZATION ON ENDPOINT::Hadr_endpoint TO [CORP\Owner$];