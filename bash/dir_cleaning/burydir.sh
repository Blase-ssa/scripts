#!/bin/bash
# This script designed to move old directories to a specific folder (CEMETERY).
# And since the script is executed on a highly loaded server, some operations are performed with reduced priority.
# The script also removes symlinks before archiving and cleaning.

# Uncomment the string below to print every shell command before execute it.
# set -x

# place to bury directories
CEMETERY="/NFS/archive"

## help function
Print_help(){
    echo "This script designed to move old directories to a specific folder (CEMETERY).
    
    To use script:
    0) update CEMETERY variable inside this script, to move old directories to the folder you need,
    1) mark all folders with \"_old\" or "_OLD" mark,
    2) run script with filter parametr (use "old" if you want to move all files)
    "
}

send_to_the_cemetery(){
    echo "$OLDDIRS"
    for SDIR in $OLDDIRS; do
        find "$SDIR" -type l -exec unlink {} \;
        # Archive dir
        ionice -c 3 nice -n 19 zip -r "${CEMETERY}/${SDIR}.zip" "$SDIR"
        echo "rm -rf $SDIR"
    done
}

main(){
    ### Print help and exit
    if [[ $# < 1 ]] || [[ $1 == '-h' ]] ; then
        Print_help
        exit 0
    fi
    # get list of 
    OLDDIRS=$(ls |grep -i $1 |grep -i "_old")
    send_to_the_cemetery
}

## check if script executed or used as a lib
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main $1
fi
