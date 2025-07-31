#!/bin/bash -l

LOCAL_PARSE_OPTIONS="a:c:o:"

Usage () {
    cat <<EOF

    Purpose   : Start/stop a CMAN configuration

    Usage: $(basename "$0") -a {start|stop|reload|restart|status} -c <config_name> -o <oracle_home>

    Options:
        -a action           One in start|stop|reload|restart|status
        -c config_name      Name of the cman instance (e.g. ais-prod, gen-prod, etc.)
        -o oracle_home      The ORACLE_HOME path that must be used for the operation (e.g. cman1930)
EOF
}

CENTRAL_CONFIG_DIR=/base/app/oracle/network/admin

while getopts ":${LOCAL_PARSE_OPTIONS}" opt ; do
    case $opt in
        a)
            L_Action=$OPTARG
            ;;
        c)
            L_Config=$OPTARG
            ;;
        o)
            L_OH=$OPTARG
            ;;
        \?)
            echo "Error: Invalid option -$OPTARG"
            Usage
            exit 1
            ;;
        :)
            echo "Error: Option -$OPTARG requires an argument."
            Usage
            exit 1
            ;;
    esac
done

# Validate configuration directory
if [ ! -d "$CENTRAL_CONFIG_DIR" ]; then
    echo "Error: Central configuration directory $CENTRAL_CONFIG_DIR does not exist."
    exit 1
fi

# Validate config name
if [ -z "$L_Config" ]; then
    Usage
    echo "Please specify a configuration name with -c. Possible values are:"
    ls -1 "$CENTRAL_CONFIG_DIR" | sed -e "s/\.ora//" | grep -v cman
    exit 1
fi

# Validate ORACLE_HOME
if [ -z "$L_OH" ] || [ ! -f "$L_OH/bin/cmctl" ]; then
    Usage
    echo "Please set a valid ORACLE_HOME path with -o."
    exit 1
fi

export ORACLE_HOME=$L_OH
export TNS_ADMIN=$CENTRAL_CONFIG_DIR

case $L_Action in
    start)
        $ORACLE_HOME/bin/cmctl startup -c $L_Config
        ;;
    stop)
        $ORACLE_HOME/bin/cmctl shutdown -c $L_Config
        ;;
    reload)
        $ORACLE_HOME/bin/cmctl reload -c $L_Config
        ;;
    restart)
        $ORACLE_HOME/bin/cmctl shutdown -c $L_Config
        sleep 1
        $ORACLE_HOME/bin/cmctl startup -c $L_Config
        ;;
    status)
        $ORACLE_HOME/bin/cmctl show status -c $L_Config
        $ORACLE_HOME/bin/cmctl show status -c $L_Config | grep "The command completed successfully." >/dev/null
        ;;
    *)
        echo "Invalid action: $L_Action"
        Usage
        exit 1
        ;;
esac