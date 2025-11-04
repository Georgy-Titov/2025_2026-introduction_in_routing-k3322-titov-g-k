# Отчет по лабораторной работе №2 - "Эмуляция распределенной корпоративной сети связи, настройка статической маршрутизации между филиалами".

## Шапка отчета

* University: [ITMO University](https://itmo.ru/ru/)
* Faculty: [ФПиН](https://fpin.itmo.ru/ru)
* Course: [Introduction in routing](https://github.com/itmo-ict-faculty/introduction-in-routing)
* Year: 2025/2026
* Group: K3322
* Author: Titov Georgy Konstantinovich
* Lab: Lab1
* Date of create: 03.11.2025
* Date of finished: -.09.2025

## Описание

В данной лабораторной работе вы первый раз познакомитесь с компанией "RogaIKopita Games" LLC которая занимается разработкой мобильных игр с офисами в Москве, Франкфурте и Берлине. Для обеспечения работы своих офисов "RogaIKopita Games" вам как сетевому инженеру необходимо установить 3 роутера, назначить на них IP адресацию и поднять статическую маршрутизацию. В результате работы сотрудник из Москвы должен иметь возможность обмениваться данными с сотрудником из Франкфурта или Берлина и наоборот.

## Цель работы

Ознакомиться с принципами планирования IP адресов, настройке статической маршрутизации и сетевыми функциями устройств.

## Задание

Вам необходимо сделать сеть связи в трех геораспределенных офисах "RogaIKopita Games" изображенную на рисунке 1 в ContainerLab. Необходимо создать все устройства указанные на схеме и соединения между ними.

<img width="541" height="361" alt="image" src="https://github.com/user-attachments/assets/8cd57641-2e23-4813-ae13-8976e25d95aa" />

Помимо этого вам необходимо настроить IP адреса на интерфейсах.
Создать DHCP сервера на роутерах в сторону клиентских устройств.
Настроить статическую маршрутизацию.
Настроить имена устройств, сменить логины и пароли.


## Выполнение работы

Схема связей нарисованная в draw.io:

<img width="1057" height="672" alt="image" src="https://github.com/user-attachments/assets/cfaff6ff-c929-4432-a6bc-5814c06105c2" />

### Конфигурация маршрутизаиров

Конфиг маршрутизатора на примере **R1-BRL**:

```
# Изменяется имя устройства и создается новый пользователь с полными правами
/system identity set name=R1-BRL
/user add name=georgy password=strongpass group=full

# Настраиваются IP-адреса на интерфейсах: два межмаршрутных соединения (/30) и один интерфейс локальной сети
/ip address
add address=192.168.13.1/30 interface=ether2
add address=192.168.12.2/30 interface=ether3
add address=10.3.0.1/16 interface=ether4

# Создается пул адресов, из которого DHCP-сервер будет раздавать IP-адреса клиентам
/ip pool
add name=dhcp-pool ranges=10.3.0.10-10.3.255.254

# Настраивается DHCP-сервер на локальной сети (ether4), чтобы ПК автоматически получали IP и шлюз
/ip dhcp-server
add address-pool=dhcp-pool disabled=no interface=ether4 name=dhcp-server

/ip dhcp-server network
add address=10.3.0.0/16 gateway=10.3.0.1

# Создаются статические маршруты к сетям других офисов через соседние маршрутизаторы
/ip route
add distance=1 dst-address=10.1.0.0/16 gateway=192.168.13.2
add distance=1 dst-address=10.2.0.0/16 gateway=192.168.12.1
```

### Конфигурация компьютеров

Конфиг ПК на примере **PC1**:

```
#!/bin/sh
set -e

# Сначала удаляется стандартный маршрут, заданный по умолчанию, а затем компьютер получает IP-адрес, маску и шлюз через DHCP от маршрутизатора своего филиала
ip route del default via 172.160.16.1 dev eth0
udhcpc -i eth1
```

### Проверяем работоспособность

Создаем лабораторию `clab deploy -t <имя_лаборатории>`:

![Loj4KQqpNWl7v-8C5ju8-sMvcR_CqgUxKqPVKIJDqsdH9uMb3HFJwgURN3IElEKiJWbWpZqPcGlbH7xDyWE6P-oe](https://github.com/user-attachments/assets/dc5f92c9-a8bc-4ed6-8435-419671256d21)

Заходим на **PC1** и пингуем оставшиеся два, также посмотрим таблицу маршрутизации на маршрутизаторе в Берлине:

![BOXpRjh1xlJLO2j0klNcDF_ZOMQNZAbEXgEVX6QPqgQj1p9O7G2cNsiHmQm5XFUDKTKRGiF6jiHtN7lEdmV4vHjB](https://github.com/user-attachments/assets/659bee52-5350-4afa-8342-7ecd7ded6c4e)

![lKG9sh71vRPtbwiMqMADurkR0yKZ0tYRedulAhuV4babRKl8KKxDqC6wnJVp5npu9Wq9ThONdlcPXlPq2vSl54g5](https://github.com/user-attachments/assets/cc014a74-dde6-4143-afa5-c4fcfd28e9fe)

Все ОК!

## Заключение

В ходе лабораторной работы была создана распределённая сеть компании "RogaIKopita Games", включающая три филиала: Москву, Франкфурт и Берлин.
Была выполнена настройка IP-адресов, DHCP-серверов и статической маршрутизации между маршрутизаторами.
Проверка с помощью команд ping показала успешную связь между всеми филиалами, что подтверждает корректность маршрутизации.
