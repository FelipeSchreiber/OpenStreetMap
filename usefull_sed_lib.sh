function escape_slashes()
{
    local var_esc=$(echo $1 | sed 's_/_\\/_g')
    echo $var_esc
}

## SED -e 's/KEYWORD/REPLACE/'
function escape_replace()
{
    local var_esc="$(echo "$1" | 
    sed -e 's/[&\\/]/\\&/g; s/$/\\/' -e '$s/\\$//')"
    echo "$var_esc"
}

function escape_keyword()
{
    local var_esc=$(echo $1 | sed -e 's/[]\/$*.^[]/\\&/g')
    echo $var_esc
}

function replace_between_START_END_REPLACE_FILENAME()
{
    local BEGIN="$1"
    local END="$2"
    local REPLACE="$3"
    local filename="$4"
    ## between \Q\E is taken as literal
    #perl -0777 -pi "s/\Q${BEGIN}\E[^${END}]*\Q${END}\E/${BEGIN}${REPLACE}${END}/" "$filename"
    sed -i "/$BEGIN/,/$END/c${BEGIN}${REPLACE}${END}/p" $filename
    #https://stackoverflow.com/questions/2156731/how-do-i-escape-special-chars-in-a-string-i-interpolate-into-a-perl-regex
}