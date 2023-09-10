#!/bin/bash

# Deployment script for role_store.cairo

command_output=$(starkli declare ../target/dev/satoru_RoleStore.sierra.json)


from_char=":"

class_hash=$(echo "$command_output" | sed 's/.*'$from_char'//')


starkli deploy $class_hash