
find_depends_version() {
    packagename=$1
    local dependpath=$2

    for i in `echo n|apt install $packagename |grep --color=auto -Eo 'Depends: .* but'|awk -F ' ' '{print $2$3$4}'| grep "("`
    do
        local substr=$i
        subname=`echo $substr| awk -F '(' '{print $1}'`
        opstr=`echo $substr| awk -F '(' '{print $2}'|awk -F ")" '{print $1}'| grep -Eo "[>,>=,=,!=,<,<=]{1,2}"`
        reqversion=`echo $substr| awk -F '(' '{print $2}'|awk -F ")" '{print $1}'| awk -F "$opstr" '{print $2}'`

        apt search $subname| grep $subname/ >/dev/null
        if [ $? -eq 0 ]
        then
            searchversion=`apt search $subname| grep -E "^$subname/"| awk -F ' ' '{print $2}'`
            op=""
            case $opstr in 
                ">")
                op="gt"
                ;;
                ">=")
                op="ge"
                ;;
                "!=")
                op="ne"
                ;;
                "=")
                op="eq"
                ;;
                "<=")
                op="le"
                ;;
                "<")
                op="lt"
                ;;
            esac
            
            dpkg --compare-versions $searchversion  $op $reqversion
            if [ $? -ne 0 ]
            then
                echo "$dependpath->$subname version is $searchversion, but require $opstr $reqversion"
            else
                find_depends_version $subname "$dependpath->$subname"
            fi
        else
            echo "$dependpath->$subname not found"
        fi
    done
}


find_depends() {
    local packagename=$1
    local dependpath=$2

    for i in `echo n|apt install $packagename|grep --color=auto -Eo 'Depends: .* but'|awk -F ' ' '{print $2}'`
    do
        local subname=$i
        apt search $subname| grep $subname >/dev/null 2>&1
        if [ $? -eq 0 ]
        then
            find_depends $subname "$dependpath->$subname"
            find_depends_version $subname "$dependpath->$subname"
        else
            echo "$dependpath->$subname not found"
        fi
    done
}

find_depends_version $1 $1
find_depends $1 $1
