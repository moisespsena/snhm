
main() {
  local php_uri="$user_uri/public"
  local php_sock="/run/$user/snhm/php-fpm.sock"

  echo "location $php_uri {"
  echo

  local base_path=$(dirname "$BASH_SOURCE")

  if [ -e "$base_path/public" ]; then
   (ls -1 "$base_path/public/"*.sh 2>/dev/null) | while read l; do
      echo "# START-SOURCE: $l"
      . "$l" || exit $?
      echo "# END-SOURCE: $l"
    done
  fi

  echo "
  location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:$php_sock;
  }

  if (-f \"\$request_filename/index.php\") {
    rewrite (.+)/$ \$1/index.php last;
  }

  try_files \$uri \$uri/ =404;

  break;
}"
}

main
