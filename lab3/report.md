# Отчет по лабораторной работе №3 - "Эмуляция распределенной корпоративной сети связи, настройка OSPF и MPLS, организация первого EoMPLS".

## Шапка отчета

* University: [ITMO University](https://itmo.ru/ru/)
* Faculty: [ФПиН](https://fpin.itmo.ru/ru)
* Course: [Introduction in routing](https://github.com/itmo-ict-faculty/introduction-in-routing)
* Year: 2025/2026
* Group: K3322
* Author: Titov Georgy Konstantinovich
* Lab: Lab3
* Date of create: 01.12.2025
* Date of finished: 05.12.2025

## Описание

Наша компания "RogaIKopita Games" с прошлой лабораторной работы выросла до серьезного игрового концерна, ещё немного и они выпустят свой ответ Genshin Impact - Allmoney Impact. И вот для этой задачи они купили небольшую, но очень старую студию "Old Games" из Нью Йорка, при поглощении выяснилось что у этой студии много наработок в области компьютерной графики и совет директоров "RogaIKopita Games" решил взять эти наработки на вооружение. К сожалению исходники лежат на сервере "SGI Prism", в Нью-Йоркском офисе никто им пользоваться не умеет, а из-за короновируса сотрудники офиса из Санкт-Петерубурга не могут добраться в Нью-Йорк, чтобы забрать данные из "SGI Prism". Ваша задача подключить Нью-Йоркский офис к общей IP/MPLS сети и организовать EoMPLS между "SGI Prism" и компьютером инженеров в Санк-Петербурге.

## Цель работы

Изучить протоколы OSPF и MPLS, механизмы организации EoMPLS.

## Задание

Вам необходимо сделать IP/MPLS сеть связи для "RogaIKopita Games" изображенную на рисунке 1 в ContainerLab. Необходимо создать все устройства указанные на схеме и соединения между ними.

<img width="713" height="391" alt="image" src="https://github.com/user-attachments/assets/7cea3712-9d93-459e-aaae-428066f579dd" />

* Помимо этого вам необходимо настроить IP адреса на интерфейсах.
* Настроить OSPF и MPLS.
* Настроить EoMPLS.
* Назначить адресацию на контейнеры, связанные между собой EoMPLS.
* Настроить имена устройств, сменить логины и пароли.

## Схема топологии сети

<img width="1254" height="577" alt="image" src="https://github.com/user-attachments/assets/2365e0fc-5229-4683-802b-80833d7fe9fa" />


Сама топология сети повторяет структуру топологий из предыдущих лабораторных работ. Только в этот раз будет развернуто 6 маршрутизаторов, один пользовательский компьютер и один хост, выполняющий роль SGI.

Для управления используется подсеть: 172.160.16.0/24.

## Выполнение работы

### Конфигурация маршрутизаторов

Конфигурации маршрутизаторов будут примерно схожи за исключением R0.SPB, R0.NY - так как на них мы ее настраивали DHCP-сервер, подключали клиентов и настраивали VPLS (EoMPLS). Разбирать конфигурацию марщрутизаторов будем на примере R0.SPB:

```
/user 
add name=georgy password=strongpass group=full 
remove admin
/system identity set name=R01.SPB
```

* Как нас просили в задание - удаляем дефолтного пользователя `admin` и создаем нового пользователя `georgy` с паролем. Также задаем имя для нашего роуетера.

```
add address=10.20.1.1/30 interface=ether2 
add address=10.20.2.1/30 interface=ether
add address=192.168.10.1/24 interface=ether4
```

* Указываем ip-адреса на физических портах нашего маршрутизтора.

```
/ip pool add name=dhcp-pool ranges=192.168.10.10-192.168.10.100
/ip dhcp-server add address-pool=dhcp-pool disabled=no interface=ether4 name=dhcp-server
/ip dhcp-server network add address=192.168.10.0/24 gateway=192.168.10.1
```

* Создаем и настраиваем DHCP-сервер, чтобы наши устойства динамически получали ip-адреса.

```
/interface bridge
add name=loopback

/ip address 
add address=10.255.255.X/32 interface=loopback network=10.255.255.X
```

* Cоздаём loopback интерфейс через, который обеспечивает стабильный IP-адрес, не зависящий от физических интерфейсов. По данному виртуальному интерфейсу будет происходить обмен данными по протоколу OSPF.

```
/routing ospf instance
add name=inst router-id=10.255.255.X

/routing ospf area
add name=backbonev2 area-id=0.0.0.0 instance=inst

/routing ospf network
add area=backbonev2 network=10.20.X.0/30
add area=backbonev2 network=192.168.X.0/24
add area=backbonev2 network=10.255.255.X/32 
```

* Далее мы создаем OSPF-инстанс — независимый процесс маршрутизации OSPF. Создаем OSPF-Area — область маршрутизации. Мы включаем интерфейсы в OSPF по IP-префиксам.

```
/mpls ldp
set lsr-id=10.255.255.X
set enabled=yes transport-address=10.255.255.X

/mpls ldp advertise-filter 
add prefix=10.255.255.0/24 advertise=yes
add advertise=no

/mpls ldp accept-filter 
add prefix=10.255.255.0/24 accept=yes
add accept=no

/mpls ldp interface
add interface=ether2
add interface=ether3
```

* Устанавливаем уникальный MPLS Router-ID. Включаем MPLS LDP. Указываем адрес для установления LDP соседства. Включение LDP на интерфейсах.

```
/interface bridge
add name=vpn

/interface vpls
add disabled=no name=SGIPC remote-peer=10.255.255.6 cisco-style=yes cisco-style-id=0

/interface bridge port
add interface=ether2 bridge=vpn
add interface=SGIPC bridge=vpn
```

* Создали виртуальный коммутатор (bridge) для объединения L2. Подключили к нему локальный порт и VPLS интерфейс. Фреймы между SPB и NY теперь проходят по MPLS LSP, а на каждом PE "выходят" в локальный bridge. Теперь клиент из SPB и клиент из NY в одной VLAN, хоть они физически находятся в разных городах.

### Конфигурация конечных устройств (На примере PC1)

Тут все по старинке, как в предыдущих работых.

```
#!/bin/sh
ip route del default via 172.160.16.1 dev eth0
udhcpc -i eth1
```

## Проверка работоспособности

### OSPF

![UlmBmqZ2ManIXvdCBXgupBVn2SPjWqTIGgABT3mEj6UgUxOT15buwPEPtTLjIXO6ZPVJ2amEXZeGVPV_HMySY0R3](https://github.com/user-attachments/assets/2c10e550-5530-4c2b-a797-02fd9e8a42e0)

Проверка таблиц маршрутизации подтверждает, что маршруты распространяются динамически — никаких статических маршрутов не используется.

### MPLS

![E-AjrZ4-fJeVhTxlG4nCKjiE963Khlq7uFZIVrfu-gzVIWoAnR4U7IzYIG74hgnzrhenlpSXnuoxjSWDS766OSri](https://github.com/user-attachments/assets/b0092d0d-f089-4c36-a718-8f6d62070912)

### VPLS (EoMPLS)

![iNn2vpyuetHgAeehr2jXEQrbNA26CPsmoafCx2NY6_myYc8gxbVnvzVcwiyEyWFXhSTrbeDP6OVct5qxrU6CN5UN](https://github.com/user-attachments/assets/72a56ac2-7e75-4dea-abc7-bcd144440f94)

VPLS-туннель между NY и SPB успешно поднят, компьютеры на его концах оказываются в одной L2-домене и могут взаимодействовать напрямую.

### Проверка доступности двух узлов

![O5w7d7MypTQGQXYOqxhqUavuhGQHS9kV9IGvHXczySV-kP-JuEaPk7Jt2Nk-HJNcjCvEIfhgOZE2ylsVBQNC7QD2](https://github.com/user-attachments/assets/14dd2ec6-902c-44db-b367-42c979af50fb)

## Вывод

В рамках данной лабораторной работы была построена и настроена сеть IP/MPLS: реализована динамическая маршрутизация с использованием протокола OSPF, поверх которой активированы механизмы MPLS, а также организован VPLS-туннель между маршрутизаторами локаций Нью-Йорк и Санкт-Петербург.

Работоспособность всех сервисов подтверждена, задачи выполнены в полном объёме, цель работы достигнута.

