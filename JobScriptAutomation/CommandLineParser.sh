# NOTE: If at some points for some reason one would decide to allow as options
#       --startcondition and/or --host_seed (CL2QCD) one should think whether
#       the continue part should be modified or not. 

function ParseCommandLineOption(){

    MUTUALLYEXCLUSIVEOPTS=( "-s | --submit"
                            "-c | --continue"
                            "-C | --continueThermalization"
                            "-t | --thermalize"
                            "-l | --liststatus"
                            "-U | --uncommentBetas"
                            "-u | --commentBetas"
                            "-i | --invertConfigurations"
							"-D | --dataBase"
                            "--liststatus_all"
                            "--submitonly"
                            "--showjobs"
                            "--showjobs_all"
                            "--accRateReport"
                            "--accRateReport_all"
                            "--emptyBetaDirectories"
                            "--cleanOutputFiles"
                            "--completeBetasFile")
    MUTUALLYEXCLUSIVEOPTS_PASSED=( )

    #Rewrite combined short options as proper options for parser
    local NEW_OPTIONS=()
    for VALUE in "$@"; do
        if [[ $VALUE =~ ^-[[:alpha:]]+(=.*)?$ ]]; then
            if [ $(grep -c "=" <<< "$VALUE") -gt 0 ]; then
                local OPTION_EQUAL_PART=${VALUE##*=}
                VALUE=${VALUE%%=*}
            else
                local OPTION_EQUAL_PART=""
            fi
            local SPLITTED_OPTIONS=( $(grep -o "." <<< "${VALUE:1}") )
            for OPTION in "${SPLITTED_OPTIONS[@]}"; do
                NEW_OPTIONS+=( "-$OPTION" )
            done && unset -v 'OPTION'
            [ "$OPTION_EQUAL_PART" != "" ] && NEW_OPTIONS[-1]="${NEW_OPTIONS[-1]}=$OPTION_EQUAL_PART" #Add =.* to last option 
        else
            NEW_OPTIONS+=($VALUE)
        fi
    done && unset -v 'VALUE'
    set -- ${NEW_OPTIONS[@]}
    
    if ! ElementInArray "--doNotUseMultipleChains" $@ && [ "$CLUSTER_NAME" = "JUQUEEN" ]; then
        printf "\n\e[0;31m At the moment, the options --doNotUseMultipleChains must be specified on not CSC clusters!! Aborting...\n\n\e[0m"
        exit -1
	fi

    
    while [ "$1" != "" ]; do
	    case $1 in
	        -h | --help )
		        printf "\n\e[0;32m"
		        echo "Call the script $0 with the following optional arguments:"
		        echo ""
		        echo "  -h | --help"
		        echo "  --jobscript_prefix                 ->    default value = $JOBSCRIPT_PREFIX"
		        echo "  --chempot_prefix                   ->    default value = $CHEMPOT_PREFIX"
		        echo -e "  --kappa_prefix                     ->    default value = k \e[1;32m(Wilson Case ONLY)\e[0;32m"
		        echo -e "  --mass_prefix                      ->    default value = mass \e[1;32m(Staggered Case ONLY)\e[0;32m"
		        echo "  --ntime_prefix                     ->    default value = $NTIME_PREFIX"
		        echo "  --nspace_prefix                    ->    default value = $NSPACE_PREFIX"
		        echo "  --beta_prefix                      ->    default value = $BETA_PREFIX"
		        echo "  --betasfile                        ->    default value = $BETASFILE"
		        echo "  -m | --measurements                ->    default value = $MEASUREMENTS"
		        echo "  -f | --confSaveFrequency           ->    default value = $NSAVE"
		        echo "  -F | --confSavePointFrequency      ->    default value = $NSAVEPOINT"
		        echo "  --intsteps0                        ->    default value = $INTSTEPS0"
		        echo "  --intsteps1                        ->    default value = $INTSTEPS1"
				echo "  --cgbs                             ->    default value = $CGBS (cg_iteration_block_size)"
		        echo -e "  --doNotUseMultipleChains           ->    if given, multiple chain usage and nomenclature are disabled \e[1;32m(this implies that in the betas file the seed column is NOT present)\e[0;32m"
		        if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then
		            echo "  --intsteps2                        ->    default value = $INTSTEPS2"
		            echo "  -w | --walltime                    ->    default value = $WALLTIME [hours:min:sec]"
		            echo "  --bgsize                           ->    default value = $BGSIZE"
		            echo "  --nrxprocs                         ->    default value = $NRXPROCS"
		            echo "  --nryprocs                         ->    default value = $NRYPROCS"
		            echo "  --nrzprocs                         ->    default value = $NRZPROCS"
		            echo "  --ompnumthreads                    ->    default value = $OMPNUMTHREADS"
		        else
		            echo "  -p | --doNotMeasurePbp             ->    if given, the chiral condensate measurement is switched off"
		            echo "  -w | --walltime                    ->    default value = $WALLTIME [days-hours:min:sec]"
		            echo "  --partition                        ->    default value = $LOEWE_PARTITION"
		            echo "  --constraint                       ->    default value = $LOEWE_CONSTRAINT"
		            echo "  --node                             ->    default value = automatically assigned"
		        fi
		        echo -e "  --doNotUseRAfiles                  ->    if given, the Rational Approximations are evaluated \e[1;32m(Staggered Case ONLY)\e[0;32m"
		        echo -e "  \e[0;34m-s | --submit\e[0;32m                      ->    jobs will be submitted"
		        echo -e "  \e[0;34m--submitonly\e[0;32m                       ->    jobs will be submitted (no files are created)"
		        echo -e "  \e[0;34m-t | --thermalize\e[0;32m                  ->    The thermalization is done." #TODO: Explain how
		        echo -e "  \e[0;34m-c | --continue\e[0;32m                    ->    Unfinished jobs will be continued doing the nr. of measurements specified in the input file."
		        echo -e "  \e[0;34m-c=[#] | --continue=[#]\e[0;32m                  If a number is specified, jobs will be continued up to the specified number."
		        if [ "$CLUSTER_NAME" = "LOEWE" ] || [ "$CLUSTER_NAME" = "LCSC" ]; then
		            echo -e "                                           To resume a simulation from a given trajectory, add \e[0;34mresumefrom=[number]\e[0;32m in the betasfile."
		            echo -e "                                           Use \e[0;34mresumefrom=last\e[0;32m in the betasfile to resume a simulation from the last saved conf.[[:digit:]]+ file."
		        fi
		        echo -e "  \e[0;34m-C | --continueThermalization\e[0;32m      ->    Unfinished thermalizations will be continued doing the nr. of measurements specified in the input file."
		        echo -e "  \e[0;34m-C=[#] | --continueThermalization=[#]\e[0;32m    If a number is specified, thermalizations will be continued up to the specified number."        
		        if [ "$CLUSTER_NAME" = "LOEWE" ] || [ "$CLUSTER_NAME" = "LCSC" ]; then
		            echo -e "                                           To resume a thermalization from a given trajectory, add \e[0;34mresumefrom=[number]\e[0;32m in the betasfile."
		            echo -e "                                           Use \e[0;34mresumefrom=last\e[0;32m in the betasfile to resume a thermalization from the last saved conf.[[:digit:]]+ file."
		        fi
		        echo -e "  \e[0;34m-l | --liststatus\e[0;32m                  ->    The local measurement status for all beta will be displayed"
		        if [ "$CLUSTER_NAME" = "LOEWE" ] || [ "$CLUSTER_NAME" = "LCSC" ]; then
		            echo -e "                                           Secondary options: \e[0;34m--measureTime\e[0;32m to get information about the trajectory time"
		            echo -e "                                                              \e[0;34m--showOnlyQueued\e[0;32m not to show status about not queued jobs"
		        fi
		        echo -e "  \e[0;34m--liststatus_all\e[0;32m                   ->    The global measurement status for all beta will be displayed"
		        echo -e "  \e[0;34m--showjobs\e[0;32m                         ->    The queued jobs will be displayed for the local parameters (kappa,nt,ns,beta)"
		        echo -e "  \e[0;34m--accRateReport\e[0;32m                    ->    The acceptance rates will be computed for the specified intervals of configurations"
		        echo -e "  \e[0;34m--accRateReport_all\e[0;32m                ->    The acceptance rates will be computed for the specified intervals of configurations for all parameters (kappa,nt,ns,beta)"
		        echo -e "  \e[0;34m--cleanOutputFiles\e[0;32m                 ->    The output files referred to the betas contained in the betas file are cleaned (repeated lines are eliminated)"
		        echo -e "                                           For safety reason, a backup of the output file is done (it is left in the output file folder with the name outputfilename_date)" 
		        echo -e "                                           Secondary options: \e[0;34m--all\e[0;32m to clean output files for all betas in WORK_DIR referred to the actual path parameters"
		        echo -e "  \e[0;34m--emptyBetaDirectories\e[0;32m             ->    The beta directories corresponding to the beta values specified in the file \"\e[4memptybetas\e[0;32m\" will be emptied!"
		        echo -e "                                           For each beta value specified there will be a promt for confirmation! \e[1mATTENTION\e[0;32m: After the Confirmation the process cannot be undone!" 
		        echo -e "  \e[0;34m--completeBetasFile[=number]\e[0;32m       ->    The beta file is completed adding for each beta new chains in order to have as many chain as specified. "
		        echo -e "                                           If no number is specified, 4 is used. This option, if \"-u\" has been given, uses the seed in the second field to generate new chains." 
		        echo -e "                                           Otherwise one new field containing the seed is inserted in second position." 
		        echo -e "  \e[0;34m-U | --uncommentBetas\e[0;32m              ->    This option uncomments the specified betas (All remaining entries will be commented)." 
		        echo -e "                                           The betas can be specified either with a seed or without."
		        echo -e "                                           The format of the specified string can either contain the output of the --liststatus option, e.g. 5.4380_s5491_NC" 
		        echo -e "                                           or simply beta values like 5.4380 or a mix of both. If pure beta values are given then all seeds of the given beta value will be uncommented."
		        echo -e "  \e[0;34m-u | --commentBetas\e[0;32m                ->    Is the reverse option of the --uncommentBetas option"
		        echo -e "  \e[0;34m-i | --invertConfigurations\e[0;32m        ->    Invert configurations and produce correlator files for betas and seed specified in the betas file."
				echo -e "  \e[0;34m-d | --dataBase\e[0;32m                    ->    Update, display and filter database. This is a subprogram plenty of functionalities. Run this script with"
                echo -e "                                           the option \e[0;34m--helpDatabase\e[0;32m to get an explanation about the various possibilities. To work with the database, specify the \e[0;34m-d\e[0;32m"
                echo -e "                                           option followed by all the database options. Differently said, all options given after \e[0;34m-d\e[0;32m are options for the database subprogram."
		        echo ""
		        echo -e "\e[0;93mNOTE: The blue options are mutually exclusive and they are all FALSE by default! In other words, if none of them"
		        echo -e "\e[0;93m      is given, the script will create beta-folders with the right files inside, but no job will be submitted."
		        echo ""
		        echo -e "\e[38;5;202mNOTE: Short options can be combined, and one specification via = can be appended to the last short option specified."
		        echo -e "\e[38;5;202m      For example \e[0;95m-dl\e[38;5;202m is equivalent to \e[0;95m-d -l\e[38;5;202m and \e[0;95m-pcm=10000\e[38;5;202m is equivalent to \e[0;95m-p -c -m=10000\e[38;5;202m."
		        printf "\n\e[0m"
		        exit
		        shift;;
            --jobscript_prefix=* )
                JOBSCRIPT_PREFIX=${1#*=}; shift ;;
            --chempot_prefix=* )
                CHEMPOT_PREFIX=${1#*=}; shift ;;
            --kappa_prefix=* )
                [ $STAGGERED = "TRUE" ] && printf "\n\e[0;31m The option --kappa_prefix can be used only in WILSON simulations! Aborting...\n\n\e[0m" && exit -1
		        KAPPA_PREFIX=${1#*=}; shift ;;
	        --mass_prefix=* )
                [ $WILSON = "TRUE" ] && printf "\n\e[0;31m The option --kappa_prefix can be used only in STAGGERED simulations! Aborting...\n\n\e[0m" && exit -1
                KAPPA_PREFIX=${1#*=}; shift ;;
	        --ntime_prefix=* )              NTIME_PREFIX=${1#*=}; shift ;;
	        --nspace_prefix=* )             NSPACE_PREFIX=${1#*=}; shift ;;
	        --beta_prefix=* )               BETA_PREFIX=${1#*=}; shift ;;
	        --betasfile=* )                 BETASFILE=${1#*=}; shift ;;
	        --chempot=* )                   CHEMPOT=${1#*=}; shift ;;
	        --kappa=* )                     KAPPA=${1#*=}; shift ;;
	        -w=* | --walltime=* )           WALLTIME=${1#*=}; shift ;;
	        --bgsize=* )                    BGSIZE=${1#*=}; shift ;;
	        -m=* | --measurements=* )       MEASUREMENTS=${1#*=}; shift ;;
	        --nrxprocs=* )                  NRXPROCS=${1#*=}; shift ;;
	        --nryprocs=* )                  NRYPROCS=${1#*=}; shift ;;
	        --nrzprocs=* )                  NRZPROCS=${1#*=}; shift ;;
	        --ompnumthreads=* )             OMPNUMTHREADS=${1#*=}; shift ;;
	        -f=* | --confSaveFrequency=* )  NSAVE=${1#*=}; shift ;;
	        -F=* | --confSavePointFrequency=* )  NSAVEPOINT=${1#*=}; shift ;;
	        --intsteps0=* )                 INTSTEPS0=${1#*=}; shift ;;
	        --intsteps1=* )                 INTSTEPS1=${1#*=}; shift ;;
	        --intsteps2=* )                 INTSTEPS2=${1#*=}; shift ;;
			--cgbs=* )                      CGBS=${1#*=}; shift ;;
	        -p | --doNotMeasurePbp )        MEASURE_PBP="FALSE"; shift ;;
	        --doNotUseRAfiles )
                [ $WILSON = "TRUE" ] && printf "\n\e[0;31m The option --doNotUseRAfiles can be used only in STAGGERED simulations! Aborting...\n\n\e[0m" && exit -1
                USE_RATIONAL_APPROXIMATION_FILE="FALSE"; shift ;;
	        --doNotUseMultipleChains )
		        USE_MULTIPLE_CHAINS="FALSE"
		        if [ $THERMALIZE = "FALSE" ]; then
		    	    BETA_POSTFIX=""
		        fi
                shift ;;
	        --partition=* )
		        LOEWE_PARTITION=${1#*=}; 
	            if [[ $CLUSTER_NAME != "LOEWE" ]]; then
		            printf "\n\e[0;31m The options --partition can be used only on the LOEWE! Aborting...\n\n\e[0m"
                    exit -1
		        fi
		        shift ;;
	        --constraint=* )
		        LOEWE_CONSTRAINT=${1#*=}; 
	            if [[ $CLUSTER_NAME != "LOEWE" ]]; then
		            printf "\n\e[0;31m The options --constraint can be used only on the LOEWE! Aborting...\n\n\e[0m"
                    exit -1
		        fi
		        shift ;;
	        --node=* )
                LOEWE_NODE=${1#*=}; 
	            if [[ $CLUSTER_NAME != "LOEWE" ]]; then
		            printf "\n\e[0;31m The options --node can be used only on the LOEWE! Aborting...\n\n\e[0m"
                    exit -1
		        fi
		        shift ;;
	        -s | --submit )
		        MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
		        SUBMIT="TRUE"
		        shift;; 
	        --submitonly )	 			
                MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
		        SUBMITONLY="TRUE"
		        shift;; 
	        -t | --thermalize )			 
		        MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
		        THERMALIZE="TRUE"
		        shift;; 
	        -c | --continue )			 
		        MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
		        CONTINUE="TRUE"		
		        shift;; 
	        -c=* | --continue=* )		
		        MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
		        CONTINUE="TRUE"
		        CONTINUE_NUMBER=${1#*=}; 
		        if [[ ! $CONTINUE_NUMBER =~ ^[[:digit:]]+$ ]];then
		    	    printf "\n\e[0;31m The specified number for --continue=[number] must be an integer containing at least one or more digits! Aborting...\n\n\e[0m" 
			        exit -1
		        fi
		        shift;; 
	        -C | --continueThermalization )			 
		        MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
		        CONTINUE_THERMALIZATION="TRUE"		
		        shift;; 
	        -C=* | --continueThermalization=* )		
		        MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
		        CONTINUE_THERMALIZATION="TRUE"
		        CONTINUE_NUMBER=${1#*=}; 
		        if [[ ! $CONTINUE_NUMBER =~ ^[[:digit:]]+$ ]];then
		    	    printf "\n\e[0;31m The specified number for --continueThermalization=[number] must be an integer containing at least one or more digits! Aborting...\n\n\e[0m" 
			        exit -1
		        fi
		        shift;; 
	        -l | --liststatus )
		        MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
		        LISTSTATUS="TRUE"
		        LISTSTATUSALL="FALSE"
		        shift;;
	        --measureTime )
	            [ $LISTSTATUS = "FALSE" ] && printf "\n\e[0;31mSecondary option --measureTime must be given after the primary one \"-l | --liststatus\"! Aborting...\n\n\e[0m" && exit -1
		        LISTSTATUS_MEASURE_TIME="TRUE"
		        shift;;
	        --showOnlyQueued )
	            [ $LISTSTATUS = "FALSE" ] && printf "\n\e[0;31mSecondary option --showOnlyQueued must be given after the primary one \"-l | --liststatus\"! Aborting...\n\n\e[0m" && exit -1
		        LISTSTATUS_SHOW_ONLY_QUEUED="TRUE"
		        shift;;
	        --liststatus_all )
		        MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
		        LISTSTATUS="FALSE"
		        LISTSTATUSALL="TRUE"
		        shift;; 
	        --showjobs )
                MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
		        SHOWJOBS="TRUE"
		        shift;; 
	        --accRateReport=* )
                INTERVAL=${1#*=} 
		        MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--accRateReport" )
	   	        ACCRATE_REPORT="TRUE"
	            shift ;;
	        --accRateReport_all=* )
                INTERVAL=${1#*=}
		        MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--accRateReport_all" )
	   	        ACCRATE_REPORT="TRUE"
	   	        ACCRATE_REPORT_GLOBAL="TRUE"
	            shift ;;
	        --cleanOutputFiles )
                MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
		        CLEAN_OUTPUT_FILES="TRUE"
	            shift ;;
	        --all )
	            [ $CLEAN_OUTPUT_FILES = "FALSE" ] && printf "\n\e[0;31mSecondary option --all must be given after the primary one! Aborting...\n\n\e[0m" && exit -1
		        SECONDARY_OPTION_ALL="TRUE"
		        shift;;
	        --emptyBetaDirectories )
		        MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
		        EMPTY_BETA_DIRS="TRUE"
	            shift ;;
	        --completeBetasFile* )
		        MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--completeBetasFile" )
		        COMPLETE_BETAS_FILE="TRUE"
                local TMP_STRING=${1#*File}
                if [ "$TMP_STRING" != "" ]; then
                    if [ ${TMP_STRING:0:1} == "=" ]; then
                        NUMBER_OF_CHAINS_TO_BE_IN_THE_BETAS_FILE=${1#*=}
                    else
                        printf "\n\e[0;31m Invalid option \e[1m$1\e[0;31m (see help for further information)! Aborting...\n\n\e[0m"
                    fi
                fi
	            shift ;;
		    -U | --uncommentBetas | -u | --commentBetas )
		        MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
                if [ $1 = '-U' ] || [ $1 = '--uncommentBetas' ]; then
				    COMMENT_BETAS="FALSE"
				    UNCOMMENT_BETAS="TRUE"
                elif [ $1 = '-u' ] || [ $1 = '--commentBetas' ]; then
                    UNCOMMENT_BETAS="FALSE"
                    COMMENT_BETAS="TRUE"
                fi
                
				while [[ "$2" =~ ^[[:digit:]]\.[[:digit:]]{4}_s[[:digit:]]{4}_(NC|fC|fH)$ ]] || [[ "$2" =~ ^[[:digit:]]\.[[:digit:]]*$ ]]
				do
					if [[ "$2" =~ ^[[:digit:]]\.[[:digit:]]{4}_s[[:digit:]]{4}_(NC|fC|fH)$ ]]
					then
						UNCOMMENT_BETAS_SEED_ARRAY+=( $2 )
					elif [[ "$2" =~ ^[[:digit:]]\.[[:digit:]]*$ ]]
					then 
                        UNCOMMENT_BETAS_ARRAY+=( $(awk '{printf "%1.4f", $1}' <<< "$2") )
					fi
				    shift
				done
                shift
				;;
            -i | --invertConfigurations)
				MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--invertConfigurations" )
                INVERT_CONFIGURATIONS="TRUE"
                shift
                ;;
			-d | --database)
				CALL_DATABASE="TRUE"
				MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--database" )
				shift
				DATABASE_OPTIONS=( $@ )
				shift $#
				;;
	        * ) printf "\n\e[0;31m Invalid option \e[1m$1\e[0;31m (see help for further information)! Aborting...\n\n\e[0m" ; exit -1 ;;
	    esac
    done

    if [ ${#MUTUALLYEXCLUSIVEOPTS_PASSED[@]} -gt 1 ]; then
	    printf "\n\e[0;31m The options\n\n\e[1m" 
	    for OPT in "${MUTUALLYEXCLUSIVEOPTS[@]}"; do
		    printf "  %s\n" "$OPT"
	    done
	    printf "\n\e[0;31m are mutually exclusive and must not be combined! Aborting...\n\n\e[0m" 
	    exit -1
    fi
}
