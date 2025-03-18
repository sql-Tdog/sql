DECLARE @stmt nvarchar(max);
DECLARE @mail_profile varchar(300)=(SELECT TOP 1 name FROM msdb.dbo.sysmail_profile);
DECLARE @recipient_emails varchar(600)='tnikolaychuk@centene.com';
DECLARE @subject varchar(1000);
EXEC msdb.dbo.sp_start_job 'DBA_WhoIsActive';
WAITFOR DELAY '00:00:05'

DECLARE @exempt_users varchar(max)='''sa'',''CENTENE\mfeeser'',''NT AUTHORITY\SYSTEM'',''CENTENE\reports'',
	''CENTENE\TNIKOLAYCHUK'',''SSRS_User'',''CENTENE\USSFOGLIGHT''';
DECLARE @collection_time datetime=(SELECT TOP 1 collection_time FROM master.dbo.whoisactive order by collection_time desc);
DECLARE @run_time nchar(4);
DECLARE @search nvarchar(max)='SELECT @runT=MAX(convert(int,substring([dd hh:mm:ss.mss],4,2))*60+convert(int,substring([dd hh:mm:ss.mss],7,2))) 
	FROM master.dbo.whoisactive 
	WHERE convert(nvarchar(40),collection_time)='''+convert(nvarchar(40),@collection_time) +''' AND login_name 
	NOT IN ('+@exempt_users+') AND 	len(login_name)>3';
EXECUTE sp_executesql @search, N'@runT nchar(4) OUTPUT', @runT=@run_time OUTPUT;


IF (SELECT datediff(minute,last_batch,getdate()) FROM sys.sysprocesses where loginame='pbm_link')>30 BEGIN
	SET @stmt='KILL ' + (SELECT TOP 1 convert(varchar(4),spid) FROM sys.sysprocesses where loginame='pbm_link');
	EXECUTE sp_executesql @stmt;
	SET @stmt='Running the following statement to kill an inactive session with an open transaction: '+@stmt;
	SET @subject =(SELECT 'Killing pbm_link on '+ @@SERVERNAME);
	EXEC msdb.dbo.sp_send_dbmail 
		@profile_name=@mail_profile, 
		@recipients=@recipient_emails,
		@subject=@subject,
		@body=@stmt;

END ELSE IF @run_time>120  BEGIN
		DECLARE @user nvarchar(50);
		Declare @runtime varchar(4);
		SET @search=('SELECT TOP 1 @login=login_name FROM master.dbo.whoisactive WHERE convert(nvarchar(40),collection_time)='''+
			convert(nvarchar(40),@collection_time) +''' AND login_name 	NOT IN ('+@exempt_users+') AND 	len(login_name)>3 ORDER BY [dd hh:mm:ss.mss] DESC');
		EXECUTE sp_executesql @search, N'@login nvarchar(50) OUTPUT', @login=@user OUTPUT;
		DECLARE @spid nchar(4);
		SET @search=('SELECT TOP 1 @id=session_id FROM master.dbo.whoisactive WHERE convert(nvarchar(40),collection_time)='''+
			convert(nvarchar(40),@collection_time) +''' AND login_name 	NOT IN ('+@exempt_users+') AND 	len(login_name)>3 ORDER BY [dd hh:mm:ss.mss] DESC');
		EXECUTE sp_executesql @search, N'@id nchar(4) OUTPUT', @id=@spid OUTPUT;
		IF @spid>50 BEGIN
			SET @stmt='KILL ' + @spid;
			EXECUTE sp_executesql @stmt;
			SET @stmt='Running the following statement to kill an long running user query: '+@stmt +'.  User:  '+@user +'. Run time (min): '+@run_time;
			SET @subject='Killing user query on '+@@SERVERNAME;
			EXEC msdb.dbo.sp_send_dbmail 
				@profile_name=@mail_profile, 
				@recipients=@recipient_emails,
				@subject=@subject,
				@body=@stmt;
		END

END ELSE IF datepart(hour,getdate()) between 9 and 21 BEGIN
	IF @run_time>30 BEGIN
			DECLARE @tableHTML  NVARCHAR(MAX) ;  
  
			SET @tableHTML =  
				N'<H1>Transactions</H1>' +  
				N'<table border="1">' +  
				N'<tr><th>Database Name</th><th>Run Time (min)</th><th>Login</th>' +  
				N'<th>Stmt</th><th>Wait Type</th></tr>' +  
				CAST ((SELECT   td = database_name, '',
								td = [dd hh:mm:ss.mss], '',
								td = login_name, '',
								td = sql_text, '',
								td = wait_info
					FROM master.dbo.whoisactive WHERE convert(nvarchar(40),collection_time)=convert(nvarchar(40),@collection_time)
						FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX))+ N'</table>';

			SET @subject = 'Long Running Transaction Details on '+@@SERVERNAME;
			EXEC msdb.dbo.sp_send_dbmail 
					@profile_name=@mail_profile, 
					@recipients=@recipient_emails,
					@body_format='html',
					@body=@tableHTML,
					@subject=@subject
	END
END

