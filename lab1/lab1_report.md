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

Также при помощи команды `clab graph -t <имя_лаборатории>` можно увидеть графическое представелние вашей сети. 

### Настройка маршрутизатора R1

На маршрутизаторе `R1` настроены два VLAN-а — `VLAN 10` и `VLAN 20`. Каждый из этих VLAN используется для разделения трафика между двумя сегментами сети, к которым подключены `PC1` и `PC2`. Для каждого VLAN настроен DHCP-сервер, который автоматически раздаёт IP-адреса устройствам в соответствующих VLAN. Дополнительно был создан новый пользователь с административными правами и изменено имя устройства.

Конфиг для настройки `R1`:

```
/system identity set name=R1-Router
/user add name=georgy password=strongpass group=full

/interface vlan
add name=vlan10 vlan-id=10 interface=ether2
add name=vlan20 vlan-id=20 interface=ether2

/ip address
add address=10.10.0.1/24 interface=vlan10
add address=10.20.0.1/24 interface=vlan20

/ip pool
add name=dhcp-pool10 ranges=10.10.0.10-10.10.0.254
add name=dhcp-pool20 ranges=10.20.0.10-10.20.0.254

/ip dhcp-server
add address-pool=dhcp-pool10 disabled=no interface=vlan10 name=dhcp-server10
add address-pool=dhcp-pool20 disabled=no interface=vlan20 name=dhcp-server20

/ip dhcp-server network
add address=10.10.0.0/24 gateway=10.10.0.1
add address=10.20.0.0/24 gateway=10.20.0.1
```

### Настройка коммутатора SW1

На `SW1` добавлены VLAN-интерфейсы для разных портов и создан мост для `VLAN 10` и `VLAN 20`, обеспечивающий передачу трафика между соответствующими интерфейсами.

Конфиг для настройки `SW1`:

```
/system identity set name=SW1-Switch
/user add name=georgy password=strongpass group=full

/interface bridge
add name=bridge vlan-filtering=yes

/interface vlan
add name=vlan10 vlan-id=10 interface=bridge
add name=vlan20 vlan-id=20 interface=bridge

/interface bridge port
add bridge=bridge interface=ether2
add bridge=bridge interface=ether3
add bridge=bridge interface=ether4

/interface bridge vlan
add bridge=bridge tagged=bridge,ether2,ether3 vlan-ids=10
add bridge=bridge tagged=bridge,ether2,ether4 vlan-ids=20

/ip address
add address=10.10.0.2/24 interface=vlan10
add address=10.20.0.2/24 interface=vlan20
```

### Настройка коммутаторов SW2 и SW3

Конфигурация аналогична: VLAN-интерфейсы и мост для своих портов.

Пример конфига для настройки `SW2`:

```
/system identity set name=SW2-Switch
/user add name=georgy password=strongpass group=full

/interface bridge
add name=bridge

/interface vlan
add name=vlan10 vlan-id=10 interface=bridge

/interface bridge port
add bridge=bridge interface=ether2
add bridge=bridge interface=ether3 pvid=10

/interface bridge vlan
add bridge=bridge tagged=bridge,ether2 untagged=ether3 vlan-ids=10

/ip address
add address=10.10.0.3/24 interface=vlan10
```

### Настройка конечных устройств PC1, PC2

Компьютерам добавляется интерфейс vlan через ip link, и udhcpc -i запрашивает на этот интерфейс айпи у dhcp сервера. Наконец, записывается ip route add 10.x0.0.0/24 via 10.x0.0.1 dev vlanx0, чтобы компьютеры видели друг друга в сети.

Пример конфига для `PC1`:

```
#!/bin/sh
set -e

ip link add link eth1 name vlan10 type vlan id 10
ip link set vlan10 up
udhcpc -i vlan10
ip route add 10.20.0.0/24 via 10.10.0.1 dev vlan10
```

Пример конфига для `PC2`:

```
#!/bin/sh
set -e

ip link add link eth1 name vlan20 type vlan id 20
ip link set vlan20 up
udhcpc -i vlan20
ip route add 10.10.0.0/24 via 10.20.0.1 dev vlan20
```

## Проверка работспособности сети

Командой `clab deploy -t <имя_лаборатории>` производится деплой.

![7IBLfTLA3Oi3Dpmr8kflYhqyfnlWKoBbMwwDSx9f9WincHoICFkNYQl-UpW19t6lo3iyoyTdoxbJAvgy30TLmpa8](https://github.com/user-attachments/assets/b3f1cf6f-fd35-4fb3-9cdd-a34baf80aa94)

Далее при помощи команды `docker exec -it <имя_контейнера> sh` мы можем зайти в любой из контейнеров (устройств) в нашей сети. К роутеру и коммутаторам также можно подключиться по `ssh` - именно для этого мы и настраивали менеджмент сеть в нашей топологии.

Давайте подключимся к PC1, а потом к PC2, чтобы проверить работоспособность нашей сети.

![VCX2Ach_i9kp90veBk_ABDUeOV1uHJCReVb4xuGLgYt1eQXp5WMDXJeQYzLWTheUIx20HwmlW3KYjPltOgsR-vgH](https://github.com/user-attachments/assets/e0a05743-d780-4cf8-b36a-479bd71a9c26)

Как можно увидеть PC1 видит PC2 - все ок.

![N4fQlu2NvScK36FlF3uqQrlYuqsWCDvW_oo8_UH_vFyproLEgNI0jnLtiSbXaiSVoLVLzSSm3l1YdHS5Nnrqt3L6](https://github.com/user-attachments/assets/25c9389d-9e00-454f-8928-c2fb829e1023)

В обратную сторону также все хорошо.


## Заключение
