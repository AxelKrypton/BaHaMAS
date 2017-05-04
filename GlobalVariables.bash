#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

#----------------------------------------------------------------------------------#
# Variables about operations on path. For the moment we hard-code the existence    #
# of 5 parameters and of their order in the path. Maybe there is an elegant        #
# way to generalize this feature of BaHaMAS, but at the moment we leave it so.     #
#                                                                                  #
# NOTE: Since we have 5 parameters (Nf, kappa, mu, ns, nt), in principle there     #
#       are 5!=120 possible orders. Here we fix the order using an array.          #
#                                                                                  #
# ATTENTION: For the moment, BaHaMAS is built ad hoc for CL2QCD and since the      #
#            algorithms to be run for staggered and Wilson fermions are rather     #
#            different, we introduce here two variables to detect in which         #
#            situation we are. The idea is that only one variable must be 'TRUE'   #
#            and this can also be used to bypass the distinction in case it        #
#            is not needed. Note that the use of two variables can be thought      #
#            to be an overhead since in principle a single variable would be       #
#            enough. Actually, having two variables increases readability of       #
#            the code and this approach is open to future new cases.               #
#----------------------------------------------------------------------------------#

function DeclarePathRelatedGlobalVariables(){
    #Setting of the correct formulation based on the path.
    STAGGERED="FALSE"
    WILSON="FALSE"
    [ $(grep "[sS]taggered" <<< "$PWD" | wc -l) -gt 0 ] && STAGGERED="TRUE"
    [ $(grep    "[wW]ilson" <<< "$PWD" | wc -l) -gt 0 ] && WILSON="TRUE"
    #Parameters positions
    NFLAVOUR_POSITION=0
    CHEMPOT_POSITION=1
    MASS_POSITION=2
    NTIME_POSITION=3
    NSPACE_POSITION=4
    #Parameters prefixes
    NFLAVOUR_PREFIX="Nf"
    CHEMPOT_PREFIX="mui"
    [ $WILSON = "TRUE" ] && MASS_PREFIX="k" || MASS_PREFIX="mass"
    NTIME_PREFIX="nt"
    NSPACE_PREFIX="ns"
    PARAMETER_PREFIXES=( [$NFLAVOUR_POSITION]=$NFLAVOUR_PREFIX
                         [$CHEMPOT_POSITION]=$CHEMPOT_PREFIX
                         [$MASS_POSITION]=$MASS_PREFIX
                         [$NTIME_POSITION]=$NTIME_PREFIX
                         [$NSPACE_POSITION]=$NSPACE_PREFIX )
    #Parameters values
    NFLAVOUR=""
    CHEMPOT=""
    MASS=0
    NSPACE=0
    NTIME=0
    #Parameters regular expressions
    NFLAVOUR_REGEX='[[:digit:]]\([.][[:digit:]]\)\?'
    CHEMPOT_REGEX='\(0\|PiT\)'
    MASS_REGEX='[[:digit:]]\{4\}'
    NTIME_REGEX='[[:digit:]]\{1,2\}'
    NSPACE_REGEX='[[:digit:]]\{1,2\}'
    PARAMETER_REGEXES=( [$NFLAVOUR_POSITION]=$NFLAVOUR_REGEX
                        [$CHEMPOT_POSITION]=$CHEMPOT_REGEX
                        [$MASS_POSITION]=$MASS_REGEX
                        [$NTIME_POSITION]=$NTIME_REGEX
                        [$NSPACE_POSITION]=$NSPACE_REGEX )
    #Parameters path and string
    PARAMETERS_PATH=""     # --> e.g. /Nf2/muiPiT/k1550/nt6/ns12    or   /Nf2/mui0/mass0250/nt4/ns8
    PARAMETERS_STRING=""   # --> e.g.  Nf2_muiPiT_k1550_nt6_ns12    or    Nf2_mui0_mass0250_nt4_ns8
    #Beta and seed information
    BETA_PREFIX="b"
    SEED_PREFIX="s"
    BETA_POSTFIX=""
    BETA_PREFIX="b"
    SEED_PREFIX="s"
    SEED_REGEX='[[:digit:]]\{4\}'
    BETA_POSTFIX=""
    BETA_POSITION=5
    BETA_REGEX='[[:digit:]][.][[:digit:]]\{4\}'
    BETA_FOLDER_SHORT_REGEX=$BETA_REGEX'_'$SEED_PREFIX'[[:digit:]]\{4\}_[[:alpha:]]\+'
    BETA_FOLDER_REGEX=$BETA_PREFIX$BETA_FOLDER_SHORT_REGEX
}

#----------------------------------------------------------------------------------#
# The following variables are instead for BaHaMAS functionality. Most of them      #
# are needed for the command line options and the main branches of the flow of     #
# the code. Some are just about the coloured output, while some others are simply  #
# necessary for the implementation of the different features.                      #
#----------------------------------------------------------------------------------#

function DeclareBaHaMASGlobalVariables(){
    BaHaMAS_clusterScheduler="$(SelectClusterSchedulerName)"
    BETASFILE='betas'
    BETA_POSTFIX='_continueWithNewChain' #Here we set the BETA_POSTFIX supposing it is not a thermalization. If indeed it is, the postfix will be overwritten in the thermalize case in the main!
    WALLTIME='7-00:00:00'
    MEASUREMENTS=20000
    NSAVE=100
    NSAVEPOINT=20
    INTSTEPS0=7
    INTSTEPS1=5
    INTSTEPS2=5
    CGBS=50
    MEASURE_PBP='TRUE'
    USE_MULTIPLE_CHAINS='TRUE'
    CLUSTER_NAME='LOEWE'
    JOBS_STATUS_PREFIX='jobs_status_'
    USE_RATIONAL_APPROXIMATION_FILE='TRUE'

    #Mutually exclusive options variables
    SUBMIT='FALSE'
    SUBMITONLY='FALSE'
    THERMALIZE='FALSE'
    CONTINUE='FALSE'
    CONTINUE_NUMBER=0
    CONTINUE_THERMALIZATION='FALSE'
    LISTSTATUS='FALSE'
    LISTSTATUS_MEASURE_TIME='FALSE'
    LISTSTATUS_SHOW_ONLY_QUEUED='FALSE'
    ACCRATE_REPORT='FALSE'
    INTERVAL=1000
    CLEAN_OUTPUT_FILES='FALSE'
    SECONDARY_OPTION_ALL='FALSE'
    COMPLETE_BETAS_FILE='FALSE'
    NUMBER_OF_CHAINS_TO_BE_IN_THE_BETAS_FILE=4
    UNCOMMENT_BETAS='FALSE'
    COMMENT_BETAS='FALSE'
    INVERT_CONFIGURATIONS='FALSE'
    CALL_DATABASE='FALSE'

    #Variables for output color
    DEFAULT_LISTSTATUS_COLOR="\e[0;36m"
    SUSPICIOUS_BETA_LISTSTATUS_COLOR="\e[0;33m"
    WRONG_BETA_LISTSTATUS_COLOR="\e[0;91m"
    TOO_HIGH_DELTA_S_LISTSTATUS_COLOR="\e[0;91m"
    TOO_LOW_ACCEPTANCE_LISTSTATUS_COLOR="\e[38;5;9m"
    LOW_ACCEPTANCE_LISTSTATUS_COLOR="\e[38;5;208m"
    OPTIMAL_ACCEPTANCE_LISTSTATUS_COLOR="\e[38;5;10m"
    HIGH_ACCEPTANCE_LISTSTATUS_COLOR="\e[38;5;11m"
    TOO_HIGH_ACCEPTANCE_LISTSTATUS_COLOR="\e[38;5;202m"
    TOO_HIGH_DELTA_S_LISTSTATUS_COLOR="\e[0;91m"
    RUNNING_LISTSTATUS_COLOR="\e[0;32m"
    PENDING_LISTSTATUS_COLOR="\e[0;33m"
    CLEANING_LISTSTATUS_COLOR="\e[0;31m"
    STUCK_SIMULATION_LISTSTATUS_COLOR="\e[0;91m"
    FINE_SIMULATION_LISTSTATUS_COLOR="\e[0;32m"

    #Variables for acceptances/deltaS thresholds
    TOO_LOW_ACCEPTANCE_THRESHOLD=68
    LOW_ACCEPTANCE_THRESHOLD=70
    HIGH_ACCEPTANCE_THRESHOLD=78
    TOO_HIGH_ACCEPTANCE_THRESHOLD=90
    DELTA_S_THRESHOLD=6
}
