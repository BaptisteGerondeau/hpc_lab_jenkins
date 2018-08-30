#!/usr/bin/env bash

# read arguments
opts=$(getopt \
    --longoptions "$(printf "%s:," "${ARGUMENT_LIST[@]}")verbose,help" \
    --name "$(basename "$0")" \
    --options "vh" \
    -- "$@"
)
if [ $? -ne 0 ]; then
  exit 1
fi

# Parse arguments
eval set --$opts
while [[ $# -gt 0 ]]; do
    val=${1/--/}
    if [ -d $val ]; then
      shift
    else
	if [[ $val == 'verbose' ]] || [[ $val == 'v' ]]
	then
		export verbose=True
		shift
		break
	elif [[ $val == 'help' ]] || [[ $val == 'h' ]]
	then
		export help=True
		shift
		break
	fi
	export $val=$2
	shift 2
    fi
done
