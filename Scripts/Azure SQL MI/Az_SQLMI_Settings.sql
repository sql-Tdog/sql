--SQL MI:

select DATABASEPROPERTYEX('DatabaseName', 'Updateability')




SELECT configuration_id, name, value, value_for_secondary  
FROM sys.database_scoped_configurations;

