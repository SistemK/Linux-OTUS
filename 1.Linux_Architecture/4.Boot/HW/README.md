# Описание

## Работа с загрузчиком
1. Попасть в систему без пароля несколькими способами
2. Установить систему с LVM, после чего переименовать VG
3. Добавить модуль в initrd

## Работа с загрузчиком (*)
Сконфигурировать систему без отдельного раздела с /boot, а только с LVM
Репозиторий с пропатченым grub: https://yum.rumyantsev.com/centos/7/x86_64/
PV необходимо инициализировать с параметром --bootloaderareasize 1m

# Выполнение

## Попасть в систему без пароля несколькими способами

### Способ 1. init=/bin/sh

1. В конце строки `^linux16` добавляем `init=/bin/sh`

### Cпособ 2. rd.break

1. В конце строки `^linux16` добавляем `rd.break`

```
mount -o remount,rw /sysroot
chroot /sysroot
passwd root
touch /.autorelabel
```

### Способ 3. rw init=/sysroot/bin/sh

1. В строке `^linux16` `ro` заменяем на `rw init=/sysroot/bin/sh`

Таким образом `sysroot` сразу монтируется в read-write

### Cпособ 4. Изменение rescue/emergency.service файлов

1. vi /usr/lib/systemd/system/{rescue,emergency}.service
2. В строке `ExecStart` правим `/usr/sbin/sulogin` на `/usr/sbin/sushell` и у нас перестают спрашивать логин. Запускается сразу в bash

### Способ 5. LiveCD

Ну тут всё просто =)

## Установить систему с LVM, после чего переименовать VG

vgrename centos otus-centos