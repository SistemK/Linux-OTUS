#!/bin/bash
# Wathcdog демон с оповещением по e-mail

# Переменные

ADMIN=lalbrekht@gmail.com
#PROC=${1:-httpd}
PROC=httpd

daemonName="$PROC-wathcdog"

logDir="."
logFile="$logDir/$daemonName-"`date +%Y-%m-%d`".log"

runInterval=30 # В секундах

## Проверяем запущен ли уже скрипт. Если да, то не даём запуститься второй раз.

lockdir=/tmp/$daemonName.lock

lock() {
  if mkdir "$lockdir"
  then
      log "Successfully acquired lock"
      echo ""
      # Удаляем блокировочную директора когда скрипт завершается
      # или когда он получит сигнал
      trap 'rm -rf "$lockdir"' 0    # Удаляем директорию после завершения скрипта

      # Можно в этой папке разместить временные файлы,
      # они будут удалены автоматически, после завершения скрипта
      tmpfile=$lockdir/filelist

  else
      echo "Error: Cannot acquire lock, giving up on $lockdir"
      log "Error: Cannot acquire lock, giving up on $lockdir"
      exit 0
  fi
}


## Предварительные настройки
# Создаем файл для лога
if [[ ! -f $logFile ]]
then
  touch $logFile
fi

############# Функции

# Функция логгирования
log() {
  echo "$1" >> "$logFile"
}


# Функция для перезапуска сервиса
reload() {
  PROC=$1  

  if systemctl start $PROC
  then
#    echo "Proccess $PROC started succesfully"
    mailx -s "CLEAR: Process $PROC stop working" $ADMIN << EOF
    CLEAR: Process $proc started successfuly on host $HOSTNAME
EOF
log "Proccess $PROC started succesfully"
  else
#    echo "Proccess $PROC can't start. See journalctl -xe for more info"
    mailx -s "ALERT: Process $PROC stop working" $ADMIN << EOF
    Process $proc can't start automaticly on host $HOSTNAME
    Need your attention
EOF
log "Proccess $PROC can't start. See journalctl -xe for more info"
  fi
}


# Проверяем запущен ли сервис
# если нет, то отправляем письмо администратору
# и пытаемся его рестартовать
wathcdog() {
  if systemctl is-active $PROC > /dev/null
  then
  #  echo "Process $PROC Up and Running"
    log "Process $PROC Up and Running"
  else
  #  echo "Process $PROC Stopped"
    log "Error: Process $PROC stoped working."
    mailx -s "ALERT: Process $PROC stoped working" $ADMIN << EOF
    ALERT: Process $proc stop working on host $HOSTNAME
    Tring to auto reload it
EOF
  #  echo "Trying to start $PROC"
    log "Trying to start $PROC"
    reload $PROC
  fi
}


# Функция для старта демона
startDaemon() {
  lock
  log '*** '`date +"%Y-%m-%d"`": Starting up $daemonName."
  loop
}


# Функция для стопа демона
stopDaemon() {
    log '*** '`date +"%Y-%m-%d"`": Stopping $daemonName."
    kill -15 `ps -ef | grep '[w]atchdog.sh' | awk '/start/{print $2}'`
}


# Зацикливаем выполнение
loop() {
  wathcdog

  sleep $runInterval
  loop  
}


# Меню
case $1 in 
  start)
    startDaemon
    ;;
  stop)
    stopDaemon
    ;;
  *)
    echo "Usage: $0 {start | stop }"
    exit 1
esac

exit 0