
select * from pbiods1 order by [SQLServer:General Statistics\User Connections]

/**
--modify imported table to make analysis easier:
delete from pbiods1 where [time] is null or [memory\pages/sec] is null
alter table pbiods1 alter column [time] datetime not null
alter table pbiods1 add primary key ([time])
alter table pbiods1 add id int identity not null

--find non-peak hours:
SELECT max([SQLServer:General Statistics\User Connections]),min([SQLServer:General Statistics\User Connections]),avg([SQLServer:General Statistics\User Connections])
FROM pbiods1



Memory
	• Pages/sec:  the rate at which pages are read from or written to disk to resolve hard page faults.  Average should be below 50.  It's not possible to reduce the value to 0,
	 as moving pages from memory and to memory always occurs while the operating system is running.  The more memory the server has, the fewer pages have to written and read due
	  to page faults.  
	  
	  SELECT avg([Memory\Pages/sec]) 'average',max([Memory\Pages/sec]) 'max',min([Memory\Pages/sec]) 'min' FROM pbiods1


	  High values indicate intensive memory activity and can indicate insufficient RAM memory.  But can also be caused by sequential reading of a file mapped 
	  in memory.  To determine whether this is the case, check Available Mbytes and Paging File % Usage values.  
	  Occasional peaks are normal and appear when databases and/or logs are being backed up, databases restored, data imported/exported, and other complex tasks are performed.  
	  If value is higher than 50 for 24 hours or longer and at the same time Buffer Hit Cache Ratio is 99% or higher, then other applications are using memory needed by SQL 
	  server.  (get a dedicated server for SQL server)

	  SELECT [Time],[Memory\Pages/sec],[SQLServer:Buffer Manager\Buffer cache hit ratio] FROM pbiods1 where [Memory\Pages/sec]>50 ORDER BY [Time]

	  During this time when other applications are using memory needed by SQL Server, other counters will be affected.

	• Available Mbytes: amount of physical memory available for allocation to a process or for system use.  Look for fluctuations of a couple hundred megabytes or more.

	 SELECT  P.Time t1, P2.Time t2, P.[Memory\Available MBytes], P2.[Memory\Available MBytes], (P2.[Memory\Available MBytes]-P.[Memory\Available MBytes]) AvailableMbytes_Fluctuation
	 ,(P2.[PhysicalDiskC\% Disk Time]-P.[PhysicalDiskC\% Disk Time]) 'DiskCActivityIncrease'
	 ,(P2.[PhysicalDiskE\% Disk Time]-P.[PhysicalDiskE\% Disk Time]) 'DiskEActivityIncrease'
	 ,(P2.[PhysicalDiskH\% Disk Time]-P.[PhysicalDiskH\% Disk Time]) 'DiskHActivityIncrease'
	 ,(P2.[PhysicalDiskTotal\% Disk Time]-P.[PhysicalDiskTotal\% Disk Time]) 'DiskTotalActivityIncrease'
	 ,(P2.[Paging File\% Usage]-P.[Paging File\% Usage]) 'PagingFile%UsageIncrease'
	 FROM pbiods1 P INNER JOIN pbiods1 P2 ON P.Id=(P2.Id)-1 WHERE (P.[Memory\Available MBytes]-P2.[Memory\Available MBytes])>150

	 If that’s happening, then either  the SQL Server’s memory is being adjusted dynamically (probably a bad idea for performance) or users are actively logging into the 
	 SQL Server  via remote desktop and running software.  Correlate these fluctuations with disk activity: when available memory drops, is disk activity also  increasing? 
	 Is this disk activity affecting the page file drive? If so, this is a demonstration of people using remote desktop.
	 If the value dips below 100mb, that’s an indication that the operating system may be getting starved for memory. Windows may be paging out your application to disk in 
	 order to keep some breathing room free for the OS.

	 SELECT [Time],[Memory\Available MBytes] FROM pbiods1 WHERE [Memory\Available MBytes]<100


	• Page Faults/sec: When a page fault is encountered, the program execution stops and is set to the wait state.  The OS searches for the requested address on the disk.  
	When the page is found, the OS copies it from disk into a free RAM page and the OS allows the program to continue with the execution.
	There are two types of page faults – hard and soft page faults. Hard page faults occur when the requested page is not in the physical memory. Soft page faults occur when 
	the requested page is in memory, but cannot be accessed by the program as it is not on the right address, or is being accessed by another program
	Monitoring page faults is important as excessive hard page faults affect application performance. Soft page faults cause no performance issues. The Page faults/sec counter 
	shows both hard and soft page faults, so it can be difficult to determine whether the page faults value indicates performance problems in SQL Server, and should be 
	addressed, or presents a normal state
	There is no specific Page faults/sec value that indicates performance problems. Monitoring Page faults/sec should provide enough information to create a baseline that will 
	be used to determine normal server performance. The normal values are 10 to 15, but even 1,000 page faults per second can be normal in specific environments. The value 
	depends on the type and amount of memory, and the speed of disk access. A sustained or increasing value for Page faults/sec can indicate insufficient memory. If this is 
	the case, check the Page reads/sec value, as it also indicates hard page faults. If the latter is also high, it indicates insufficient memory on the machine
	
	SELECT avg([Memory\Page Faults/sec])'Avg PageFaults/sec', avg([Memory\Page Reads/sec])'Avg PageReads/sec' ,
	max([Memory\Page Faults/sec])'Max PageFaults/sec', max([Memory\Page Reads/sec])'Max PageReads/sec',
	min([Memory\Page Faults/sec])'Min PageFaults/sec', min([Memory\Page Reads/sec])'Min PageReads/sec'
	FROM pbiods1

	SELECT [Time],[Memory\Page Reads/sec],[Memory\Page Faults/sec] FROM pbiods1 WHERE [Memory\Page Reads/sec]>2 ORDER BY [Time]

Paging File
	• % Usage: the amount of the page file instance in use in percent; generally speaking, you don't want to see SQL server swapping memory out to disk.  If this number is
	 averaging 1% or more, then this server would benefit from more memory or setting SQL to use less memory
	 SELECT avg([Paging File\% Usage]) 'average',max([Paging File\% Usage]) 'max' FROM pbiods1
	 SELECT [Time], [Paging File\% Usage] FROM pbiods1 WHERE [Paging File\% Usage]>1

Physical or Logical Disk
If average of one of the following counters is larger than 20 ms or max is over 30ms, the disk is over-loaded and disk bottleneck analysis must be performed: 
		? Disk sec/read
		? Disk sec/Write
		? Disk sec/Transfer
		SELECT avg([PhysicalDiskC\Avg# Disk sec/Read])*1000 DiskC,avg([PhysicalDiskE\Avg# Disk sec/Read])*1000 DiskE,avg([PhysicalDiskH\Avg# Disk sec/Read])*1000 DiskH
		FROM pbiods1

		SELECT avg([PhysicalDiskC\Avg# Disk sec/Write])*1000 DiskC,avg([PhysicalDiskE\Avg# Disk sec/Write])*1000 DiskE,avg([PhysicalDiskH\Avg# Disk sec/Write])*1000 DiskH
		FROM pbiods1

		SELECT avg([PhysicalDiskC\Avg# Disk sec/Transfer])*1000 DiskC,avg([PhysicalDiskE\Avg# Disk sec/Transfer])*1000 DiskE,avg([PhysicalDiskH\Avg# Disk sec/Transfer])*1000 DiskH
		FROM pbiods1


	• % Disk Time: % of elapsed time that the selected disk drive was busy servicing read/write requests; if greater than 50%, then there is an I/O bottleneck on disk
	SELECT avg([PhysicalDiskC\% Disk Time])DiskC, avg([PhysicalDiskE\% Disk Time])DiskE, avg([PhysicalDiskH\% Disk Time])DiskH FROM pbiods1

	• Ave Disk sec/Read: average time, in seconds, of a read of data from the disk
	• Disk Reads/sec: rate of read operations on the disk
	• Ave Disk Queue Length: the average number of both read and write requests that were queued for the selected disk during the sample interval, should be less than 2
	SELECT avg([LogicalDiskC\Avg# Disk Queue Length])DiskC, avg([LogicalDiskE\Avg# Disk Queue Length])DiskE, avg([LogicalDiskH\Avg# Disk Queue Length])DiskH 
	FROM pbiods1

	• Current Disk Queue Length
	• Disk Bytes/sec: the rate bytes are transferred to or from the disk during write/read operations, should be 300-400MB on average
	SELECT avg([LogicalDiskC\Disk Bytes/sec])/1024/1024 DiskCAvg, avg([LogicalDiskE\Disk Bytes/sec])/1024/1024 DiskEAvg, avg([LogicalDiskH\Disk Bytes/sec])/1024/1024 DiskHAvg,
	max([LogicalDiskC\Disk Bytes/sec])/1024/1024 DiskCMax, max([LogicalDiskE\Disk Bytes/sec])/1024/1024 DiskEMax, max([LogicalDiskH\Disk Bytes/sec])/1024/1024 DiskHMax
	FROM pbiods1

	• Split IO/sec: the rate at which I/Os to the disk were split into multiple I/Os.  A split I/O may result from requesting data of a size that is too large to fit into a
	 single I/O or that the disk is fragmented.
	 SELECT avg([LogicalDiskC\Split IO/Sec])DiskC,avg([LogicalDiskE\Split IO/Sec])DiskE,avg([LogicalDiskH\Split IO/Sec])DiskH
	 FROM pbiods1

Process
	• Private Bytes: The current size of memory that this process has allocated that cannot be shared with other processes
	• Working Set: the set of memory pages touched recently by the threads in the process.  If free memory in the computer is above a threshold, pages are left in the working
	 set of a process even if they are not in use.  When free memory falls below a threshold, pages are trimmed from working sets.  If they are needed, they will be soft-faulted 
	 back into the working set before leaving main memory.

Processor
	• % Processor Time
	
SQL Server
	• Buffer Manager\Page life expectancy:
	• General Statistics\User Connections
	• Memory Manager
		? Memory Grants:
		? Total Server Memory
	• SQL Statistics
		? Batch Requests/sec:
		? SQL Compilations/sec
		? SQL Re-Complications/sec
	SELECT avg([SQLServer:SQL Statistics\SQL Compilations/sec])'Compilations/sec', avg([SQLServer:SQL Statistics\SQL Re-Compilations/sec])'Re-Compilations/sec' 
	FROm pbiods1

System
	• Processor Queue Length: number of threads in the processor queue; ready threads only, not threads that are running.  There is a single queue for processors time even 
	on computers with multiple processors.  Therefore, if a computer has multiple processors, you need to divide this value by the number of processors servicing the workload.		
	If this number is averaging 1 or higher (except during the SQL Server’s  full backup window if you’re using backup compression), this means things are waiting on CPUs to 
	become available.


***/