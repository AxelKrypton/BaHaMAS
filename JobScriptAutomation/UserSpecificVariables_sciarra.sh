# Paths on LOEWE using CL2QCD
USER_MAIL="sciarra@th.physik.uni-frankfurt.de"
HMC_BUILD_PATH="clhmc/build/RefExec"
SIMULATION_PATH="WilsonProject"
HOME_DIR="/home/hfftheo/sciarra" 
WORK_DIR="/scratch/hfftheo/sciarra" 
SCRIPT_DIR="$HOME_DIR/Script/tmLQCD_Juqueen" #Needed on loewe?
PRODUCEJOBSCRIPTSH="$HOME_DIR/Script/JobScriptAutomation/ProduceJobScript.sh"
PRODUCEINPUTFILESH="$HOME_DIR/Script/JobScriptAutomation/ProduceInputFile.sh"
HMC_FILENAME="hmc_ref"
HMC_GLOBALPATH="$HOME_DIR/$HMC_BUILD_PATH/$HMC_FILENAME"
INPUTFILE_NAME="hmc.input"
JOBSCRIPT_PREFIX="job.hmc.cl2qcd.loewe"
OUTPUTFILE_NAME="hmc_output"
THERMALIZED_CONFIGURATIONS_PATH="$HOME_DIR/$SIMULATION_PATH/Thermalized_Configurations"
GPU_PER_NODE=4
JOBSCRIPT_LOCALFOLDER="JobScripts"