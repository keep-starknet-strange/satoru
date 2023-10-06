#!/bin/bash

# Deployment script for adl_handler.cairo

# Declare the contract and capture the command output
command_output=$(starkli declare ../target/dev/satoru_AdlHandler.sierra.json)

# Define the character to split the command output
from_char=":"

# Extract the class hash from the command output
class_hash=$(echo "$command_output" | sed 's/.*'$from_char'//')

# Deploy the contract using the extracted class hash
starkli deploy $class_hash $1 $2 $3 $4 $5 $6 $7 $8