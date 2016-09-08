#!/bin/bash
S=$(realpath "$0")
RWORK=$(dirname $(dirname "$S"))

. "$RWORK/env.sh" || exit 1

load_confs () {
  if [ -e "$1" ]; then
    _cmt="$2"
    (ls "$1/"*.conf 2>/dev/null) | while read l; do echo "$_cmt## source: $l"; cat "$l"; echo; done
    (ls "$1/"*.sh 2>/dev/null) | while read l; do echo "$_cmt## source: $l"; . "$l"; echo; done
  fi
}

_ed() {
  . "$SHCP_HOME/default/conf.d/$1"
}


_setup() {
  user="$USER"
  home="$HOME"

  echo "cat > $TMPFILES_D_DIR/shcp-$USER.conf <<'EOF'"
  _ed tmpfiles.sh
  load_confs 'tmpfiles.conf.d'
  echo EOF

  echo "cat > $SUPERVISOR_CONF_D_DIR/shcp-$USER.conf <<'EOF'"
  _ed supervisor.sh
  load_confs 'supervisor.conf.d'
  echo EOF

  echo "cat > $PHP_FPM_POOL_D_DIR/shcp-$USER.conf <<'EOF'"
  _ed php-fpm.sh
  load_confs 'php-fpm.conf.d'
  echo EOF

  echo "cat > $NGINX_CONF_DIR/shcp/u/$USER.conf <<'EOF'"
  _ed nginx.sh
  load_confs 'nginx.conf.d'
  echo EOF

  echo "[ ! -e '/run/$USER/shcp' ] && mkdir -pv '/run/$USER/shcp' && chown -vR '$USER.$USER' '/run/$USER'"
}

_init() {
  export SHCP_HOME="$HOME/shcp"
  [ ! -d "$SCP_HOME" ] && mkdir -pv "$SHCP_HOME" || exit 1
  cd "$SHCP_HOME"
  echo "$RWORK" > .shcp_root
  echo 'bin
log
default
default/conf.d
default/conf.d/nginx
default/conf.d/nginx/php
default/conf.d/nginx/dj
nginx.conf.d
php-fpm-pool.conf.d
python/django-apps.conf.d
supervisor.conf.d
supervisor.conf.d/dj
tmpfiles.d
env
www/dj
' | while read l; do [ "$l" != '' ] && [ ! -e "shcp/$l" ] && mkdir -pv "$l" && touch "$l/.ignore"; done

  [ ! -e ".env" ] && echo '
export SHCP_HOME=$(dirname $(realpath "$BASH_SOURCE")) || exit 1
export SHCP_ROOT=$(cat "$SHCP_HOME/.shcp_root") || exit 1
. "$SHCP_ROOT/env.sh"
. "$SHCP_HOME/env/default.sh"
' > .env

  [ ! -e "www/php" ] && (cd www && ln -vs "../../public_html" ./php)

  [ ! -e "$HOME/public_html" ] && mkdir -v "$HOME/public_html"

  (cd "$RWORK/template" && find . -type f | grep -v '.swp') | while read l; do
    l=${l##./}
    [ ! -e "$l" ] && ln -vs "$RWORK/template/$l" "$l"
  done

  return 0

}

_setup_root() {
  www="/var/www/u"

  [ ! -e "$www" ] && mkdir -p "$www"
  [ ! -e "$NGINX_CONF_DIR/shcp/u" ] && mkdir -pv "$NGINX_CONF_DIR/shcp/u"

  (ls "$RWORK/setup.d/"*.sh 2>/dev/null) | while read l; do
    . "$l"
  done

  while read u; do
    read h
    w="$h/shcp"

    [ ! -e "$w/.env" ] && continue
    su - "$u" -c "$S setup"
    [ ! -e "$www/$u" ] && ln -vs "$w/www" "$www/$u"
  done < <(awk -F':' '{print $1"\n"$6}' /etc/passwd)

  echo "$NGINX_INIT_CMD restart || exit \$?"
  echo "$PHP_FPM_INIT_CMD restart || exit \$?"
  echo "$SUPERVISOR_CTL_UPDATE_CMD || exit \$?"
}

if [ "$1" = 'init' ]; then
  _init
  exit $?
fi

if [ "$1" = 'init_user' ]; then
  su - "$2" -c "$0 init" 
  exit $?
fi

if [ "$1" = 'setup' ]; then
  if [ "$USER" != 'root' ]; then
    cd ~
    cd shcp || exit 1
    . ./.env || exit 1
    _setup
  else
    _setup_root
  fi
  exit $?
fi