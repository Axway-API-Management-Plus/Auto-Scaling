#! /bin/sh
# chkconfig: 2345 99 99
# description: Configure API GAteway Admin Node Manager or Node Manager with admin capabilties

### BEGIN INIT INFO
# Provides:             InstallAdminNodeManager
# Required-Start:       $remote_fs $network
# Required-Stop:        $remote_fs $network
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description:    InstallAdminNodeMInstallAdminNodeManageranager
### END INIT INFO


do_status() {
                echo
}

do_start() {
                touch /var/lock/subsys/ANMConf
                cd /tmp
                rm -fr /tmp/*
                wget -q https://s3.amazonaws.com/admin-node-manager/scripts/common_variables.sh
                chmod 777 common_variables.sh
                wget -q https://s3.amazonaws.com/admin-node-manager/scripts/script_install_adminnodemanager.sh
                chmod 777 script_install_adminnodemanager.sh
                wget -q https://s3.amazonaws.com/admin-node-manager/scripts/script_uninstall_adminnodemanager.sh
                chmod 777 script_uninstall_adminnodemanager.sh
                #. $(dirname $0)/script_install_adminnodemanager.sh
                ./script_install_adminnodemanager.sh
}
do_stop() {
                rm -f /var/lock/subsys/ANMConf
                cd /tmp
                ./script_uninstall_adminnodemanager.sh
}


do_reload() {
                echo
}

do_status() {

                echo
}

case "$1" in
  start)
        do_start
        exit 0
        ;;
  stop)
        do_stop
        exit 0
        ;;
  status)
        do_status
        exit 0
        ;;
  reload)
        do_reload
        ;;
  restart)
        # check the status, if it is running stop it
        ;;
  *)
        echo "Usage: $SCRIPTNAME {start|stop|status|reload|restart}" >&2
        exit 3
        ;;
esac