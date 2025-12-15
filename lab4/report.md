# Отчет по лабораторной работе №4 - "Эмуляция распределенной корпоративной сети связи, настройка iBGP, организация L3VPN, VPLS".

## Шапка отчета

* University: [ITMO University](https://itmo.ru/ru/)
* Faculty: [ФПиН](https://fpin.itmo.ru/ru)
* Course: [Introduction in routing](https://github.com/itmo-ict-faculty/introduction-in-routing)
* Year: 2025/2026
* Group: K3322
* Author: Titov Georgy Konstantinovich
* Lab: Lab4
* Date of create: 14.12.2025
* Date of finished: -.12.2025

## Описание

Компания "RogaIKopita Games" выпустила игру "Allmoney Impact", нагрузка на арендные сервера возрасли и вам поставлена задача стать LIR и организовать свою AS чтобы перенести все сервера игры на свою инфраструктуру. После организации вашей AS коллеги из отдела DEVOPS попросили вас сделать L3VPN между 3 офисами для служебных нужд. (Рисунок 1) Данный L3VPN проработал пару недель и коллеги из отдела DEVOPS попросили вас сделать VPLS для служебных нужд.

## Цель работы

Изучить протоколы BGP, MPLS и правила организации L3VPN и VPLS.

## Задание

Вам необходимо сделать IP/MPLS сеть связи для "RogaIKopita Games" изображенную на рисунке 1 в ContainerLab. Необходимо создать все устройства указанные на схеме и соединения между ними.

<img width="911" height="434" alt="image" src="https://github.com/user-attachments/assets/52f2e5fa-a44a-4bfc-8481-5f42670bd5b3" />

* Помимо этого вам необходимо настроить IP адреса на интерфейсах.
* Настроить OSPF и MPLS.
* Настроить iBGP с route reflector кластером

И вот тут лабораторная работа работа разделяется на 2 части, в первой части вам надо настроить L3VPN, во второй настроить VPLS, но при этом менять топологию не требуется. Вы можете просто разобрать VRF и на их месте собрать VPLS.

Первая часть:

* Настроить iBGP RR Cluster.
* Настроить VRF на 3 роутерах.
* Настроить RD и RT на 3 роутерах.
* Настроить IP адреса в VRF.
* Проверить связность между VRF
* Настроить имена устройств, сменить логины и пароли.

Вторая часть:

* Разобрать VRF на 3 роутерах (или отвязать их от интерфейсов).
* Настроить VPLS на 3 роутерах.
* Настроить IP адресацию на PC1,2,3 в одной сети.
* Проверить связность.

## Схема топологии сети

<img width="908" height="574" alt="image" src="https://github.com/user-attachments/assets/d1b6dc0e-25db-4576-b4fa-9b7ded1f99ac" />

Топология для каждой части лабораторной аналогична предыдущим работам: 6 маршрутизаторов объединены в единую сеть, а также три хоста - PC1, PC2, PC3. Все устройства управляются по mgmt-сети 172.161.16.0/24 в первой части, во второй - 172.162.16.0/24

## Выполнение работы

### Конфигурация маршрутизаторов

```
/user 
add name=georgy password=strongpass group=full 
remove admin
/system identity set name=R01.NY
```

* Как нас просили в задание - удаляем дефолтного пользователя admin и создаем нового пользователя georgy с паролем. Также задаем имя для нашего роуетера.

```
/ip address
add address=10.20.2.1/30 interface=ether2
add address=192.168.11.1/24 interface=ether3
```

* Указываем ip-адреса на физических портах нашего маршрутизтора.

```
/ip pool
add name=dhcp-pool ranges=192.168.11.10-192.168.11.100

/ip dhcp-server
add address-pool=dhcp-pool disabled=no interface=ether3 name=dhcp-server

/ip dhcp-server network
add address=192.168.11.0/24 gateway=192.168.11.1
```

#### Настройка OSPF

* Создаем и настраиваем DHCP-сервер, чтобы наши устойства динамически получали ip-адреса.

```
/interface bridge
add name=loopback

/ip address 
add address=10.255.255.6/32 interface=loopback network=10.255.255.6
```

* bridge loopback создается на каждом роутере, такой виртуальный интерфейс никогда не отключается без внешнего вмешательства. Также каждому маршрутизатору даю loopback 10.255.255.x/32 (где x уникален для маршрутизатора) и использую его как router-id в OSPF.

```
/routing ospf instance
add name=inst router-id=10.255.255.6

/routing ospf area
add name=backbone area-id=0.0.0.0 instance=inst

/routing ospf network
add area=backbone network=10.20.2.0/30
add area=backbone network=192.168.11.0/24
add area=backbone network=10.255.255.6/32
```

#### Настройка MPLS

* Указываем в router-id адрес loopback интерфейса, создаю зону - так как роутеров всего 6, достаточно одной зоны для всех, и также указываю имя зоны, а в сетях все физические подключения.

```
/mpls ldp
set lsr-id=10.255.255.6
set enabled=yes transport-address=10.255.255.6

/mpls ldp interface
add interface=ether2
```

* Здесь включаем протокол LDP на каждом роутере, прописываем LSR-id и указываем интерфейсы, на которых будет работать MPLS. transport-address пишем тот же, что и адрес loopback для удобства, в lsr-id тоже указываем его.

#### Настройка iBGP

```
/routing bgp instance
set default as=65000 router-id=10.255.255.6

/routing bgp peer
add name=peerLND remote-address=10.255.255.4 address-families=l2vpn,vpnv4 remote-as=65000 update-source=loopback route-reflect=no

/routing bgp network
add network=10.255.255.0/24
```

* Настроен iBGP: задан номер AS=65000, router-id = loopback-адрес. Создан iBGP-пир с соседним PE через loopback для передачи VPNv4 и L2VPN маршрутов. Анонсируется сеть MPLS-ядра, что обеспечивает установку BGP-сессии независимо от состояния физических интерфейсов.

#### Настройка VRF на внешних роутерах

```
/interface bridge 
add name=br100
/ip address
add address=10.100.1.2/32 interface=br100
/ip route vrf
add export-route-targets=65000:100 import-route-targets=65000:100 interfaces=br100 route-distinguisher=65000:100 routing-mark=VRF
/routing bgp instance vrf
add redistribute-connected=yes routing-mark=VRF
```

* Далее создаем VRF: под него делается виртуальный интерфейс-мост, ему выдаётся адрес /32, и создаётся VRF с RD и RT 65000:100 — это идентификаторы, по которым маршруты данного офиса будут выделяться и обмениваться между PE-роутерами. В VRF включается импорт и экспорт RT, а также включается отдельный BGP-инстанс, который публикует подключённые маршруты VRF в BGP VPNv4. Таким образом, этот роутер становится PE-узлом и может передавать VRF-маршруты на RR и другим офисам для L3VPN.


#### Настройка VPLS (Вторая часть)

```
/mpls ldp
set lsr-id=10.255.255.6
set enabled=yes transport-address=10.255.255.6
/mpls ldp interface
add interface=ether2
add interface=ether3
```

* Здесь в первую очередь по сравнению с предыдущей частью работы нужно поменять блок с настройкой MPLS: LDP включаем не только на ether2, но и на ether3, потому что ПК участвует в VPLS.

```
/interface bridge
add name=vpn

/interface bridge port
add interface=ether3 bridge=vpn

/interface vpls bgp-vpls
add bridge=vpn export-route-targets=65000:100 import-route-targets=65000:100 name=vpls route-distinguisher=65000:100 site-id=6

/ip address
add address=10.100.1.6/24 interface=vpn
```

* В этой части VRF полностью удаляется, и BGP используется только для VPLS. Создаю виртуальный мост vpn, затем к нему добавляю порт ether3. После этого создаётся интерфейс BGP-VPLS, который использует тот же мост vpn и получает свои параметры VPLS. И также на мост назначается айпишник 10.100.1.6/24, чтобы этот PE мог быть достигнут внутри общей сети VPLS и чтобы компьютеры могли находиться в одном IP-сегменте.

```
/ip pool
add name=vpn-dhcp-pool ranges=10.100.1.100-10.100.1.254
/ip dhcp-server
add address-pool=vpn-dhcp-pool disabled=no interface=vpn name=dhcp-vpls
/ip dhcp-server network
add address=10.100.1.0/24 gateway=10.100.1.1
```

* Также надо выбрать, на каком роутере поставить dhcp-сервер, чтобы задать айпи всем компьютерам в одной этой сети vpn. В моем случае - это SPB. На всех роутерах убираем раздачу dhcp-адресов из предыдущей части, на SPB создаём новый пул из сети впн и подключаем его к нему.

### Конфигурация ПК

```
#!/bin/sh
ip route del default via 172.161.16.1 (для второй части - 172.162.16.1) dev eth0
udhcpc -i eth1
```

* Тут все по старинке, как в предыдущих работых.

## Проверка работоспособности

### OSPF

![lm7t20rf4HqBCeZwxafSFAgGitcKRzmJAieg4oJN0jppHO-ypUy6cGupj25_A3s-yKOAEh_RTTL-BeCR7SddMXM5](https://github.com/user-attachments/assets/33ad66b6-e959-47ce-ae68-c6af3b3d390d)

Все маршруты получены динамически, без использования статических записей. OSPF настроен правильно.

### MPLS

![04cgnFYEMSt5tRZdT79zJ9GPMJfb3RLI2uoOGCJ4CBUBMdDLwqvV8iM4nJLhKVUpVerwG9Hrg1pd1tmWHYsKOCKi](https://github.com/user-attachments/assets/cee0f292-896f-48b2-b784-686a1bfc2fe9)

MPLS функционирует корректно, метки распространяются между маршрутизаторами.

### iBGP

<img width="2065" height="270" alt="image" src="https://github.com/user-attachments/assets/24fe920d-3f87-4768-9c0f-b96243bd3199" />

В таблице маршрутизации для BGP-маршрутов видно, что их административная дистанция составляет 200, что превышает значение административной дистанции OSPF (110). Это означает, что при наличии альтернативных путей трафик будет направляться по маршрутам, полученным по OSPF. Кроме того, в выводе команды routing bgp peer print status все BGP-соседи находятся в состоянии Established, что свидетельствует о корректной настройке и стабильной работе iBGP-сессий.

### VRF

![eARS2e9wYkljEwgTFfLAPZKPA0Y0819vg_G0WYm9_EBts3P1EdTVHvsPgo7tl_WXG8icoDcXbqseNpNbOdK50onL](https://github.com/user-attachments/assets/b017ae9b-f828-47bb-997c-9dc8928ad349)

На граничных маршрутизаторах успешно добавлены VRF-маршруты.

### VPLS (Часть 2)

![5L_X8tzubcHg3jigJucar0K9me34S4hb_zeLbJIxWhT2w78goUg7TU0DtgwwCCUTjNeTVYVyR97C0skELKmmn7Gp](https://github.com/user-attachments/assets/1b8283b4-47e0-4a82-95ce-8f2006df6cbd)

Успешная раздача айпи-адресов через dhcp-сервер на SPB роутере.

![NPMUGTp9faKxHRni4Fz0Yj77gtEmHRMZCLYSC252_WP231eMy1O5X1LNCNXIbuEkIstOa8ldGtkw_CZ6fj-yKSMr](https://github.com/user-attachments/assets/dc6748c0-ad5a-4517-a647-2ddebd85fd11)

![KwKh6jWn2ZgvFLsWVcowZCcP-Z8D6-rbMAqkaJHltiuPRnuBT7pMnDPpnPN6KCJE38xm1DuRLS5_g1ULOqBTdsvy](https://github.com/user-attachments/assets/91dbb49f-485d-431e-bd02-4ad4391cd3ef)

![HNUPxG6T6UjCEqYnjPquF4OKpHUrst6TmvFo8LCDIGs2FUkYOhyPKaX7yg4Lk05ExdpChRYK5ISVfE_MNBLjKhWs](https://github.com/user-attachments/assets/77f28aa7-ae72-46f0-929c-98fb68d48814)

Пиги между компьютерами.

## Выводы

В рамках лабораторной работы была построена и настроена IP/MPLS-сеть. В ходе работы успешно реализована внутренняя маршрутизация с использованием OSPF, настроена передача трафика по MPLS, а также организован обмен маршрутной информацией по iBGP с применением Route Reflector. В первой части работы была реализована услуга L3VPN на базе VRF, во второй части — услуга VPLS, обеспечивающая объединение территориально распределённых сегментов в одну широковещательную доменную сеть.
