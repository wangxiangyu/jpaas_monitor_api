#!/bin/bash 
export PATH=/home/work/dashboard/jpaas_monitor_api/env/ruby193/bin:$PATH
do_start()
{
        bundle exec rackup -p 8002 &>/home/work/dashboard/jpaas_monitor_api/log/jpaas_monitor_api.log &
        echo $! >/home/work/dashboard/jpaas_monitor_api/status/collector_pid
}

do_stop()
{
        pid=$(cat /home/work/dashboard/jpaas_monitor_api/status/collector_pid)
        kill -9 ${pid}
}

case C"$1" in
    Cstart)
        echo "Starting ... "
        do_start
        ;;
    Cstop)
        echo "Stopping ... "
        do_stop
        ;;
    *)
        echo "Usage: $0 {start|stop}" >&2
        exit 3
        ;;
esac
