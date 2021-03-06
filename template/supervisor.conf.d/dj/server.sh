cat <<EOF
[program:$(dj_supervisor_program $app)-server]
user=$USER
group=$USER
directory=$dj_app_path
command=$SNHM_HOME/bin/dj-app-serve.sh $app
environment=USER="$USER",HOME="$HOME",DJ_NAME="main",ROOT_URI="/u/$USER/dj/$app"
stdout_logfile=$SNHM_HOME/log/dj-$app-server.log
stdout_logfile_maxbytes=20MB
stdout_logfile_backups=2
pidfile=/run/$USER/snhm/dj-server-default.pid
redirect_stderr=true
EOF
