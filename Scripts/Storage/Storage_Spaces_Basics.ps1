<#
Why use storage spaces?
1.  Administrative simplicity (no need to change logical database file location, just add disks to the pool)
2.  


What do they do?
-Guarantee data to be distributed evenly across all drives
-Do not support disk growth:  human management intervention overhead (add disks or migrate to new pool)

If a VM is in a cluster:
-If a pool is created and then the VM is added to a cluster, then the cluster will want to grab that storage.  Set the flag to disable that.
-The metadata of the storage pool is stamped into the header of the disk newly added to the pool and if the pool is clustered, a disk cannot be removed from it
if it brings the pool of disks to less than 3 disks (3 votes required per cluster)
-If those disks are ever attached to a new node, the metadata will be compared so that we have the ability to move the disks if there is a node failure

Adding a new disk to an existing pool:
-Proportional fill specifies that all new writes go to the newly added disks.  May not be a big deal if we are read-heavy (secondaries are readying only anyway)
-The newly added disk will get 100% of the writes because it has 0% consumption and proportional fill dictates evening out the fill
-So all new writes are going to a different disk and all reads are going to old disks until things are balanced out
-In a heavy write workload env, the new disk may not be able to handle all the writes if it's IOPs rating is below the VM IOPs capacity & workload IOPS requirements
-In that case, you must add enough disks in one shot to be able to handle the IOPs of the workload
-Also keep in mind data usage patterns; if reads shift to new data, then there would be contention on the newly added disks
-When a new disk is added, storage spaces will re-stripe data under the covers, and new writes will be striped across the number of disks equivalent to the column size of the pool.
-So depending on the column size and how many disks are added, new disks will be hotter 
-If all existing disks are full, you have to add the same number of new disks as the column size.  Otherwise, you won't be able to expand the virtual disk until the data is 
rebalanced across all disks with the background pool optimize process.
-Every new stripe will go across the same number of disks as the column size.  Aim to ad a new disk when there is about 20% of space left on the existing disks.  Then, you get
immediate new capacity while the rebalance process runs in the background.
-Rebalancing of data between disks in the pool is a lightweight, background process which can take a very long time.  It runs at a low priority. But make sure there is enough 
available throughput on the system to allow the rebalance.
-Set IOPs per gigabyte to be the same across all disks.

#>
