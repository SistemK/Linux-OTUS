# Описание

Работа с LVM
на имеющемся образе
/dev/mapper/VolGroup00-LogVol00 38G 738M 37G 2% /

уменьшить том под / до 8G
выделить том под /home
выделить том под /var
/var - сделать в mirror
/home - сделать том для снэпшотов
прописать монтирование в fstab
попробовать с разными опциями и разными файловыми системами ( на выбор)
- сгенерить файлы в /home/
- снять снэпшот
- удалить часть файлов
- восстановится со снэпшота
- залоггировать работу можно с помощью утилиты screen

* на нашей куче дисков попробовать поставить btrfs/zfs - с кешем, снэпшотами - разметить здесь каталог /opt

# Выполнение

### Уменьшить том под / до 8G

Решил опробовать сценарий без использования LiveCD<br>
Вывод df -Th, mount, lvs, vgs, lsblk в файле log

Подготавливаем новую VG для временного рута
```
yum install xfsdump -y
pvcreate /dev/sdb
vgcreate vg_root
vgcreate vg_root /dev/sdb
lvcreate -n lv_root -l +100%FREE /dev/vg_root
mkfs.xfs /dev/vg_root/lv_root 
mount /dev/vg_root/lv_root /mnt
yum install xfsdump
xfsdump -f /tmp/root.dump /dev/VolGroup00/LogVol00
xfsrestore -f /tmp/root.dump /mnt/
```

У нас готов том для / раздела <br>
Далее апдейтим загрузчик и конфиг grub для текущего ядра и initramfs

```bash
$ for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
$ chroot /mnt/
$ grub2-mkconfig -o /boot/grub2/grub.cfg 
$ cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done
```

Для того, чтобы загрузиться с нового девайся, идём в `vi /boot/grub2/grub.cfg` и меняем `rd.lvm.lv=VolGroup00/LogVol00` на `rd.lvm.lv=vg_root/lv_root`

Перезагружаемся успешно с новым рут томом.<br>
Теперь нам нужно изменить размер старой VG и вернуть на него рут:

```bash
# Переделываем VG под рут
lvremove /dev/VolGroup00/LogVol00
lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
mkfs.xfs /dev/VolGroup00/LogVol00
mount /dev/VolGroup00/LogVol00 /mnt
# Удаляем старый дамп
rm -f /tmp/root.dump
# Делаем новый дамп и восстаналиваем его на только, что подхотовленный том
xfsdump -f /tmp/root.dump /dev/vg_root/lv_root
xfsrestore -f /tmp/root.dump /mnt/
```
У нас готов том для / раздела
Далее апдейтим загрузчик и конфиг grub для текущего ядра и initramfs

```bash
$ for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
$ chroot /mnt/
$ grub2-mkconfig -o /boot/grub2/grub.cfg 
$ cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done
```
Пока не перезагружаемся и не выходим из под chroot - нам надо заодно перенести /var <br>

### Выделить том под /var

/var - сделать в mirror

```bash
pvcreate /dev/sdc /dev/sdd
vgcreate vg_var /dev/sdc /dev/sdd
lvcreate -L 950M -m1 -n lv_var vg_var
mkfs.ext4 /dev/vg_var/lv_var
mount /dev/vg_var/lv_var /mnt
cp -aR /var/* /mnt/          # rsync -avHPSAX /var/ /mnt/
mkdir /tmp/oldvar
mv /var/* /tmp/oldvar
umount /mnt
mount /dev/vg_var/lv_var /var 
# Правим fstab для автоматического монтирования /var
```

После чего успешно перезагружаемся в новый рут

Удаляем временную VG
```bash
lvremove /dev/vg_root/lv_root
vgremove /dev/vg_root
pvremove /dev/sdb
```

### Выделить том под /home
```bash
lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
mkfs.xfs /dev/VolGroup00/LogVol_Home
mount /dev/VolGroup00/LogVol_Home /mnt/
cp -aR /home/* /mnt/        
rm -rf /home/*
umount /mnt
mount /dev/VolGroup00/LogVol_Home /home/
# Правим fstab для автоматического монтирования /home
```

### home - снэпшоты
```
# Сгенерить файлы в /home/
touch /home/file{1..20}

# Снять снэпшот
lvcreate -L 2GB -s -n home_snap /dev/VolGroup00/LogVol_Home

# Удалить часть файлов
rm -f /home/file{11..20}

# Восстановится со снэпшота
umount /home
lvconvert --merge /dev/VolGroup00/home_snap
mount /home
```

### На нашей куче дисков попробовать поставить btrfs/zfs - с кешем, снэпшотами - разметить здесь каталог /opt

## btrfs
Имеются 4 диска: sd{d,e,fg}
Из их будет делать RAID10

```bash
mkfs.btrfs -f -d raid10 -m raid10 /dev/sdd /dev/sde /dev/sdf /dev/sdg
# Без разницы какой том монтируем, они в рейде
mount /dev/sdd /opt/
umount /opt
mount /dev/sde
# Все файлы на месте
```
Полезные команды
```bash
btrfs filesystem show /dev/sdd
btrfs filesystem df /
btrfs filesystem usage /opt
```

Создаём subvolume и snapshot
```
# Subvolume и оригинальный файлик в него
btrfs subvolume create /opt/data
btrfs subvolume create /opt/data/orig
echo "This is original file" > /opt/data/orig/file
# Создаём snapshot
btrfs subvolume snapshot /opt/data/orig/ /opt/data/backup
# Листинг subvolume (узнаем ID для восстановления)
btrfs subvolume list /opt
# Делаем snapshot дефолтным томом
# Перед этим поправим файлик, чтобы видеть изменения
btrfs subvolume set-default 258 /opt
umount /opt/data
mount /dev/sdd /opt/data
# После чего мы имеем оригинальный файл в ветке orig
```



