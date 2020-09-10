#
#  Copyright (c) 2020 Alessandro Sciarra
#
#  This file is part of BaHaMAS.
#
#  BaHaMAS is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  BaHaMAS is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with BaHaMAS. If not, see <http://www.gnu.org/licenses/>.
#

function GatherAndPrintJobsInformation()
{
    local jobsInformation string\
          jobId jobName jobStatus jobNodeList jobSubmissionTime jobWalltime\
          jobStartTime jobRunTime jobEndTime jobSubmissionFolder jobNumberOfNodes\
          lengthOfLongestJobName lengthOfLongestJobId\
          numberOfJobs numberOfRunningJobs numberOfPendingJobs numberOfOtherJobs\
          lineOfEquals tableFormat index\
          nodesPendingTimeString startEndTime runWallTime submissionTimeString
    #Call function scheduler specific: It will fill jobsInformation
    GatherJobsInformationForJobStatusMode
    if [[ "${#jobsInformation[@]}" -eq 0 ]]; then
        cecho lc "\n No job found according to given options!"
        return 0
    fi
    #Split job information in different arrays using '@' as separator
    #NOTE: Here the strings could contain glob patterns (e.g. NodeList)
    #      and it is important to quote them, since nullglob is set.
    for string in "${jobsInformation[@]}"; do
        jobId+=(               "${string%%@*}" ); string="${string#*@}"
        jobName+=(             "${string%%@*}" ); string="${string#*@}"
        jobStatus+=(           "${string%%@*}" ); string="${string#*@}"
        jobNodeList+=(         "${string%%@*}" ); string="${string#*@}"
        jobSubmissionTime+=(   "${string%%@*}" ); string="${string#*@}"
        jobWalltime+=(         "${string%%@*}" ); string="${string#*@}"
        jobStartTime+=(        "${string%%@*}" ); string="${string#*@}"
        jobRunTime+=(          "${string%%@*}" ); string="${string#*@}"
        jobEndTime+=(          "${string%%@*}" ); string="${string#*@}"
        jobSubmissionFolder+=( "${string%%@*}" ); string="${string#*@}"
        jobNumberOfNodes+=(    "${string%%@*}" )
    done
    #Shorten path (it works only if the user is 'whoami'
    jobSubmissionFolder=( ${jobSubmissionFolder[@]/${BHMAS_submitDiskGlobalPath}/SUBMIT} )
    jobSubmissionFolder=( ${jobSubmissionFolder[@]/${BHMAS_runDiskGlobalPath}/WORK} )
    #Some counting for the table
    numberOfJobs=${#jobId[@]}
    set +e
    numberOfRunningJobs=$(grep -o "RUNNING" <<< "${jobStatus[@]}" | wc -l)
    numberOfPendingJobs=$(grep -o "PENDING" <<< "${jobStatus[@]}" | wc -l)
    set -e
    numberOfOtherJobs=$(( numberOfJobs - numberOfRunningJobs - numberOfPendingJobs ))

    #Table header
    printf -v lineOfEquals '%*s' $(( $(tput cols) - 3 )) ''
    lineOfEquals=${lineOfEquals// /=}
    lengthOfLongestJobId=$(LengthOfLongestEntryInArray "${jobId[@]}")
    lengthOfLongestJobName=$(LengthOfLongestEntryInArray "${jobName[@]}")
    tableFormat="%-$((5+lengthOfLongestJobId))s%-$((5+lengthOfLongestJobName))s%-26s%-24s%+12s     %-s"
    cecho lc "\n" B "${lineOfEquals}\n"\
          bb "$(printf "${tableFormat}" "JOB ID" "JOB NAME" "STATUS" "START/END TIME" "WALL/RUNTIME" "SUBMITTED FROM")"

    #Print table sorting according jobname
    while [[ ${#jobName[@]} -gt 0 ]]; do
        index=$(FindPositionOfFirstMinimumOfArray "${jobName[@]}")
        __static__ChangeOutputColor "${jobStatus[${index}]}" "${jobStartTime[${index}]}"

        if [[ ${jobStatus[${index}]} == "RUNNING" ]]; then
            if [[ ${jobNumberOfNodes[${index}]} -eq 1 ]]; then
                nodesPendingTimeString=" on ${jobNodeList[${index}]}"
            else
                nodesPendingTimeString=" on ${jobNumberOfNodes[${index}]} nodes"
            fi
            startEndTime="${jobEndTime[${index}]}"
            runWallTime="${jobRunTime[${index}]}"
            submissionTimeString=''
        else
            if [[ ${jobStatus[${index}]} == "PENDING" ]]; then
                nodesPendingTimeString=" for $(__static__GetQueuingTime ${jobSubmissionTime[${index}]})"
            else
                nodesPendingTimeString=''
            fi
            startEndTime="${jobStartTime[${index}]}"
            runWallTime="${jobWalltime[${index}]}"
            submissionTimeString=" on ${jobSubmissionTime[${index}]}"
        fi

        printf "${tableFormat}\e[0m\n"\
               "${jobId[${index}]}"\
               "${jobName[${index}]}"\
               "${jobStatus[${index}]}${nodesPendingTimeString}"\
               "${startEndTime}"\
               "${runWallTime}"\
               "${jobSubmissionFolder[${index}]}${submissionTimeString}"

        unset -v 'jobId[${index}]';               jobId=(               ${jobId[@]+"${jobId[@]}"} )
        unset -v 'jobName[${index}]';             jobName=(             ${jobName[@]+"${jobName[@]}"} )
        unset -v 'jobStatus[${index}]';           jobStatus=(           ${jobStatus[@]+"${jobStatus[@]}"} )
        unset -v 'jobStartTime[${index}]';        jobStartTime=(        ${jobStartTime[@]+"${jobStartTime[@]}"} )
        unset -v 'jobEndTime[${index}]';          jobEndTime=(          ${jobEndTime[@]+"${jobEndTime[@]}"} )
        unset -v 'jobSubmissionTime[${index}]';   jobSubmissionTime=(   ${jobSubmissionTime[@]+"${jobSubmissionTime[@]}"} )
        unset -v 'jobSubmissionFolder[${index}]'; jobSubmissionFolder=( ${jobSubmissionFolder[@]+"${jobSubmissionFolder[@]}"} )
        unset -v 'jobNumberOfNodes[${index}]';    jobNumberOfNodes=(    ${jobNumberOfNodes[@]+"${jobNumberOfNodes[@]}"} )
        unset -v 'jobNodeList[${index}]';         jobNodeList=(         ${jobNodeList[@]+"${jobNodeList[@]}"} )
        unset -v 'jobWalltime[${index}]';         jobWalltime=(         ${jobWalltime[@]+"${jobWalltime[@]}"} )
        unset -v 'jobRunTime[${index}]';          jobRunTime=(          ${jobRunTime[@]+"${jobRunTime[@]}"} )
    done
    cecho o "\n  Total number of submitted jobs: " B "${numberOfJobs}" uB " (" B lg "Running: ${numberOfRunningJobs}" ly "     Pending: ${numberOfPendingJobs}" lm "     Others: ${numberOfOtherJobs}" uB o ")"
    cecho lc B "${lineOfEquals}"
}


function __static__ChangeOutputColor()
{
    local status startingTime color
    status="$1"
    startingTime="$2"
    if [[ "${status}" = 'RUNNING' ]]; then
        color='lg'
    elif [[ "${status}" = 'PENDING' ]]; then
        if [[ "${startingTime}" != 'N/A' ]]; then
            color='ly'
        else
            color='lo'
        fi
    else
        color='lm'
    fi
    cecho -d -n "${color}"
}

function __static__GetQueuingTime()
{
    local submissionTime queuingTime
    submissionTime="$1"
    queuingTime=$(( $(date +'%s') - $(date -d "${submissionTime}" +'%s') ))
    printf "%d-%s" $((queuingTime/86400)) $(date -d@${queuingTime} -u +'%H:%M:%S')
}


MakeFunctionsDefinedInThisFileReadonly
