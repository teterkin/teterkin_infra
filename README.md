# teterkin_infra

## Подключение к someinternalhost в одну команду

Для подключения к узлу, находящимся за бастионом достаточно выполнить одну
команду:

```bash

ssh -A BASTION-IP -t ssh INTERNAL-HOST

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
   touch ~/.ssh/config
   chmod 0700 ~/.ssh/config
   ```

1. Откройте файл в редакторе `vi`:

   ```bash
   vi ~/.ssh/config
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
   ssh someinternalhost
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

```bash
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
```

Для проверки работы:

1. Нужно перейти по ssh на только что созданный сервер и запустить команду tail
   на syslog системы:

   ```bash
   ssh 35.246.227.187
   tail -f /var/log/syslog
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

```bash
gcloud compute firewall-rules create default-puma-server \
  --allow='tcp:9292' \
  --target-tags='puma-server' \
  --source-ranges='0.0.0.0/0' \
  --direction='INGRESS' \
  --network='default'
```

## Сборка образа VM с помощью Packer

### Установка Packer

1. Скачайте версию *Packer* для вашей ОС, перейдя по ссылке:
   [https://www.packer.io/downloads.html](https://www.packer.io/downloads.html).
2. Распакуйте скачанный zip архив и поместите бинарный файл в директорию, путь
   до которой содержится в переменной окружения *PATH*.
3. Проверить установку Packer можно командой: `$ packer -v`

### Credentials

Для управления ресурсами *GCP* через сторонние приложения, такие как *Packer* и
*Terraform*, нам нужно предоставить этим инструментам информацию (credentials)
для аутентификации и управлению ресурсами *GCP* нашего аккаунта.

### Application Default Credentials (ADC)

Установка ADC позволяет приложениям, работающим с *GCP* ресурсами и использующим
Google API библиотеки, управлять ресурсами *GCP* через авторизованные API
вызовы, используя credentials вашего пользователя.

Создайте АDC:

```bash
gcloud auth application-default login
```

### Создаем Packer template

1. Создайте в репозитории *infra* директорию `packer`.
1. Внутри директории `packer` создайте файл `ubuntu16.json`.

Это и будет наш шаблон *Packer*, содержащий описание образа VM, который мы хотим
создать.

Для нашего тестового приложения мы соберем образ VM с предустановленными Ruby и
MongoDB, так называемый baked-образ.

Определим *Packer builders* в шаблоне `ubuntu16.json`:

```json
{
  "builders": [
      {
          "type": "googlecompute",
          "project_id": "infra-297519",
          "image_name": "reddit-base-{{timestamp}}",
          "image_family": "reddit-base",
          "source_image_family": "ubuntu-1604-lts",
          "zone": "europe-west1-b",
          "ssh_username": "appuser",
          "machine_type": "f1-micro"
      }
  ]
}
```

Чтобы найти название вашего собственного проекта в GCP выполните команду
`$ gcloud info | grep project` или команду `$ gcloud projects list`.

После этого вставьте полученное название проекта в описание файла.

### Provisioners

Если *builders* секция отвечает за создание виртуальной машины для билда и
создание машинного образа в **GCP**, то секция **provisioners** позволяет
устанавливать нужное ПО, производить настройки системы и конфигурацию приложений
на созданной VM.

Используя скрипты для установки *Ruby* и *MongoDB* из предыдущего ДЗ, определим
два провижинера.

Используем [shell provisioner](https://www.packer.io/docs/provisioners/shell.html),
который позволяет запускать *bash* команды на запущенном инстансе.

После секции “builders” определим, через запятую, провижинеры внутри нашего
шаблона для установки *Ruby* и *MongoDB*. Готовый файл будет выглядеть так:

```json
{
    "builders": [
        {
            "type": "googlecompute",
            "project_id": "infra-297519",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "source_image_family": "ubuntu-1604-lts",
            "zone": "europe-west1-b",
            "ssh_username": "appuser",
            "machine_type": "f1-micro"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```

Опция execute_command позволяет указать, каким способом будет запускаться
скрипт. Т.к. команды по установке требуют sudo, то мы указываем, что запускать
скрипт следует с sudo. 

### Скрипты для провижининга

Внутри директории `packer` создайте директорию `scripts` для скриптов, которые
будут использовать провижинерами. Скопируйте в эту директорию скрипты
`install_ruby.sh` и `install_mongodb.sh` из предыдущего ДЗ.

### Проверка на ошибки

Проверьте, не допустили ли вы ошибок при создании шаблона, используя команду
packer validate:

```bash
packer validate ./ubuntu16.json
```

Поправьте ошибки, если они есть.

### Packer build

Если проверка на ошибки прошла успешно, то запустите build образа:

```bash
packer build ubuntu16.json
```

> В браузерной консоли можно увидеть, как Packer запустил экземпляр VM.

### Проверяем созданный образ

В браузерной консоли перейдите по пути `Compute Engine -> Images`. Найдите свой
образ.

Также можно проверить с помощью gcloud (отфильтровав по названию вашего
проекта):

```bash
$ gcloud compute images list | egrep "infra|NAME"
NAME                      PROJECT         FAMILY         DEPRECATED    STATUS
reddit-base-1608051000    infra-297519    reddit-base                  READY
```

### Развертываем приложение

Как и в прошлый раз, завернем наше тестовое приложение.

Но на этот раз нам нужно будет проделать меньше работы, т.к. часть пакетов уже
содержится в образе VM, который мы создали.

1. В консоли Google Cloud создаем новую виртуальную машину.
1. Задаем нужные характеристики машины (тип экземпляра не больше g1-small).
1. При выборе загрузочного диска (Boot disk) нажимаем «Изменить образ» (Change).
1. Выбираем вкладку custom images и выбираем созданный нами образ
   «reddit-base-1608051000».

### Подключение по SSH

После того как экземпляр запустился, вам необходимо подключиться к экземпляру по
SSH, используя ключи пользователя, которые вы сгенерировали на прошлом занятии.

```bash
ssh <app_user>@<instace_public_ip>
```

### Установка зависимостей и запуск приложения

Для деплоя приложения можно использовать созданный вами скрипт `deploy.sh` или
перечисленные ниже команды:

```bash
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
puma -d
```

Проверяем, что сервер приложения запустился:

```bash
ps aux | grep puma
```

### Проверка работы приложения

1. Предварительно убедитесь, что вам доступен порт сервера приложения в правилах
   firewall. Помните тег `puma-server`?
1. Перейдите по адресу вашего приложения:
   [http://34.76.244.136:9292/](http://34.76.244.136:9292/)

### Immutable infrastructure

> Задание со *

Чтобы попрактиковать подход к управлению инфраструктурой *Immutable*
*infrastructure*, «запечем» (*bake*) в образ VM все зависимости приложения и сам
код приложения. Результат должен быть таким: запускаем экземпляр из созданного
образа и на нем сразу же имеем запущенное приложение.

Для этого нам понадобится подготовить скрипты для развертывания сервера Puma в
качестве системного сервиса (*systemd unit*).

Мы создадим шаблон (`immutable.json`) в той же директории `packer`. Параметр
`image_family` у получившегося образа по заданию должен иметь значение
`reddit-full`.

Дополнительные файлы для сервиса (`production.rb` и `puma.service`) поместим в
директорию `packer/files`. Для запуска приложения при старте экземпляра ВМ
создадим скрипт `deploy_service.sh` и поместим его там же где и наши скрипты
установки базы MongoDB и Ruby (в директории `packer/scripts`).

Скрипт `deploy_service.sh` должен:

1. Загружать тестовое приложение из репозитория.
1. Выполнять конфигурацию окружения сервера Puma.
1. Создавать новый сервис в Systemd ОС Ubuntu.
1. Запускать сервер Puma с тестовым приложением.
1. Проверять корректность развертывания приложения.

Дополнительно приведем команду для конфигурации правила брандмауэра для работы
нашего сервера Puma и приложения в нём (точно так же как делали раньше):

```bash
gcloud compute firewall-rules create default-puma-server \
  --allow='tcp:9292' \
  --target-tags='puma-server' \
  --source-ranges='0.0.0.0/0' \
  --direction='INGRESS' \
  --network='default'
```

Проверка созданной конфигурации на ошибки:

```bash
packer validate ./immutable.json
```

Запечем наш образ:

```bash
packer build ./immutable.json
```

Проверяем наличие созданного образа в облаке:

```bash
$ gcloud compute images list | egrep "reddit-full|NAME"
NAME                      PROJECT         FAMILY         DEPRECATED    STATUS
reddit-full-1608151595    infra-297519    reddit-full                  READY
```

Проверяем создание ВМ из нашего образа и автоматическое развертывание приложения
и всех его зависимостей:

Как и в прошлый раз, завернули наше тестовое приложение.

Но на этот раз нам вообще не нужно ничего делать, т.к. все пакеты, сервисы и
само приложение содержатся в образе VM, который мы создали.

1. В консоли Google Cloud создаем новую виртуальную машину.
1. Задаем нужные характеристики машины (тип экземпляра не больше g1-small).
1. При выборе загрузочного диска (Boot disk) нажимаем «Изменить образ» (Change).
1. Выбираем вкладку custom images и выбираем созданный нами образ
   «reddit-full-`ДОПОЛНИТЬ!`».
1. В разделе «Networking» указываем `puma-server` в поле «Network tags».

Теперь, после запуска ВМ с нашим новым образом, все необходимое ПО должно быть
предустановлено, а наше приложение должно запускаться автоматически, как сервис,
во время запуска системы. Проверим работу приложения:

Перейдите по адресу вашего приложения:
[http://35.240.37.94:9292](http://35.240.37.94:9292)

### Запуск подготовленной машины из скрипта

> Второе задание со *

Для ускорения работы можно запускать виртуальную машину с помощью командной
строки и утилиты gcloud.

Создадим shell-скрипт с названием create-reddit-vm.sh в директории
config-scripts.

Запишите в него команду которая запустит виртуальную машину из образа
подготовленного нами в рамках этого ДЗ, из семейства reddit-full.

Запуск и результат работы команды:

```bash
$ date; ./create-reddit-vm.sh; date

17 дек 2020 г.  2:31:26

-------------------------------
Starting my VM made with Packer
-------------------------------
Adding firewall rule...
Creating firewall...⠹Created [https://www.googleapis.com/compute/v1/projects/infra-297519/global/firewalls/default-puma-server].
Creating firewall...done.
NAME                 NETWORK  DIRECTION  PRIORITY  ALLOW     DENY  DISABLED
default-puma-server  default  INGRESS    1000      tcp:9292        False
Creating VM...
WARNING: You have selected a disk size of under [200GB]. This may result in poor I/O performance.
For more information, see: https://developers.google.com/compute/docs/disks#
performance.
Created [https://www.googleapis.com/compute/v1/projects/infra-297519/zones/europe-west1-b/instances/reddit-app].
NAME        ZONE            MACHINE_TYPE  PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP   STATUS
reddit-app  europe-west1-b  f1-micro                   10.132.0.15  35.205.129.9  RUNNING
Application started successfully!

17 дек 2020 г.  2:31:46
```

Проверяем работу приложения:
[http://35.205.129.9:9292](http://35.205.129.9:9292)

Все ок.

**Итого:**

- Новая ВМ создается из подготовленного с помощью *Packer* образа за **20**
  **секунд!**
- Приложение *Ruby* на *Puma*-сервере хранящее пользователей в *Mondgo DB*
  корректно функционирует.
- **Immutable Infrastructure рулит!**
