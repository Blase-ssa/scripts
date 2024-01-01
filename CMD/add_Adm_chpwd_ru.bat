@echo off

net user user0 12345678
net localgroup "Администраторы" >> 1.txt
rem net localgroup "Администраторы" /ADD user0 >> 1.txt
rem pause