# teterkin_infra

## Подключение к someinternalhost в одну команду

Для подключения к узлу, находящимся за бастионом достаточно выполнить одну
команду:

```bash

$ ssh -A BASTION-IP -t ssh INTERNAL-HOST

```

Вместо `BASTION-IP` укажите публичный IP адрес вашего бастион сервера.

Вместо `INTERNAL-HOST` укажите внутренний IP адрес сервера во внутреннем
периметре.

## Подключение к someinternalhost с помощью короткой команды

> Команды вида ssh someinternalhost

Для подключения из консоли при помощи команды вида `ssh someinternalhost` из
локальной консоли рабочего устройства, необходимо выполнить ряд действий, чтобы
настроить локальный алиас `someinternalhost` в локальном конфигурационном файле
клиента ssh:

1. Создайте локальный конфигурационный файл ssh и назначьте файлу права доступа:

   ```bash
   $ touch ~/.ssh/config
   $ chmod 0700 ~/.ssh/config
   ```

1. Откройте файл в редакторе `vi`:

   ```bash
   $ vi ~/.ssh/config
   ```

1. Опишите секцию отосящуюся к нашему серверу:

   ```ini
   Host someinternalhost
        HostName INTERNAL-HOST
        Port 22
        ForwardX11 no
        ProxyJump BASTION-IP
   ```
  
   Где, как в примере выше, Вместо `BASTION-IP` укажите публичный IP адрес
   вашего бастион сервера, а вместо `INTERNAL-HOST` укажите внутренний IP адрес
   сервера во внутреннем периметре.

1. Сохраните файл.
1. Проверьте подключение. Теперь для подключения к внутреннему серверу через
   бастион достаточно набрать:

   ```bash
   $ ssh someinternalhost
   ```

## Настройка VPN

Для настройки VPN используйте файл [setupvpn.sh](./setupvpn.sh).

Для доступа к моему настроенному серверу используйте клиента OpenVPN и файл
профиля [cloud-bastion.ovpn](./cloud-bastion.ovpn).

Временные IP адреса для проверки конфигурации:

bastion_IP = 35.246.197.77

someinternalhost_IP = 10.156.0.3

## Автоматическое развертывание приложения на Ruby в облаке

IP адреса для проверки cloud-testapp:

testapp_IP = 35.246.227.187

testapp_port = 9292

Labels:

- GCP
- cloud-testapp

> Ресурсы, созданные в этом ДЗ НЕЛЬЗЯ удалять до прохождения тестов TravisCI.

> После того как тесты в рамках PR будут зеленые и будет получен approve пул
> реквеста, ветку с ДЗ нужно смерджить и закрыть PR.

Пример команды для создания облака и автоматического развертывания приложения:

gcloud compute instances create reddit-app\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --zone=europe-west3-a \
  --metadata startup-script='#! /bin/bash
  wget https://gist.githubusercontent.com/teterkin/60e28fc2842a32b73eda06b42a0f83f3/raw/6ea0adf082200ad97a9a0bd94b7c039686950c06/install_ruby.sh && \
  chmod +x install_ruby.sh && \
  ./install_ruby.sh && \
  wget https://gist.githubusercontent.com/teterkin/25d0dcd2390bb8d216577f50c83c1403/raw/8c410805a5b3ffbf8a5509b55b794e7e4412461e/install_mongodb.sh && \
  chmod +x install_mongodb.sh && \
  ./install_mongodb.sh && \
  wget https://gist.githubusercontent.com/teterkin/e397b5fe355da5887d3c42c9a0bf1576/raw/c32747597f8dfa40b076b96c97ca684b553308a8/deploy.sh && \
  chmod +x deploy.sh && \
  ./deploy.sh
  RC=$?
  if [ "$RC" -eq 0 ]; then
    echo "Deployment is complete. Done."
    exit 0;
  else
    echo "ERROR. Exiting..."
    exit 1;
  fi
  '

Для проверки работы:

1. Нужно перейти по ssh на только что созданный сервер и запустить команду tail
   на syslog системы:

   ```bash
   $ ssh 35.246.227.187
   $ tail -f /var/log/syslog
   ```
2. Дождитесь, когда startup-script закончит работу.
3. Перейдите по адресу [http://35.246.227.187:9292/](http://35.246.227.187:9292/).
4. Проверьте работу приложения.

Проверка скорости развертывания:

- 6 дек 2020 г.  2:59:02 – запущен скрипт создания ВМ.
- 6 дек 2020 г.  2:59:13 – скрипт успешно завершился (машина создана).
- 6 дек 2020 г.  3:00:39 – startup-script завершился (приложение работает).

Итого на всё от создания ВМ до рабочего приложения ушло 37 секунд!!!

Для создания правила брандмауэра из консоли нужно выполнить следующую команду:

gcloud compute firewall-rules create default-puma-server \
  --allow='tcp:9292' \
  --target-tags='puma-server' \
  --source-ranges='0.0.0.0/0' \
  --direction='INGRESS' \
  --network='default'
