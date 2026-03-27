# Ruler Sandbox - Local Development Environment

Полностью настроенный локальный sandbox для разработки Kubernetes-native приложения с мониторингом.

## Архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                         KIND CLUSTER                         │
│                                                              │
│  Namespace: monitoring                                        │
│  ├── VictoriaMetrics (хранение метрик)                       │
│  ├── Grafana (визуализация) → http://grafana.local:8080      │
│  ├── OpenTelemetry Collector (сбор метрик)                   │
│  └── VM Operator (CRD для VMRule)                            │
│                                                              │
│  Namespace: ruler-system (для будущего приложения)           │
│  ├── ruler-server (API с SQLite)                             │
│  └── ruler-controller (синхронизация с VMRule)               │
└─────────────────────────────────────────────────────────────┘
```

## Быстрый старт

### 1. Подготовка

Убедитесь, что установлены:
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)
- [Task](https://taskfile.dev/installation/)

### 2. Добавить hosts запись

```bash
echo "127.0.0.1 grafana.local" | sudo tee -a /etc/hosts
```

### 3. Запустить инфраструктуру

```bash
cd /path/to/ruler

# Полный деплой (кластер + инфраструктура)
task infra:all

# Или по шагам:
task cluster:create      # Создать kind кластер
task helm:repos          # Добавить Helm репозитории
task infra:deploy        # Развернуть компоненты
```

### 4. Доступ к сервисам

**Grafana:** http://grafana.local:8080
- Login: `admin`
- Password: см. вывод команды `task infra:grafana`

**VictoriaMetrics:** доступен внутри кластера по адресу:
`http://victoria-metrics-victoria-metrics-single-server.monitoring.svc.cluster.local:8428`

### 5. Генерация тестовых метрик

```bash
# Развернуть OpenTelemetry Demo (генерирует метрики)
task demo:deploy
```

## Команды Task

```bash
task --list              # Показать все команды

# Управление кластером
task cluster:create      # Создать kind кластер
task cluster:delete      # Удалить кластер
task cluster:reset       # Пересоздать кластер

# Инфраструктура
task infra:deploy        # Развернуть все компоненты
task infra:delete        # Удалить все компоненты

# Отдельные компоненты
task infra:victoria-metrics
task infra:grafana
task infra:otel-collector
task infra:vm-operator
task infra:ingress

# Приложение (когда будут образы)
task app:load-images     # Загрузить локальные образы в kind
task app:deploy          # Развернуть ruler-server и ruler-controller
task app:delete          # Удалить приложение
task app:logs            # Посмотреть логи

# Демо
task demo:deploy         # Развернуть OpenTelemetry Demo
task demo:delete         # Удалить демо

# Статус
task status              # Показать статус кластера
```

## Проверка работы

### Проверить, что метрики поступают:

```bash
# Проверить метрики в VictoriaMetrics
kubectl exec -n monitoring statefulset/victoria-metrics-victoria-metrics-single-server \
  -- wget -qO- 'http://127.0.0.1:8428/api/v1/label/__name__/values'
```

### Проверить datasource в Grafana:

1. Открыть http://grafana.local:8080
2. Login: admin / (пароль из вывода команды `task infra:grafana`)
3. Configuration → Data sources
4. VictoriaMetrics должен быть зеленым

## Структура проекта

```
ruler/
├── Taskfile.yml                    # Команды управления
├── sandbox/
│   ├── kind-config.yaml            # Конфигурация kind кластера
│   ├── prepare-cluster.sh          # Скрипт проверки зависимостей
│   ├── config/
│   │   ├── infra/                  # Конфиги инфраструктуры
│   │   │   ├── victoria-metrics/
│   │   │   ├── grafana/
│   │   │   ├── otel-collector/
│   │   │   ├── vm-operator/
│   │   │   └── ingress-nginx/
│   │   └── app/                    # Конфиги приложения
│   │       ├── namespace.yaml
│   │       ├── ruler-server/
│   │       └── ruler-controller/
│   └── scripts/
│       ├── load-images.sh          # Загрузка образов в kind
│       └── setup-hosts.sh          # Настройка /etc/hosts
├── server/                         # Код ruler-server (gRPC API + SQLite)
└── controller/                     # Код ruler-controller
```

## Что протестировано

✅ **Kind cluster** - создан и работает  
✅ **VictoriaMetrics** - развернут, данные сохраняются в PVC  
✅ **Grafana** - развернут, доступен через ingress на http://grafana.local:8080  
✅ **OpenTelemetry Collector** - собирает метрики и отправляет в VictoriaMetrics  
✅ **VM Operator** - развернут для управления VMRule CRDs  
✅ **Ingress Controller** - работает, маршрутизирует трафик  
✅ **Метрики** - поступают в VictoriaMetrics (проверено!)  

## Известные ограничения

1. **OpenTelemetry Demo** - требует много ресурсов, может долго разворачиваться
2. **Данные** - при удалении kind кластера данные VictoriaMetrics теряются (это ожидаемое поведение)
3. **Локальные образы** - для ruler-server и ruler-controller нужно предварительно собрать образы

## Следующие шаги

1. Собрать образы ruler-server и ruler-controller
2. Загрузить их в kind: `task app:load-images`
3. Развернуть приложение: `task app:deploy`
4. Проверить, что controller создает VMRule CRDs

## Troubleshooting

### Grafana не доступна по grafana.local:8080

```bash
# Проверить ingress
kubectl get ingress -n monitoring

# Проверить, что ingress controller запущен
kubectl get pods -n ingress-nginx

# Проверить hosts файл
cat /etc/hosts | grep grafana
```

### Нет метрик в VictoriaMetrics

```bash
# Проверить logs collector'а
kubectl logs -n monitoring -l app.kubernetes.io/name=opentelemetry-collector

# Проверить доступность VictoriaMetrics из collector'а
kubectl exec -n monitoring statefulset/victoria-metrics-victoria-metrics-single-server \
  -- wget -qO- 'http://127.0.0.1:8428/health'
```

### Проблемы с kind

```bash
# Полный сброс
kind delete cluster --name=ruler
task cluster:create
```
