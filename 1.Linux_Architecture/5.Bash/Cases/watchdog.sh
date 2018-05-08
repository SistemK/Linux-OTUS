#!/bin/bash
# Wathcdog с оповещением по e-mail

# Переменные

admin=lalbrekht@gmail.com
proc=${1:-httpd}
# Проверяем запущен ли уже скрипт. Если да, то не даём запуститься второй раз.

lockdir=/tmp/myscript.lock

if mkdir "$lockdir"
then
    echo >&2 "Successfully acquired lock"
    echo ""
    # Удаляем блокировочную директора когда скрипт завершается
    # или когда он получит сигнал
    trap 'rm -rf "$lockdir"' 0    # Удаляем директория после завершения скрипта

    # Можно в этой папке разместить временные файлы,
    # они будут удалены автоматически, после завершения скрипта
    tmpfile=$lockdir/filelist

else
    echo >&2 "Cannot acquire lock, giving up on $lockdir"
    exit 0
fi

## Простой watchdog

# Функция для перезапуска сервиса
reload() {
  proc=$1  

  if systemctl start $proc
  then
    echo "Proccess $proc started succesfully"
    mailx -s "Process $proc stop working" $admin << EOF
    Process $proc started successfuly on host $HOSTNAME
EOF
    
  else
    echo "Proccess $proc can't start. See journalctl -xe for more info"
    mailx -s "Process $proc stop working" $admin << EOF
    Process $proc can't start automaticly on host $HOSTNAME
    Need your attention
EOF
  fi
}

# Проверяем запущен ли сервис
# если нет, то отправляем письмо администратору
# и пытаемся его рестартовать
if systemctl is-active $proc > /dev/null
then
  echo "Process $proc Up and Running"
else
  echo "Process $proc Stopped"
  mailx -s "Process $proc stop working" lalbrekht@gmail.com << EOF
  Process $proc stop working on host $HOSTNAME
  Tring to auto reload it
EOF
  echo "Trying to start $proc"
  reload $proc
fi
