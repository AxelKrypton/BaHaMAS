#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENCE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

# NOTE: At the moment I do not have a smarter idea about
#       how to understand which scheduler is installed
#       on the cluster, so I check for the existence of
#       the command to get the cluster jobs queue information.

function SelectClusterSchedulerName()
{
    local availableScheduler scheduler
    availableScheduler=()
    #Queue commands of some well known job schedulers
    declare -A schedulerMap=( ['LOADLEVELER']='llq'
                              ['LSF']='bjobs'
                              ['PBS']='qstat'
                              ['SLURM']='squeue' )

    for scheduler in "${!schedulerMap[@]}"; do
        if hash "${schedulerMap[$scheduler]}" 2>/dev/null; then
            availableScheduler+=( "$scheduler" )
        fi
    done

    if [ ${#availableScheduler[@]} -eq 0 ]; then
        cecho lr "\n No known scheduler was found! Aborting...\n" >&2
        exit -1
    elif [ ${#availableScheduler[@]} -gt 1 ]; then
        cecho "\n" ly B " WARNING:" uB " More than one scheduler was found! Using " o B "${availableScheduler[0]}" uB ly "\n" >&2
    fi

    printf "${availableScheduler[0]}"
}
