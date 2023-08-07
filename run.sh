#!/bin/bash
DEFAULT_COUNTRY="iran-latest"

function execute {
    #USAGE: execute
    #Developed to write stdout into output.txt
    #Inputs:
    #       $@: command with args
    #OUTPUT: command outputs
    #RETURN CODES: command

    #execute command and pipe it to tee to store at output.txt
    if [ "$1" == "echo" ]; then
        $@ 2>&1| tee -a output.txt
    else
        echo "Executing: $@" >> output.txt
        $@ 2>&1| tee -a output.txt
    fi
}

function destroy_containers {
    #USAGE: destroy containers
    #Developed to stop and delete 
    #Inputs: none
    #OUTPUT: command outputs
    #RETURN CODES: command, failed"1"

    #stop containers and delete them 
    execute echo "destroying containers"
    get_status >/dev/null 
    local RETURN_CODE=$?
    if [ $RETURN_CODE -ne 2 ] ;then
        execute docker compose down
        execute echo "-----------------------"
        return $?
    else
        execute echo "no containers found!"
        execute echo "-----------------------"
        return 1
    fi
    
}

function setup {
    #USAGE: setup
    #Developed to create and run project containers 
    #Inputs:
    #       MAP: MAP name, default value is iran-latest
    #OUTPUT: commands outputs
    #RETURN CODES: successful"0", failed"1"

    execute echo "setup started"

    local MAP="${1}"
    #check MAP if is empty set it to DEFAULT_COUNTRY
    if [ -z "${MAP}" ]; then
        MAP=$DEFAULT_COUNTRY
    fi
    local ERRORS=()


    #check if docker, docker-build, docker-compose are installed
    if ! docker --version > /dev/null ;then 
        execute echo "docker not installed" 
        ERRORS+=("docker")
    fi

    if ! docker buildx > /dev/null ;then
        execute echo "docker builder not installed" 
        ERRORS+=("docker-build")
    fi

    if ! docker compose > /dev/null ;then
        execute echo "docker compose not installed" 
        ERRORS+=("docker-compose")
    fi
    #if one of validation is not met, return error
    if [ -n "${ERRORS}" ] ;then
        execute echo "setup aborted. missing component: ${#ERRORS[@]}. missing packages: ${ERRORS[*]}"
        return 1
    fi
  
    #Exit immediately if one of commands failed for triggering trap
    set -e
    trap "set +e ;destroy_containers; trap - INT TERM EXIT ; return 1" INT TERM EXIT

    #check if MAP file exists
    if  find assets/*.osm.pbf | grep -x assets/"$MAP".osm.pbf ; then
        execute docker compose build --build-arg MAP="${MAP}" && execute docker compose up -d 
    else
        execute echo "MAP file not found. Abort setup." 
    fi
    #restore shell to default behaviare 
    set +e
    trap - INT TERM EXIT
    execute echo "setup ended succesfully"
    execute echo "-----------------------"
    return 0
}

function download_assets {
    #USAGE: download_assets
    #Developed to download MAP assets  
    #Inputs:
    #       URL:  MAP url
    #OUTPUT: commands outputs
    #RETURN CODES: successful"0", failed"1"

    #Exit immediately if one of commands failed for triggering trap
    execute echo "download started"
    set -e
    local URL="${1}"
    if [ -z "$URL" ] ; then
        echo "please specifice a URL"
        return 1
    fi
    #find filename from url
    local FILE_NAME=$(echo "${URL}" | awk -F '/' '{print $NF}')
    #if url empty return error
    if [ -z "${URL}" ] ;then
        return 1
    fi
    trap "rm -f ./assets/${FILE_NAME} ;return 1" INT TERM EXIT
    execute curl "${URL}" -o ./assets/"${FILE_NAME}"
    #restore shell to default behaviare 
    trap - INT TERM EXIT
    set +e
    execute echo "downoad ended succesfully"
    execute echo "-----------------------"
    return 0
}

function list_maps {
    #USAGE: list_maps
    #Developed to list MAP files
    #Inputs: none
    #OUTPUT: MAP List
    #RETURN CODES: none
    
    #list all osm.pbf then extract MAP filename from it
    find assets/*.osm.pbf | awk -F '/' '{print substr($NF,0,length($NF)-8)}' 
}

function get_status {
    #USAGE: get_status
    #Developed to get project status
    #Inputs: none
    #OUTPUT: project status
    #RETURN CODES: running"0", stopped"1", not found"2", unknow state"127    
    
    #if containers status equal to running(4) means project is running
    local STATUS=$(docker compose ls -a --format json | jq -r '.[] | select(.Name=="osrm-backend-nginx")|.Status')
    case $STATUS in 

        "running(4)") 
            echo "running"
            return 0
            ;;

        exited*)
            echo "stopped"
            return 1
            ;;

        '')
            echo "not found"
            return 2
            ;;

        *)
            echo "unknown state"
            return 127
            ;;
    esac
}
#a="51.42838,35.80697"
#b="51.42088,35.68590"
function get_data {
    #USAGE: get_data
    #Developed to get distance and duration based on Mode
    #Inputs: POINTA("start point"), POINTB("end point"), MODE(driving,walking,cycling)
    #OUTPUT: distance and duration based on Mode
    #RETURN CODES: failure"1"  

    #query api with two point and mode for getting duration and distance
    local POINTA=$1
    local POINTB=$2
    local MODE=$3
    if ! get_status > /dev/null ;then
        return 1
    fi
    echo "$MODE"
    curl "http://127.0.0.1:80/route/v1/$MODE/$POINTA;$POINTB" 2>/dev/null | jq -r '.routes[].legs[]|"duration: " + (.duration|tostring), "distance: "+ (.distance|tostring)'
    echo "-----------------------"

}

function start {
    #USAGE: start
    #Developed to start all containers
    #Inputs: none
    #OUTPUT: command
    #RETURN CODES: command, failed"1"  

    #start containers
    execute echo "starting containers"
    get_status >/dev/null
    local RETURN_CODE=$?
    if [ $RETURN_CODE -eq 1 ] ;then
        execute docker compose start
        execute echo "-----------------------"
        return $?
    elif [ $RETURN_CODE -eq 0 ];then
        echo "containers already running"
    elif  [ $RETURN_CODE -eq 2 ];then
        echo "no container found. run setup first"
    else
        echo "problem on starting containers"
    fi
    execute echo "-----------------------"
    return 1
}

function stop {
    #USAGE: stop
    #Developed to start all containers
    #Inputs: none
    #OUTPUT: command
    #RETURN CODES: command, failed"1"  

    #stop containers
    execute echo "stopping containers"
    get_status >/dev/null
    local RETURN_CODE=$?
    if [ $RETURN_CODE -eq 1 ] ;then
        execute echo "containers not running"
    elif [ $RETURN_CODE -eq 0 ];then
        execute docker compose stop
        execute echo "-----------------------"
        return $?
    elif  [ $RETURN_CODE -eq 2 ];then
        execute echo "no container found. run setup first"
    else
        execute echo "problem on starting containers"
    fi
    execute echo "-----------------------"
    return 1

}

function help {
    cat << SAB

Usage:
    run.sh setup -m <MAP> # setup project 
    run.sh start #start containers
    run.sh stop #stop containers
    run.sh destroy #stop and delete all containers
    run.sh download -g <URL> #download MAP file
    run.sh list #list all map files
    run.sh status #get status of containers
    run.sh get -s <FIRST_Longitude,FIRST_Latitude> -d <SECOND_Longitude,SECOND_Latitude> #get distance and duration between two point based on mode

SAB
}

#set OPTIND to 2 to getopts start from second arg and based on input fill values
OPTIND=2
while getopts 'm:g:hs:d:' option; do
  case "$option" in
    m) 
        MAP=$OPTARG
        ;;

    g)
        URL=$OPTARG
        ;;

    s)
        POINTA=$OPTARG
        ;;

    d)
        POINTB=$OPTARG
        ;;

    h)  
        help
        exit 0
        ;;

    *)
        help
        exit 1
        ;;
  esac
done


#set script action based on input
case "$1" in
    setup)
        #setup project 
        setup "${MAP}"
        ;;

    download)
        #download MAP file
        download_assets "${URL}"
        ;;

    list)
        #list all map files
        list_maps
        ;;

    status)
        #get status of containers
        get_status
        ;;

    destroy)
        #stop and delete all containers
        destroy_containers 
        ;;

    get)
        #get distance and duration between two point based on mode
        if [ -z "$POINTA" ] || [ -z "$POINTB" ] ; then
            help
            exit 1
        fi
        get_data "$POINTA" "$POINTB" "driving"
        get_data "$POINTA" "$POINTB" "walking"
        get_data "$POINTA" "$POINTB" "cycling"
        ;;
    
    start)
        start
        ;;

    stop)
        stop
        ;;

    help)
        help 
        exit 0
        ;;
    *)
        help
        exit 1
        ;;

esac
