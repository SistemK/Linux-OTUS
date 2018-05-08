#!/bin/bash
# Данный скрипт содаёт RAID 6 на предоствленных девайсах,
# разбивает его на пять партиций и монтирует их по каталогам

echo "Start creating RAID"
echo " "

# Создаем RAID 
mdadm --create /dev/md0 -l 6 -n 5 /dev/sd{c,d,e,f,g}

# Проверяем успешно ли создался
mdadm -D /dev/md0
if [ $? == 0 ]
then
    echo "RIAD created succesfuly"
else
    echo "RAID was not created"
fi


# В цикле создаем партиции на предоставленном девайсе
for part in {1..5}
do
# делаем так, что gdisk ожидает любой из предложенных симоволов (цифры и буквы)
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | gdisk /dev/md0
  n


  +100M

  w
  Y
EOF
done

# Создаём файловые системы на предоставленных девайсах
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done

# Создаём папки куда будем монтировать
mkdir /u0{1,2,3,4,5}

# Прописываем в /etc/fstab
echo "#Our new devices" >> /etc/fstab
for i in $(seq 1 5)
do 
    echo `sudo blkid /dev/md0p$i | awk '{print $2}'` /u0$i ext4 defaults 0 0 >> /etc/fstab
done

# Монитруем по папкам
mount -a

echo " "
echo "Done creating RAID"