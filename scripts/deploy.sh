#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

function dump {
	echo
	kubectl get pods -n "$POD_NAMESPACE" -o json  | jq -r '.items[] | .metadata.namespace + "/" + .metadata.name + " - " + .status.phase + " - " + .metadata.deletionTimestamp'
}

function waitForPods {
	local RETRIES=30
	local WAIT_PERIOD=10
	
	[[ "$#" -gt 0 ]] && [[ -f "$1/wait.settings" ]] && . "$1/wait.settings"
	
	echo -n "waiting ..."
	local n=`kubectl get pods -n "$POD_NAMESPACE" -o json  | jq -r '.items[] | select((.metadata.ownerReferences[].kind == "Job" and .status.phase != "Succeeded") or (.metadata.ownerReferences[].kind != "Job" and .status.phase != "Running") or (.metadata.deletionTimestamp != null)) | .metadata.namespace + "/" + .metadata.name' | wc -l`
	while [[ "$n" -ne 0 ]]
	do
		n=`kubectl get pods -n "$POD_NAMESPACE" -o json  | jq -r '.items[] | select((.metadata.ownerReferences[].kind == "Job" and .status.phase != "Succeeded" and .status.phase != "Running" and .status.phase != "Pending") or (.metadata.ownerReferences[].kind != "Job" and .status.phase != "Running" and .status.phase != "Pending")) | .metadata.namespace + "/" + .metadata.name' | wc -l`
		[[ "$n" -ne 0 ]] && dump && echo "ERROR: pod(s) in error state found!" && return 1
		RETRIES=$((RETRIES-1))
		if [[ "$RETRIES" -le 0 ]]
		then
			echo
			echo "ERROR: wait time exceeded!"
			return 1
		fi
		
		echo -n "."
		sleep $WAIT_PERIOD
		n=`kubectl get pods -n "$POD_NAMESPACE" -o json  | jq -r '.items[] | select((.metadata.ownerReferences[].kind == "Job" and .status.phase != "Succeeded") or (.metadata.ownerReferences[].kind != "Job" and .status.phase != "Running") or (.metadata.deletionTimestamp != null)) | .metadata.namespace + "/" + .metadata.name' | wc -l`
	done
	echo
}

function deploy {
  waitForPods
  for i in `ls -1 | grep -E "^[0-9]+" | grep -vE "^0+[^0-9]+"`
  do
    for j in `ls -1 "$i" | grep -E "\.yaml|\.yml"`
    do
      echo "deploying $i/$j ..."
  	  kubectl create -n "$POD_NAMESPACE" -f "$i/$j"
  	  sleep 2
    done
	waitForPods "$i"
  done
}

if [[ ! -z "${1-}" ]]
then
	git clone "$1" git
	if [[ ! -z "${2-}" ]]
	then
		cd git/"$2"
	else
		cd git
	fi
elif [[ ! -z "${GIT_URL-}" ]]
then
	git clone "$GIT_URL" git
	cd git
fi

deploy

echo
echo "finished!"
