#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

# Useful reference: http://misc.flogisoft.com/bash/tip_colors_and_formatting

#TODO: Some of the functionality used here could be not present in
#      different environment. Probably it should be considered to
#      build some functionality on top. For example, here the 256
#      colors are used but it could be useful to provide a 8 colors
#      only alternative, which is widely supported (mapping the 256
#      used colors back to 8 colors).
#      For the moment we give the possibility to the user to deactivate
#      completely colors, loosing then some database functionality.
#
#TODO: Colors in BaHaMAS have been chosen thinking to dark terminal
#      background. Implement here some functionality to provide a
#      version of colors which are well suited for light bg terminal.

function __static__SetFormatCodes()
{
    formatCodes[B]="${escape}1m"   # bold
    formatCodes[U]="${escape}4m"   # underlined
    formatCodes[uB]="${escape}21m" # u-bold
    formatCodes[uU]="${escape}24m" # u-underlined
}

function __static__SetColorCodes()
{
    #Default format
    colorCodes[d]="${escape}0m"          # default
    #Font standard 8 color
    colorCodes[bk]="${escape}30m"        # black
    colorCodes[r]="${escape}31m"         # red
    colorCodes[g]="${escape}32m"         # green
    colorCodes[y]="${escape}33m"         # yellow
    colorCodes[b]="${escape}34m"         # blue
    colorCodes[m]="${escape}35m"         # magenta
    colorCodes[c]="${escape}36m"         # cyan
    colorCodes[gr]="${escape}37m"        # gray
    #Font standard bright 8 color
    colorCodes[dgr]="${escape}90m"       # d-gray
    colorCodes[lr]="${escape}91m"        # light red
    colorCodes[lg]="${escape}92m"        # light green
    colorCodes[ly]="${escape}93m"        # light yellow
    colorCodes[lb]="${escape}94m"        # light blue
    colorCodes[lm]="${escape}95m"        # light magenta
    colorCodes[lc]="${escape}96m"        # light cyan
    colorCodes[w]="${escape}97m"         # white
    #Font 256 colors
    colorCodes[bb]="${escape}38;5;26m"   # bright blue
    colorCodes[bc]="${escape}38;5;45m"   # bright cyan
    colorCodes[wg]="${escape}38;5;48m"   # water green
    colorCodes[yg]="${escape}38;5;118m"  # yellow green
    colorCodes[p]="${escape}38;5;135m"   # purple
    colorCodes[lp]="${escape}38;5;147m"  # light purple
    colorCodes[pk]="${escape}38;5;198m"  # pink
    colorCodes[o]="${escape}38;5;202m"   # orange
    colorCodes[lo]="${escape}38;5;208m"  # light orange
}

function __static__SetEmphasizeCodes()
{
    local code
    for code in "${!colorCodes[@]}"; do
        emphCodes[$code]=d
    done
    emphCodes[r]=y
    emphCodes[y]=r
    emphCodes[b]=m
    emphCodes[m]=c
    emphCodes[c]=b
    emphCodes[lr]=ly
    emphCodes[ly]=lr
    emphCodes[lb]=lm
    emphCodes[lm]=lc
    emphCodes[lc]=lb
    emphCodes[bb]=lc
    emphCodes[bc]=lc
    emphCodes[p]=lm
    emphCodes[lp]=pk
    emphCodes[pk]=lc
    emphCodes[o]=ly
    emphCodes[lo]=ly
}

function cecho()
{
    local escape endline format previousFormat previousColor\
          text outputString defaultFormat fileFormat dirsFormat restore
    declare -A formatCodes colorCodes emphCodes
    escape="\033["; endline="\n"; defaultFormat="${escape}0m"
    format=''; previousFormat=''; previousColor=''; text=''; outputString=''
    fileFormat="${escape}0;38;5;48m"; dirsFormat="${escape}0;94m"; restore='FALSE'
    __static__SetFormatCodes
    __static__SetColorCodes
    __static__SetEmphasizeCodes
    while [ "$1" != '' ]; do
        case "$1" in
            #Font format
            B | U | uB | uU )
                format="${formatCodes[$1]}"
                previousFormat+="$format" ;;
            d | bk | r | g | y | b | m | c | gr | dgr | lr | lg | ly | lb | lm | lc | w | bb | bc | wg | yg | p | lp | pk | o | lo )
                format="${colorCodes[$1]}"
                previousColor="$1"; previousFormat="$format" ;;
            #classes of strings to highlight
            file) format="$fileFormat"; shift; text="$1"; restore='TRUE' ;;
            dir)  format="$dirsFormat"; shift; text="$1"; restore='TRUE' ;;
            emph)
                if [ "$previousColor" != '' ]; then
                    format="${colorCodes[${emphCodes[$previousColor]}]}"
                    shift; text="$1"; restore='TRUE'
                fi ;;
            #Other options
            -n) endline='' ;;
            -d) defaultFormat='' ;;
            *) text="$1"
        esac
        shift
        if [ "$format" != '' ]; then
            [ "$BaHaMAS_colouredOutput" = 'TRUE' ] && outputString+="$format"
        fi
        if [ "$text" != '' ]; then
            outputString+="$text"
            if [ $restore = 'TRUE' ]; then
                [ "$BaHaMAS_colouredOutput" = 'TRUE' ] && outputString+="$previousFormat"
            fi
            restore='FALSE'
        fi
        format=''; text='' #To avoid to put them again in outputString
    done
    outputString+="$defaultFormat$endline"
    printf "$outputString"
}

function AskUser()
{
    cecho -n "\n" lc " $1" "[Y/N] "
}

function UserSaidYes()
{
    local userAnswer
    while read userAnswer; do
        if [ "$userAnswer" = "Y" ]; then
            return 0
        elif [ "$userAnswer" = "N" ]; then
            return 1
        else
            printf "\n Please enter Y (yes) or N (no): "
        fi
    done
}

function UserSaidNo()
{
    if UserSaidYes; then
        return 1
    else
        return 0
    fi
}


#format="${escape}38;5;9m  " ;;    lr
#format="${escape}38;5;10m " ;;    lg
#format="${escape}38;5;11m " ;;    ly
#format="${escape}38;5;13m " ;;    lm
#format="${escape}38;5;27m " ;;    bb
#format="${escape}38;5;34m " ;;     g
#format="${escape}38;5;39m " ;;     b
#format="${escape}38;5;49m " ;;    wg
#format="${escape}38;5;69m " ;;     b
#format="${escape}38;5;83m " ;;    wg
#format="${escape}38;5;86m " ;;    lc
#format="${escape}38;5;123m" ;;    lc
#format="${escape}38;5;171m" ;;     p
#format="${escape}38;5;207m" ;;    lm
