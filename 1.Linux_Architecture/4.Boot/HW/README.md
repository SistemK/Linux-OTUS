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

## 1. Попасть в систему без пароля несколькими способами

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

## 2. Установить систему с LVM, после чего переименовать VG

1. Переименовываем Volume Group

`vgrename -v <old-name> <new-name>`

2. Правим /etc/fstab, /etc/default/grub, /boot/grub2/grub.cfg. Везде заменяем старое название на новое.

3. Пересоздаём имадж initramfs, чтобы он знал новое название

`mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)`

4. Перезагружаемся

## 2. Добавить модуль в initrd

Скрипты модулей хранятся в /usr/lib/dracut/modules.d/

* Создаём там папку 01test

 * В ней у нас будет два скрипта:
<details>
<summary>1. module_setup.sh - который устанавливает модуль и вызывает скрипт test.sh </summary>

```bash
#!/bin/bash

check() {
    return 0
}

depends() {
    return 0
}

install() {
    inst_hook cleanup 00 "${moddir}/test.sh"
}
```
</details>

<details>
<summary>2. test.sh - собственно сам вызываемый скрипт, в нём у нас рисуется пингвинчик</summary>

```bash
#!/bin/bash

exec 0<>/dev/console 1<>/dev/console 2<>/dev/console
cat <<'msgend'

Hello! You are in dracut module!

 ___________________
< I'm dracut module >
 -------------------
   \
    \
        .--.
       |o_o |
       |:_/ |
      //   \ \
     (|     | )
    /'\_   _/`\
    \___)=(___/
msgend
sleep 10
echo " continuing...."
```

</details>

 * Пересобираем образ initrd 

 `mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)`

 * Можно проверить/посмотерть какие модули загружены в образ

 `lsinitrd -m /boot/initramfs-$(uname -r).img` - если всё прошло успешно, то там будет модуль с нашим именем `test`

 * Вот сейчас неуверенная часть, но я пока только такой нашёл способ увидеть модуль в деле : Убрать из параметров загрузки ядра `rghb` и `quiet` и тогда при перезагрузке можно увидеть, что скрипт вызывается
 
## Работа с загрузчиком (*)
Сконфигурировать систему без отдельного раздела с /boot, а только с LVM
Репозиторий с пропатченым grub: https://yum.rumyantsev.com/centos/7/x86_64/
PV необходимо инициализировать с параметром --bootloaderareasize 1m

Установил систему 

2. Добавляем репозиторий Александра с пропатченным Grub2

```
yum install yum-utils -y && \
yum-config-manager --add-repo https://yum.rumyantsev.com/centos/7/x86_64/
```

3. Устанавливаем пропатченный Grub2

`yum install grub2 -y --nogpgcheck`

4. 



