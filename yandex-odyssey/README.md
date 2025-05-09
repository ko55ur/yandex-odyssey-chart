# yandex-odyssey

Инсталяционный пакет сервиса yandex-odyssey

## Описание проекта

Многопоточный pooler-соединений, служащий для распределения
запросов по кластерам Postgres.
"Маршрутизирует" (распределяет) запросы по имени запрашиваемой БД
на основании шаблонов.
Служит единой точкой входа для всех запросов к БД Postgres.
Дополнительная информация и документация может быть найдена в
[официальном репозитории](https://github.com/yandex/odyssey).

### Использование

Текущая реализация позволяет "маршрутизировать" входящие запросы к одному из трех кластеров Postgres.
Для выбора соответствующего кластера в переменных окружения POSTGRES_HOST2_DB_LIST, POSTGRES_HOST3_DB_LIST
указываются шаблоны. Шаблон представляет собой строку, соответствующую требованиям оператора *LIKE* языка SQL.
При совпадении шаблона с именем запрашиваемой БД запрос будет отправлен в соответсвующий кластер:
кластер №2 - при совпадении с POSTGRES_HOST2_DB_LIST,
кластер №3 - при совпадении с POSTGRES_HOST3_DB_LIST.
В случае, если имя БД не соответствует ни одному из шаблонов в вышуказанных переменных, то запрос
будет обработан в кластере №1.
Важнейшими параметрами настройки являются имена целевых хостов с БД Postgres,
которые задаются в переменных POSTGRES_HOST1(2,3).

Для доступа к служебной информации рекомендуется использовать одного пользователя
(переменная окружения ODYSSEY_AUTH_USER) на всех базах данных кластера.
При этом авторизационные данные предлагается хранить в secret *yandex-odyssey*.

Настройка сервиса производится при помощи переменных окружения.

## Процесс установки

Установка данного сервиса осуществляется
при помощи пакетного менеджера [helm](https://helm.sh/).

Пример команды, производящей установку:

`helm install yandex-odyssey .`

## Параметры (values) развертывания

Для корректной установки необходимо задать необходимые переменные
окружения, а также параметры (values) развертывания.
Описание их представлено в таблице ниже:

| Параметр          | Описание                                                                                                                                                                                                                                                                                                              |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| image                     | Используемый образ из registry                                                                                                                                                                                                                                                                             |
| imageTag                  | Используемая версия образа                                                                                                                                                                                                                                                                            |
| resources.limits.cpu      | Максимальное количество потребляемых ядер процессора                                                                                                                                                                                                                          |
| resources.limits.memory   | Максимальное количество памяти, выделяемой сервису                                                                                                                                                                                                                               |
| resources.requests.cpu    | Количество процессорных ядер, выделяемых в момент запуска сервиса                                                                                                                                                                                                    |
| resources.requests.memory | Количество памяти, выделяемой в момент запуска сервиса                                                                                                                                                                                                                         |
| secret.name               | Имя secret, который содержит авторизационные данные для доступа к служебной информации кластеров                                                                                                                                                |
| secret.loginKey           | Ключ в*secret.name*, содержащий значение переменной среды *ODYSSEY_AUTH_USER*                                                                                                                                                                                                       |
| secret.passwordKey        | Ключ в*secret.name*, содержащий значение переменной среды *ODYSSEY_AUTH_PASSWORD*                                                                                                                                                                                                   |
| securityContext.create    | Параметр включает использование securityContext в deployment (Должно быть включено при развертывании в кластере*openshift*)                                                                                                                        |
| rbac.nonroot              | Включает создание RoleBinding system:openshift:scc:nonroot (Применимо только при развертывании в кластере*openshift*)                                                                                                                                               |
| rbac.restart              | Включает создание Role для выполнения манипуляций с deployment yandex-odyssey (Используеться для Job которая производит перезагрузку контейнера по расписанию)                                                |
| tls.odyssey.mode          | Режим работы TLS c клиентами. Допустимые значения: "**disable**", "**allow**", "**require**", "**verify_ca**", "**verify_full**". [Документация](https://github.com/yandex/odyssey/blob/master/documentation/configuration.md#tls-string)        |
| tls.postgres1.mode        | Режим работы TLS с кластером №1. Допустимые значения: "**disable**", "**allow**", "**require**", "**verify_ca**", "**verify_full**". [Документация](https://github.com/yandex/odyssey/blob/master/documentation/configuration.md#tls-string-1) |
| tls.postgres1.secret_name | Имя секрета, в котором содержится доверенный СA                                                                                                                                                                                                                                        |
| tls.postgres2.mode        | *по аналогии*                                                                                                                                                                                                                                                                                                     |
| tls.postgres2.secret_name | *по аналогии*                                                                                                                                                                                                                                                                                                     |
| tls.postgres3.mode        | *по аналогии*                                                                                                                                                                                                                                                                                                     |
| tls.postgres3.secret_name | *по аналогии*                                                                                                                                                                                                                                                                                                     |

## Переменные окружения

| Переменная        | Описание                                                                                                                                                                                                                                                                                                                                               |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| POSTGRES_HOST1              | Имя хоста кластера Postgres, на который будут отправлены запросы по умолчанию (кластер №1)                                                                                                                                                                                                   |
| POSTGRES_PORT1              | Сетевой порт, используемый кластером №1 для приема запросов                                                                                                                                                                                                                                                  |
| POSTGRES_HOST2              | Имя хоста кластера Postgres, на который будут отправлены запросы, соответвующие шаблону из переменной POSTGRES_HOST2_DB_LIST (кластер №2)                                                                                                                               |
| POSTGRES_PORT2              | Сетевой порт, используемый кластером №2 для приема запросов                                                                                                                                                                                                                                                  |
| POSTGRES_HOST3              | Имя хоста кластера Postgres, на который будут отправлены запросы, соответвующие шаблону из переменной POSTGRES_HOST3_DB_LIST (кластер №3)                                                                                                                               |
| POSTGRES_PORT3              | Сетевой порт, используемый кластером №3 для приема запросов                                                                                                                                                                                                                                                  |
| POSTGRES_HOST2_DB_LIST      | Список шаблонов (разделитель пробел), при совпадении которых с именем БД произойдет перенаправление запроса в кластер №2; формат шаблона соответствует требованиям оператора LIKE языка SQL            |
| POSTGRES_HOST3_DB_LIST      | Список шаблонов (разделитель пробел), при совпадении которых с именем БД произойдет перенаправление запроса в кластер №3; формат шаблона соответствует требованиям оператора LIKE языка SQL            |
| ODYSSEY_AUTH_USER           | Имя пользователя, под которым будет производиться запрос служебной (авторизационные данные из pg_shadow) информации на кластерах Postgres                                                                                                                |
| ODYSSEY_AUTH_PASSWORD       | Пароль для пользователя, указанного в переменной ODYSSEY_AUTH_USER                                                                                                                                                                                                                                                   |
| ODYSSEY_DEBUG               | Включает расширенное логгирование (в том числе вывод sql-запросов)                                                                                                                                                                                                                                        |
| ODYSSEY_LOG                 | Включает минимальное логгирование (отключаем чтобы не тек по памяти)                                                                                                                                                                                                                                 |
| ODYSSEY_POOL_TYPE           | Режим "маршрутизации":`session` - связывает входящее соединение с соединением к кластеру Postgres до конца сессии, `transaction` - до завершения текущей транзакции                                                                            |
| ODYSSEY_POOL_SIZE           | МаксималДля изменения количества кластеров postgres образ нужно будет пересобирать. Сейчас образ настроен на использование трех кластеров.ное количество соединений к каждому из кластеров postgres |
| ODYSSEY_POOL_TTL            | Закрывать соединение к кластеру в случае простоя более, чем значение переменной (в секундах)                                                                                                                                                                                      |
| ODYSSEY_POOL_TIMEOUT        | Максимальное время ожидания соединения с кластером, в случае превышения - соединение клиента разрывается (указывается в милисекундах)                                                                                                        |
| ODYSSEY_POOL_DISCARD        | Выполнить команду*DISCARD ALL* до использования серверного соединения клиентами                                                                                                                                                                                                                  |
| ODYSSEY_POOL_CANCEL         | Запустить отдельное*CANCEL* соединение, в случае потери связи с сервером, выполняющим запрос                                                                                                                                                                                         |
| ODYSSEY_POOL_ROLLBACK       | Выполнить команду*ROLLBACK*, если сервер потерял соединение с клиентом, выполняющим транзакцию                                                                                                                                                                                      |
| ODYSSEY_CACHE_COROUTINE     | Количество кэшируемых соединений для coroutine                                                                                                                                                                                                                                                                                |
| ODYSSEY_MONITORING_PASSWORD | Пароль для пользователя метрик (default monitor)                                                                                                                                                                                                                                                                                    |
| ODYSSEY_MONITORING_USER     | Пользователь метрик (default monitor)                                                                                                                                                                                                                                                                                                        |

## Параметры (values) развертывания yandex-odyssey-exporter

Для корректной установки необходимо задать необходимые переменные
окружения, а также параметры (values) развертывания.
Описание их представлено в таблице ниже:

| Параметр          | Описание                                                                                                           |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| image                     | Используемый образ из registry                                                                          |
| imageTag                  | Используемая версия образа                                                                         |
| resources.limits.cpu      | Максимальное количество потребляемых ядер процессора                       |
| resources.limits.memory   | Максимальное количество памяти, выделяемой сервису                            |
| resources.requests.cpu    | Количество процессорных ядер, выделяемых в момент запуска сервиса |
| resources.requests.memory | Количество памяти, выделяемой в момент запуска сервиса                      |

| host                      | Хост одиссея по умолчанию 127.0.0.1              |

| port                      | Порт для метрик по умолчанию 9127                |

| connection.dbname         | Имя служебной, локальной БД одиссея по умолчанию console    |

| connection.sslmode        | Включение в строку подключения к одиссею режима ssl по умолчанию sslmode=disable    |

## Диагностика

В контейнере проверить наличие и содержимое следующих файлов:

- /home/appuser/odyssey/psql02_list.txt - содержит список имен баз и их владельцев, полученный из переменной POSTGRES_HOST2_DB_LIST
- /home/appuser/odyssey/psql03_list.txt - содержит список имен баз и их владельцев, полученный из переменной POSTGRES_HOST3_DB_LIST
- /home/appuser/odyssey/odyssey.conf - в конце файла должны присутствовать маршруты к спискам БД файлов psql02_list.txt, psql03_list.txt

Если вышеуказанные файлы или записи в них отсутствуют, то необходимо проверить синтаксис значений добавленных в переменные POSTGRES_HOST2_DB_LIST, POSTGRES_HOST3_DB_LIST или наличие баз на искомых postgres кластерах.

### Мониторинга состояния

Подключение к локальной базе yandex-odyssey осуществляется командой:

```bash
psql -h localhost -d console
```

После подключения к локальной БД воспользоваться следующими командами,
для получения более подробной информации о работе сервиса:

```bash
show pools;
show stats;
show clients;
show databases;
show servers;
```
