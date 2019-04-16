#!/bin/sh 

now=$(date +"%d-%m-%Y")
fileExtension=".txt"
tempDir="/tmp"
candidatePvcFilename="candidatePvcs"-$now$fileExtension
namespacesFilename="namespaces"-$now$fileExtension
activePvcFilename="activePvcs"-$now$fileExtension
deletePvcFilename="deletePvcs"-$now$fileExtension
candidateNamespacesFilename="candidate-namespaces"-$now$fileExtension

inputHelp="Please choose 'dev' or 'sandbox'"
fullPathNamespacesFile=$tempDir/$namespacesFilename

if [ -z "$1" ]
then 
    echo "Please provide an env as input"
    echo $inputHelp
	exit 1
else
  case $1 in 
  	#login DCD-CNP-DEV
  	"dev") ./setup-dev-env.sh;;
	#login DCD-CFT-Sandbox
    "sandbox") ./setup-sandbox-env.sh;;
    *) echo "Invalid environment - $inputHelp"
       exit 1;;
  esac
fi

#function do delete a file at a given path
function deleteExistingFile(){
 fileToDelete=$1
 if [ -f $fileToDelete ]
 then
  	echo "Deleting existing file => "$fileToDelete
  	rm -f $fileToDelete	
 fi
}

#Fetch all namespaces in the current environement
echo "Creating new namespace file"
deleteExistingFile $fullPathNamespacesFile
kubectl get namespace -o json | jq -r '.items[] | .metadata.name' >> $fullPathNamespacesFile

#Get Pvcs in a given namespace
function getPvcs(){
  namespace=$1
  kubectl get pvc -o json -n $namespace | jq -r '.items[].metadata.name' | grep -v null | sort | uniq
}

#Stats function
function checkStats(){
  statsFile=$1
  echo "Checking all pvcs stats - started"
  deleteExistingFile $statsFile
	while read namespace; do
	  pvcCount=$(getPvcs $namespace | wc -l)
	    if [ $pvcCount -gt 0 ]
	    then 
	  	  echo $namespace " => " $pvcCount >> $statsFile
	    fi	
	done < $fullPathNamespacesFile
  echo "Checking all pvcs stats - done"
}

#Check stats before
fullPathBeforeStatsFile=$tempDir/"beforeStats"-$now$fileExtension 
checkStats fullPathBeforeStatsFile

#Fetch all pvcs in use by a pod in a namespace
function getActivePvcs(){
  namespace=$1
  kubectl get pods -o json -n $namespace | jq -r '.items[].spec.volumes[]?.persistentVolumeClaim.claimName' | grep -v null | sort | uniq
}

echo "Fetching all active pvcs in use by pod & write them in files - started"
while read namespace; do
  fullPathActivePvcFile=$tempDir/$namespace-$activePvcFilename
  pvcCount=$(getActivePvcs $namespace | wc -l)
  if [ $pvcCount -gt 0 ]
  then 
  	deleteExistingFile $fullPathActivePvcFile
  	getActivePvcs $namespace >> $fullPathActivePvcFile
  	echo "Active Pvcs for namespace $namespace saved in => $fullPathActivePvcFile"
  fi	
done < $fullPathNamespacesFile 
echo "Fetching all active pvcs in use by pod - done"

#File to store all namespaces of candidates pvc names
fullPathCandidateNamespacesFile=$tempDir/$candidateNamespacesFilename

#Fetch all candidate pvc names
echo "Fetching all candidates pvcs - started"
deleteExistingFile $fullPathCandidateNamespacesFile
while read namespace; do
  fullPathCandidatePvcFile=$tempDir/$namespace-$candidatePvcFilename
  deleteExistingFile $fullPathCandidatePvcFile	
  pvcCount=$(getPvcs $namespace | wc -l)
  if [ $pvcCount -gt 0 ]
  then 
  	getPvcs $namespace >> $fullPathCandidatePvcFile
  	# Write this namespace into the file
  	echo $namespace >> $fullPathCandidateNamespacesFile
  fi	
done < $fullPathNamespacesFile
echo "Fetching all candidates pvcs - done"

# Generate List of pvcs to delete using the candidate namespace file
echo "Generating pvcs to delete - started"
while read namespace; do
  activeFile=$tempDir/$namespace-$activePvcFilename
  candidateFile=$tempDir/$namespace-$candidatePvcFilename
  deleteFile=$tempDir/$namespace-$deletePvcFilename
  
  if [ -f $activeFile ]
  then
  	#check if activeFile and candidateFile are the same or not
    diffCount=$(diff $candidateFile $activeFile | wc -l)
     if [ $diffCount -gt 0 ]
     then
       echo "active pvcs exist; then generate delete file => "$namespace
       deleteExistingFile $deleteFile
       #remove active pvcs record from candidate pvcs and store the result in deleteFile
       comm -2 -3 $candidateFile $activeFile >> $deleteFile
     else
      echo "don't delete => "$namespace
     fi
  else
  	#no active pvcs exist
    echo "no active exist; then generate delete file => "$namespace
    deleteExistingFile $deleteFile
    cp $candidateFile $deleteFile
  fi
done < $fullPathCandidateNamespacesFile
echo "Generating pvcs to delete - done"

#Delete all qualified pvcs
echo "Deleting pvcs - started"
while read namespace; do
deleteFile=$tempDir/$namespace-$deletePvcFilename
  if [ -f $deleteFile ]
  then
    while read pvcName; do
	  echo $namespace " => " $pvcName
	  kubectl delete pvc $pvcName -n $namespace
	done < $deleteFile
  fi
done < $fullPathCandidateNamespacesFile
echo "Deleting pvcs - done"

# Check stats after 
fullPathAfterStatsFile=$tempDir/"afterStats"-$now$fileExtension 
checkStats $fullPathAfterStatsFile

