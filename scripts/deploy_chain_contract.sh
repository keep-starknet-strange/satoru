#!/bin/bash

# Deployment script for chain.cairo

command_output=$(starkli declare ../target/dev/gojo_Chain.sierra.json)


from_char=":"

class_hash=$(echo "$command_output" | sed 's/.*'$from_char'//')


starkli deploy $class_hash

