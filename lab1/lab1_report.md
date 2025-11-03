# Отчет по лабораторной работе №1 - "Установка ContainerLab и развертывание тестовой сети связи".

## Шапка отчета

* University: [ITMO University](https://itmo.ru/ru/)
* Faculty: [ФПиН](https://fpin.itmo.ru/ru)
* Course: [Introduction in routing](https://github.com/itmo-ict-faculty/introduction-in-routing)
* Year: 2025/2026
* Group: K3322
* Author: Titov Georgy Konstantinovich
* Lab: Lab1
* Date of create: 09.09.2025
* Date of finished: -.09.2025

## Описание

В данной лабораторной работе вы познакомитесь с инструментом ContainerLab, развернете тестовую сеть связи, настроите оборудование на базе Linux и RouterOS.

## Цель работы

Ознакомиться с инструментом ContainerLab и методами работы с ним, изучить работу VLAN, IP адресации и т.д.

## Задание

Вам необходимо сделать трехуровневую сеть связи классического предприятия изображенную на рисунке 1 в ContainerLab. Необходимо создать все устройства указанные на схеме и соединения между ними, правила работы с СontainerLab можно изучить по [ссылке](https://containerlab.dev/quickstart/).

<img width="411" height="291" alt="image" src="https://github.com/user-attachments/assets/154540a7-11e4-4d80-aaa8-c7da83da9cf7" />

> Подсказка №1 Не забудьте создать mgmt сеть, чтобы можно было зайти на CHR.  
> Подсказка №2 Для mgmt_ipv4 не выбирайте первый и последний адрес в выделенной сети, ходить на CHR можно используя SSH и Telnet (admin/admin).

* Помимо этого вам необходимо настроить IP адреса на интерфейсах и 2 VLAN-a для PC1 и PC2, номера VLAN-ов вы вольны выбрать самостоятельно.
* Также вам необходимо создать 2 DHCP сервера на центральном роутере в ранее созданных VLAN-ах для раздачи IP адресов в них. PC1 и PC2 должны получить по 1 IP адресу из своих подсетей.
* Настроить имена устройств, сменить логины и пароли.

## Выполнение работы

### Топология

В файле lab1_network.yaml описана топология сети. Она включает маршрутизатор `R1`, три коммутатора (`SW1`, `SW2`, `SW3`), а также два конечных устройства (`PC1` и `PC2`). Каждый узел имеет свой файл конфигурации (в папке `configs`, который загружается при старте контейнера).

```
name: lab_1

mgmt:
  network: lab1_mgmt
  ipv4-subnet: 172.160.16.0/24

topology:
  kinds:
    vr-ros:
      image: vrnetlab/mikrotik_routeros:6.47.9
  
  nodes:
    R1:
      kind: vr-ros
      mgmt-ipv4: 172.160.16.100
      startup-config: configs/r1.rsc
    SW1:
      kind: vr-ros
      mgmt-ipv4: 172.160.16.101
      startup-config: configs/sw1.rsc
    SW2:
      kind: vr-ros
      mgmt-ipv4: 172.160.16.102
      startup-config: configs/sw2.rsc
    SW3:
      kind: vr-ros
      mgmt-ipv4: 172.160.16.103
      startup-config: configs/sw3.rsc
    PC1:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.160.16.2
      binds:
      - ./configs:/configs
      exec:
      - sh /configs/pc1.sh
    PC2:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.160.16.3
      binds:
      - ./configs:/configs
      exec:
      - sh /configs/pc2.sh

  links:
  - endpoints: ["R1:eth1", "SW1:eth1"]
  - endpoints: ["SW1:eth2", "SW2:eth1"]
  - endpoints: ["SW1:eth3", "SW3:eth1"]
  - endpoints: ["SW2:eth2", "PC1:eth1"]
  - endpoints: ["SW3:eth2", "PC2:eth1"]
```

Ниже можно ознакомиться с графическим представлением этой схемы (а также с разделением VLAN'ов):

<img width="946" height="624" alt="image" src="https://github.com/user-attachments/assets/7b4e4f3d-e6e5-4082-ae0e-666f20ac9d9d" />

Схема сделана в draw.io

### Настройка маршрутизатора R1

На маршрутизаторе `R1` настроены два VLAN-а — `VLAN 10` и `VLAN 20`. Каждый из этих VLAN используется для разделения трафика между двумя сегментами сети, к которым подключены `PC1` и `PC2`. Для каждого VLAN настроен DHCP-сервер, который автоматически раздаёт IP-адреса устройствам в соответствующих VLAN. Дополнительно был создан новый пользователь с административными правами и изменено имя устройства.

Конфиг для настройки `R1`:

```
/interface vlan
add name=vlan10 vlan-id=10 interface=ether1
add name=vlan20 vlan-id=20 interface=ether1
/ip address
add address=10.10.10.1/24 interface=vlan10
add address=10.10.20.1/24 interface=vlan20
/ip pool
add name=dhcp_pool_vlan10 ranges=10.10.10.2-10.10.10.254
add name=dhcp_pool_vlan20 ranges=10.10.20.2-10.10.20.254
/ip dhcp-server
add name=dhcp_vlan10 interface=vlan10 address-pool=dhcp_pool_vlan10 disabled=no
add name=dhcp_vlan20 interface=vlan20 address-pool=dhcp_pool_vlan20 disabled=no
/ip dhcp-server network
add address=10.10.10.0/24 gateway=10.10.10.1
add address=10.10.20.0/24 gateway=10.10.20.1
/user add name=georgy password=admin group=full
/system identity set name=R1-Router
```

### Настройка коммутатора SW1

На `SW1` добавлены VLAN-интерфейсы для разных портов и созданы мосты для `VLAN 10` и `VLAN 20`, обеспечивающие передачу трафика между соответствующими интерфейсами. Для каждого VLAN настроен клиент DHCP.

Конфиг для настройки `SW1`:

```
/interface vlan
add name=vlan10_e1 vlan-id=10 interface=ether1
add name=vlan20_e1 vlan-id=20 interface=ether1
add name=vlan10_e2 vlan-id=10 interface=ether2
add name=vlan20_e3 vlan-id=20 interface=ether3
/interface bridge
add name=br_v10
add name=br_v20
/interface bridge port
add interface=vlan10_e1 bridge=br_v10
add interface=vlan10_e2 bridge=br_v10
add interface=vlan20_e1 bridge=br_v20
add interface=vlan20_e3 bridge=br_v20
/ip dhcp-client
add disabled=no interface=br_v20
add disabled=no interface=br_v10
/user add name=georgy password=admin group=full
/system identity set name=SW1-Switch
```

### Настройка коммутаторов SW2 и SW3

Конфигурация аналогична: VLAN-интерфейсы и мосты для своих портов, плюс DHCP-клиенты.

Пример конфига для настройки `SW2`:

```
/interface vlan
add name=vlan10_e1 vlan-id=10 interface=ether1
add name=vlan10_e2 vlan-id=10 interface=ether2
/interface bridge
add name=br_v10
/interface bridge port
add interface=vlan10_e1 bridge=br_v10
add interface=vlan10_e2 bridge=br_v10
/ip dhcp-client
add disabled=no interface=br_v10
/user add name=georgy password=adminn group=full
/system identity set name=SW2-Switch
```

### Настройка конечных устройств PC1, PC2

`PC1` и `PC2` настраиваются для работы в своих VLAN, создаются подинтерфейсы и задаются IP-адреса.

Пример конфига для `PC1`:

```
#!/bin/sh
ip link add link eth1 name vlan10 type vlan id 10
ip link set vlan10 up
dhclient vlan10
```

Пример конфига для `PC2`:

```
#!/bin/sh
ip link add link eth1 name vlan20 type vlan id 20
ip link set vlan20 up
dhclient vlan20
```

## Проверка работспособности сети

## Заключение
