/*
--Alerts can be set up in SQL based on PerfMon counters in the following 
sys.dm_os_performance_counters DMV
--The permission needed to query this view is VIEW SERVER STATE

select * from sys.dm_os_performance_counters 
where counter_name like '%longest%'

*/


/**On NUMA machines, you need to be looking at the Buffer Node:Page Life Expectancy counters for 
all NUMA nodes otherwise you’re not getting an accurate view of buffer pool memory pressure and 
so could be missing or overreacting to performance issues. 

*/

SELECT * FROM sys.dm_os_performance_counters WHERE [counter_name] = 'Page life expectancy' --should be 300+


/*
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

	 	 If that’s happening, then either  the SQL Server’s memory is being adjusted dynamically (probably a bad idea for performance) or users are actively logging into the 
	 SQL Server  via remote desktop and running software.  Correlate these fluctuations with disk activity: when available memory drops, is disk activity also  increasing? 
	 Is this disk activity affecting the page file drive? If so, this is a demonstration of people using remote desktop.
	 If the value dips below 100mb, that’s an indication that the operating system may be getting starved for memory. Windows may be paging out your application to disk in 
	 order to keep some breathing room free for the OS


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

Paging File
	• % Usage: the amount of the page file instance in use in percent; generally speaking, you don't want to see SQL server swapping memory out to disk.  If this number is
	 averaging 1% or more, then this server would benefit from more memory or setting SQL to use less memory

Physical or Logical Disk
If average of one of the following counters is larger than 20 ms or max is over 30ms, the disk is over-loaded and disk bottleneck analysis must be performed: 
		? Disk sec/read
		? Disk sec/Write
		? Disk sec/Transfer

	• % Disk Time: % of elapsed time that the selected disk drive was busy servicing read/write requests; if greater than 50%, then there is an I/O bottleneck on disk

	• Ave Disk sec/Read: average time, in seconds, of a read of data from the disk
	• Disk Reads/sec: rate of read operations on the disk
	• Ave Disk Queue Length: the average number of both read and write requests that were queued for the selected disk during the sample interval, should be less than 2


	• Current Disk Queue Length
	• Disk Bytes/sec: the rate bytes are transferred to or from the disk during write/read operations, should be 300-400MB on average

	• Split IO/sec: the rate at which I/Os to the disk were split into multiple I/Os.  A split I/O may result from requesting data of a size that is too large to fit into a
	 single I/O or that the disk is fragmented.


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

System
	• Processor Queue Length: number of threads in the processor queue; ready threads only, not threads that are running.  There is a single queue for processors time even 
	on computers with multiple processors.  Therefore, if a computer has multiple processors, you need to divide this value by the number of processors servicing the workload.		
	If this number is averaging 1 or higher (except during the SQL Server’s  full backup window if you’re using backup compression), this means things are waiting on CPUs to 
	become available.


***/