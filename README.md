# cnp-pvcs-cleanup
Adhoc Shell script to delete unused Persistent Volume Claims (PVCs) in azure.

# How to run
```
chmod +x cleanup-volumes.sh  
 ./cleanup-volumes.sh $env

``` 
*env value is either "dev" or "sandbox"*

Output Files are generates in /tmp folder in the format: namespace-XXXXX-dd-mm-YYYY.txt 
