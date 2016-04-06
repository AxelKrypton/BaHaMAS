# Load auxiliary bash files that will be used.
source $HOME/Script/JobScriptAutomation/ListJobsStatusForLoewe.sh || exit -2
#------------------------------------------------------------------------------------#

function AcceptanceRateReport(){
    #-----------------------------------------#
    local BETAVALUES_COPY=(${BETAVALUES[@]})
    #-----------------------------------------#
    for INDEX in "${!BETAVALUES_COPY[@]}"; do
        local OUTPUTFILE_GLOBALPATH=$WORK_DIR_WITH_BETAFOLDERS/$BETA_PREFIX${BETAVALUES_COPY[$INDEX]}/$OUTPUTFILE_NAME
    	if [ ! -f $OUTPUTFILE_GLOBALPATH ]; then
			printf "\n\e[31m File $OUTPUTFILE_NAME not found in $WORK_DIR_WITH_BETAFOLDERS/$BETA_PREFIX${BETAVALUES_COPY[$INDEX]} folder! Skipping this beta...\e[0m"
	        PROBLEM_BETA_ARRAY+=( ${BETAVALUES_COPY[$INDEX]} )
	        unset BETAVALUES_COPY[$INDEX] #Here BETAVALUES_COPY becomes sparse
        fi
    done
    #Make BETAVALUES_COPY not sparse if not empty
    if [ ${#BETAVALUES_COPY[@]} -eq 0 ]; then
        echo '' && return
    else
        BETAVALUES_COPY=( ${BETAVALUES_COPY[@]} )
    fi
  	#Auxialiary arrays
	local NRLINES_ARRAY=()
	local DATA_ARRAY=()
	local POSITION_BETA_STRING_IN_DATA_ARRAY=()
    #Loop on betas and calculate acceptance concatenating data in single array    
	for BETA in ${BETAVALUES_COPY[@]}; do
        OUTPUTFILE_GLOBALPATH=$WORK_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA/$OUTPUTFILE_NAME
		NRLINES_ARRAY+=( $(awk '{if(NR%'$INTERVAL'==0){counter++;}}END{print counter}' $OUTPUTFILE_GLOBALPATH) )
		POSITION_BETA_STRING_IN_DATA_ARRAY+=( ${#DATA_ARRAY[@]} )
		DATA_ARRAY+=( "b${BETA%_*}" )
		DATA_ARRAY+=( $(awk '{if(NR%'$INTERVAL'==0){printf("%.2f \n", sum/'$INTERVAL*100');sum=0}}{sum+=$'$ACCEPTANCE_COLUMN'}' $OUTPUTFILE_GLOBALPATH) )
	done
	#Find largest number of intervals to print table properly
	local LENGTH_LONGEST_COLUMN=0
	for NRLINES in ${NRLINES_ARRAY[@]}; do
		[ $NRLINES -gt $LENGTH_LONGEST_COLUMN ] && LENGTH_LONGEST_COLUMN=$NRLINES
	done
    #Print table in proper form
    printf -v SPACE_AT_THE_BEGINNING_OF_EACH_LINE '%*s' 10 ''
    local EMPTY_SEPARATOR="   "
    #Here we evaluate the numbers to center the acceptance under the beta header:
    #
    #     |----beta_header----|
    #             xx.yy
    #      <----------------->    this is ${#DATA_ARRAY[0]}
    #             <--->           this is 5 (for the moment hard coded)
    #                  <----->    this is (${#DATA_ARRAY[0]} - 5 + 1)/2 where the +1 is to put one more in case of odd result of the subtraction
    #      <---------->           this is ${#DATA_ARRAY[0]} - (${#DATA_ARRAY[0]} - 5 + 1)/2  
    #
    local SPACE_AFTER_ACCEPTANCE_FIELD=$(( (${#DATA_ARRAY[0]} - 5 + 1)/2 )) #The first entry in DATA_ARRAY is a beta that is print in the header
    local ACCEPTANCE_FIELD_LENGTH=$(( ${#DATA_ARRAY[0]} - $SPACE_AFTER_ACCEPTANCE_FIELD )) 
    #Header
    printf -v LINE_OF_EQUAL '%*s' $((9 + (${#BETAVALUES_COPY[@]} + 1) * (2 *  ${#EMPTY_SEPARATOR}) + ${#BETAVALUES_COPY[@]} * ${#DATA_ARRAY[0]} )) ''
    printf "\n\e[0;36m$SPACE_AT_THE_BEGINNING_OF_EACH_LINE${LINE_OF_EQUAL// /=}\e[0m\n"
	local BETA_COUNTER=0
	printf "\e[38;5;39m${SPACE_AT_THE_BEGINNING_OF_EACH_LINE}${EMPTY_SEPARATOR}Intervals$EMPTY_SEPARATOR"
	while [ $BETA_COUNTER -lt ${#BETAVALUES_COPY[@]} ]; do
		printf "$EMPTY_SEPARATOR%s$EMPTY_SEPARATOR" ${DATA_ARRAY[${POSITION_BETA_STRING_IN_DATA_ARRAY[$BETA_COUNTER]}]}
		(( BETA_COUNTER++ ))
	done
    printf "\n\e[0;36m$SPACE_AT_THE_BEGINNING_OF_EACH_LINE${LINE_OF_EQUAL// /=}\e[0m\n"
	#Body
	local COUNTER=1
	while [ $COUNTER -le $LENGTH_LONGEST_COLUMN ];do
		printf "${SPACE_AT_THE_BEGINNING_OF_EACH_LINE}${EMPTY_SEPARATOR}%6d   $EMPTY_SEPARATOR\e[0m" $COUNTER
		local POS_INDEX=1
		for POS in ${POSITION_BETA_STRING_IN_DATA_ARRAY[@]}; do
			DATA_INDEX=$(expr $POS + $COUNTER)
			if [ $POS_INDEX -eq ${#POSITION_BETA_STRING_IN_DATA_ARRAY[@]} ]; then                  # "If I am printing the last column"
				if [ $DATA_INDEX -lt ${#DATA_ARRAY[@]} ]; then                                     # "If there are still data to print, print"
					printf "$(GoodAcc ${DATA_ARRAY[$DATA_INDEX]})$EMPTY_SEPARATOR%${ACCEPTANCE_FIELD_LENGTH}s%${SPACE_AFTER_ACCEPTANCE_FIELD}s$EMPTY_SEPARATOR\e[0m" ${DATA_ARRAY[$DATA_INDEX]} "" 
				else                                                                               # "otherwise print blank space"
					printf "$EMPTY_SEPARATOR$EMPTY_SEPARATOR"
				fi                                                                                 
			elif [ $POS_INDEX -lt ${#POSITION_BETA_STRING_IN_DATA_ARRAY[@]} ]; then                # "If I am printing not the last column"
				if [ $DATA_INDEX -lt ${POSITION_BETA_STRING_IN_DATA_ARRAY[$POS_INDEX]} ]; then     # "If there are still data to print, print"
					printf "$(GoodAcc ${DATA_ARRAY[$DATA_INDEX]})$EMPTY_SEPARATOR%${ACCEPTANCE_FIELD_LENGTH}s%${SPACE_AFTER_ACCEPTANCE_FIELD}s$EMPTY_SEPARATOR\e[0m" ${DATA_ARRAY[$DATA_INDEX]} "" 
				else                                                                               # "otherwise print blank space"
					printf "$EMPTY_SEPARATOR$EMPTY_SEPARATOR" 
				fi
			fi
			POS_INDEX=$(expr $POS_INDEX + 1)
		done
		printf "\n"
		(( COUNTER++ ))
	done
    printf "\e[0;36m$SPACE_AT_THE_BEGINNING_OF_EACH_LINE${LINE_OF_EQUAL// /=}\e[0m\n"

}



