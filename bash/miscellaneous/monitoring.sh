#!/bin/bash
# скрипт для Сани.
# цикл в котором всё и происходит
while true; do
    #очистка консоли
        clear
    #окраска раздела
        echo -e "\e[33m"
    #вывод информации о конкретном диске
			df -h /dev/sda3

        # вывод информации о процесах
            # postgresql
            echo -e "\e[0m postgresql:\e[36m"
                ps aux | grep -i postgresql |grep -v grep| nl;

            # screen
            echo "";
            echo -e "\e[0m screen:\e[36m"
                ps aux | grep -i screen |grep -v "grep"| nl;

            # tar
            echo "";
            echo -e "\e[0m tar:\e[36m"
                ps aux | grep -i "tar " |grep -v "grep"| nl;

       # uptime что бы посмотреть загрузку проца
        echo -e "\e[31m"
            uptime;

        # перекраска текста и далее смотрим размеры интересующих объектов
        echo -e "\e[32m";

        du -hs /DATA/pg_cluster
        echo "";
        du -hs /DATA/pg_backup/clusters/*

        # статус наблюдаемого демона ()
        echo "";
        /etc/init.d/postgresql status

        # задержка перед следующей итерацией
        sleep 10s

done