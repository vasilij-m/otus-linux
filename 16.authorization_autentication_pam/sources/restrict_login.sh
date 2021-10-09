#!/bin/bash

ugroup=$(id $PAM_USER | grep -ow admin)
uday=$(date +%u)

if [[ -n $ugroup || $uday -lt 6 ]]; then
	exit 0
else
	exit 1
fi