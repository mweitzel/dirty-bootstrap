#!/bin/bash

set -e
set -x

function escelate_privileges() {
  test -n "$SECRETS_UNAME"
  test -n "$SECRETS_PASS"
  test -n "$SECRETS_LOCATION"
  test -n "$REMEMBER_SECRETS_CERT"
  test -f secrets.crt
  local filenames=(id_ed25519 id_ed25519.pub .secrets.env)
  for filename in "${filenames[@]}"
  do
    echo curl https://"$SECRETS_UNAME":"$SECRETS_PASS"@"$SECRETS_LOCATION"/"$filename" --cacert secrets.crt > "$filename"
  done

  cp id_ed25519 ~/.ssh/id_ed25519
  cp id_ed25519.pub ~/.ssh/id_ed25519.pub
  source .secrets.env
}

function source_env() {
  test -f ~/.env && source ~/.env
}

function dependencies() {
  which git && return 0
  apt-get update
  apt-get install -y git
}

function init_system_main() {
  test -f /etc/rc.local && return 0
  touch /etc/rc.local
  chmod 755 /etc/rc.local
  echo '#!/bin/sh -e

~/repo/start

exit 0
' > /etc/rc.local
}

function clone() {
  git clone "$MAIN_REPO" repo
  cd ./repo
  exec ./init
}

function main() {
  source_env
  escelate_privileges
  dependencies
  clone
  init_system_main
  echo ok
}

main

# if no git:
#   bash <(curl -s https://raw.githubusercontent.com/mweitzel/dirty-bootstrap/main/init.sh)
