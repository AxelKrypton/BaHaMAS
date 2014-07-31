# Paths on LOEWE using CL2QCD
USER_MAIL="sciarra@th.physik.uni-frankfurt.de"
HMC_BUILD_PATH="clhmc/build/RefExec"
SIMULATION_PATH="WilsonProject"
HOME_DIR="/home/hfftheo/sciarra" 
WORK_DIR="/scratch/hfftheo/sciarra" 
SCRIPT_DIR="$HOME_DIR/Script/tmLQCD_Juqueen" #Needed on loewe?
PRODUCEJOBSCRIPTSH="$HOME_DIR/Script/JobScriptAutomation/ProduceJobScript.sh"
PRODUCEINPUTFILESH="$HOME_DIR/Script/JobScriptAutomation/ProduceInputFile.sh"
HMC_TM_FILENAME="hmc_ref"
HMC_TM_GLOBALPATH="$HOME_DIR/$HMC_BUILD_PATH/$HMC_TM_FILENAME"
INPUTFILE_NAME="hmc.input"
JOBSCRIPT_PREFIX="job.hmc.cl2qcd.loewe"
OUTPUTFILE_NAME="hmc.output"
