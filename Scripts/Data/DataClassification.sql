/**--introduced in SQL Server 2019:  Data Discovery and Classification


*/
--view stored classification information
SELECT * FROM sys.extended_properties;

--to view all columns with sensitivity labels:
SELECT schema_name(O.schema_id) schema_name, O.name Table_Name, C.Name Column_Name, information_type, sensitivity_Label
	FROM (SELECT IT.major_id, IT.minor_id, IT.information_type, L.sensitivity_label FROM (
		SELECT major_id, minor_id, value AS information_type FROM sys.extended_properties WHERE NAME='sys.information_type_name' ) IT
		FULL OUTER JOIN ( SELECT major_id, minor_id, value AS sensitivity_label FROM sys.extended_properties WHERE NAME='sys_sensitivity_label_name') L
		ON IT.major_id=L.major_id AND IT.minor_id=L.minor_id ) EP
	JOIN sys.objects O ON EP.major_id=O.object_id
	JOIN sys.columns C ON C.object_id=EP.major_id AND EP.minor_id=C.column_id


SELECT * FROM sys.sensitivity_classifications;

