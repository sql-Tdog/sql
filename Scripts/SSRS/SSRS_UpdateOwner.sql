use reportserver
go

DECLARE @OldUserID uniqueidentifier
DECLARE @NewUserID uniqueidentifier
SELECT @OldUserID = UserID FROM dbo.Users WHERE UserName = 'HBEXSQLPRODM\ReportUser'
SELECT @NewUserID = UserID FROM dbo.Users WHERE UserName = 'RHASQLPROD\Rhaadmin'

SELECT * FROM  dbo.Users WHERE UserName IN( 'RHASQLPROD\Rhaadmin','HBEXSQLPRODM\ReportUser')
SELECT * FROM dbo.Subscriptions WHERE OwnerID=@NewUserID

BEGIN TRANSACTION

SELECT @@TRANCOUNT

UPDATE dbo.Subscriptions SET OwnerID = @NewUserID WHERE OwnerID = @OldUserID

ROLLBACK

COMMIT TRANSACTION