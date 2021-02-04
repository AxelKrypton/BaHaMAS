#
#  Copyright (c) 2015-2016 Christopher Czaban
#  Copyright (c) 2015-2018,2020-2021 Alessandro Sciarra
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

function __static__AddToJobscriptFile()
{
    while [[ $# -ne 0 ]]; do
        printf "%s\n" "$1" >> ${jobScriptGlobalPath}
        shift
    done
}

function AddSoftwareSpecificPartToProductionJobScript_CL2QCD()
{
    local jobScriptGlobalPath betaValues index
    jobScriptGlobalPath="$1"; shift
    betaValues=( "$@" )

    #Job script variables
    for index in "${!betaValues[@]}"; do
        __static__AddToJobscriptFile "dir${index}=${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${betaValues[${index}]}"
    done
    __static__AddToJobscriptFile ""
    for index in "${!betaValues[@]}"; do
        __static__AddToJobscriptFile "workdir${index}=${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${betaValues[${index}]}"
    done
    __static__AddToJobscriptFile\
        ""\
        "outFile=${BHMAS_productionExecutableFilename}.\${SLURM_JOB_ID}.out"\
        "errFile=${BHMAS_productionExecutableFilename}.\${SLURM_JOB_ID}.err"\
        ""\
        "# Check if directories exist"

    #Job script directory checks
    for index in "${!betaValues[@]}"; do
        __static__AddToJobscriptFile\
            "if [[ ! -d \${dir${index}} ]]; then"\
            "  echo \"Could not find directory \\\"\${dir${index}}\\\" for runs. Aborting...\"" \
            "  exit ${BHMAS_fatalFileNotFound}" \
            "fi" \
            ""
    done

    #Print some information
    __static__AddToJobscriptFile\
        "# Print some information"\
        "echo \"$(printf "%s " ${betaValues[@]})\""\
        "echo \"\""\
        "echo \"Host: \$(hostname)\""\
        "echo \"GPU:  \${GPU_DEVICE_ORDINAL}\""\
        "echo \"Date and time: \$(date)\""\
        "echo \${SLURM_JOB_NODELIST} > ${BHMAS_productionExecutableFilename}.${betasString:1}.\${SLURM_JOB_ID}.nodelist"\
        ""

    #Some more output information and run command(s)
    __static__AddToJobscriptFile\
        ""\
        "echo \"---------------------------\""\
        "export DISPLAY=:0"\
        "echo \"\\\"export DISPLAY=:0\\\" done!\""\
        "echo \"---------------------------\""\
        ""\
        "# Since we could run the job with a pipeline to handle the std output with mbuffer, we must activate pipefail to get the correct error code!"\
        "set -o pipefail"\
        ""\
        "# Run jobs from different directories"
    for index in "${!betaValues[@]}"; do
        __static__AddToJobscriptFile\
            "mkdir -p \${workdir${index}} || exit ${BHMAS_fatalBuiltin}"\
            "cd \${workdir${index}}"\
            "pwd &"\
            "if hash mbuffer 2>/dev/null; then"\
            "    time \${dir${index}}/${BHMAS_productionExecutableFilename} --inputFile=\${dir${index}}/${BHMAS_inputFilename} --deviceId=${index} --beta=${betaValues[${index}]%%_*} 2> \${dir${index}}/\${errFile} | mbuffer -q -m2M > \${dir${index}}/\${outFile} &"\
            "else"\
            "    time \${dir${index}}/${BHMAS_productionExecutableFilename} --inputFile=\${dir${index}}/${BHMAS_inputFilename} --deviceId=${index} --beta=${betaValues[${index}]%%_*} > \${dir${index}}/\${outFile} 2> \${dir${index}}/\${errFile} &"\
            "fi"\
            "PID_SRUN_${index}=\${!}"\
            ""
    done

    #Waiting for job(s) and handling exit code
    __static__AddToJobscriptFile "#Execute wait \${PID} job after job"
    for index in "${!betaValues[@]}"; do
        __static__AddToJobscriptFile "wait \${PID_SRUN_${index}} || { printf \"\nError occurred in simulation at b${betaValues[${index}]%_*}. Please check (process id \${PID_SRUN_${index}})...\n\" && ERROR_OCCURRED=\"TRUE\"; }"
    done
    __static__AddToJobscriptFile\
        ""\
        "# Terminating job manually to get an email in case of failure of any run"\
        "if [[ \"\${ERROR_OCCURRED}\" = \"TRUE\" ]]; then"\
        "   printf \"\nTerminating job with non zero exit code... (\$(date))\n\""\
        "   exit ${BHMAS_fatalGeneric}"\
        "fi"\
        ""\
        "# Unset pipefail since not needed anymore"\
        "set +o pipefail"\
        ""\
        "echo \"---------------------------\""\
        ""\
        "echo \"Date and time: \$(date)\""\
        "" ""

    #Backup important files if working on different disks and remove executable(s)
    if [[ "${BHMAS_submitDiskGlobalPath}" != "${BHMAS_runDiskGlobalPath}" ]]; then
        __static__AddToJobscriptFile "# Backup files"
        for index in "${!betaValues[@]}"; do
            __static__AddToJobscriptFile "cd \${dir${index}} || exit ${BHMAS_fatalBuiltin}"
            if [[ ${BHMAS_measurePbp} = "TRUE" ]]; then
                __static__AddToJobscriptFile "cp \${workdir${index}}/${BHMAS_outputFilename}_pbp.dat \${dir${index}}/${BHMAS_outputFilename}_pbp.\${SLURM_JOB_ID} || exit ${BHMAS_fatalBuiltin}"
            fi
            __static__AddToJobscriptFile "cp \${workdir${index}}/${BHMAS_outputFilename} \${dir${index}}/${BHMAS_outputFilename}.\${SLURM_JOB_ID} || exit ${BHMAS_fatalBuiltin}" ""
        done
    fi
    __static__AddToJobscriptFile "# Remove executable"
    for index in "${!betaValues[@]}"; do
        __static__AddToJobscriptFile "rm \${dir${index}}/${BHMAS_productionExecutableFilename} || exit ${BHMAS_fatalBuiltin}"
    done
    __static__AddToJobscriptFile ""

    #If a thermalization was done, copy produced thermalized configuration to pool
    if [[ ${BHMAS_executionMode} = 'mode:thermalize' ]] || [[ ${BHMAS_executionMode} = "mode:continue-thermalization" ]]; then
        local thermalizeType
        if [[ ${BHMAS_betaPostfix} == "_thermalizeFromHot" ]]; then
            thermalizeType='fromHot'
        elif [[ ${BHMAS_betaPostfix} == "_thermalizeFromConf" ]]; then
            thermalizeType='fromConf'
        fi
        __static__AddToJobscriptFile "# Copy last configuration to Thermalized Configurations folder"
        for index in "${!betaValues[@]}"; do
            __static__AddToJobscriptFile\
                "NUMBER_LAST_CONFIGURATION_IN_FOLDER=\$(ls \${workdir${index}} | grep '${BHMAS_configurationPrefix}[0-9]\+' | grep -o '[0-9]\+' | sort -V | tail -n1)" \
                "cp \${workdir${index}}/${BHMAS_configurationPrefix//\\/}\${NUMBER_LAST_CONFIGURATION_IN_FOLDER} ${BHMAS_thermConfsGlobalPath}/${BHMAS_configurationPrefix//\\/}${BHMAS_parametersString}_${BHMAS_betaPrefix}${betaValues[${index}]%_*}_${thermalizeType}_trNr\$(sed 's/^0*//' <<< \"\${NUMBER_LAST_CONFIGURATION_IN_FOLDER}\") || exit ${BHMAS_fatalBuiltin}"
        done
    fi
}


MakeFunctionsDefinedInThisFileReadonly
