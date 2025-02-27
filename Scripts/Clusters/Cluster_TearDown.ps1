#to destroy the cluster, run the command below
#it will evict all nodes and will clean up AD
Remove-Cluster -Cluster "ClusterName" -Force -CleanupAD

#SQL Services will need to be restarted 
#objects will be deleted in AD so they need to restaged