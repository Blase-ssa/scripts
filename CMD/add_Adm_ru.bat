@echo off
net localgroup "Администраторы" >> 1.txt

net localgroup "Администраторы" /ADD user0 >> 1.txt
rem pause

