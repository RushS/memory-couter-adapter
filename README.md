# Memory Counter Adapter

一個設計用於在 AWS 上部署的 Spring Boot 微服務，使用 ECR 和 ECS 進行容器化部署。

## 系統需求

- Java 17
- Maven 3.6+
- Docker
- AWS CLI 已配置適當權限
- jq (用於 ECS 部署腳本)

## 本地開發

### 建置和執行

```bash
# 建置應用程式
mvn clean package

# 本地執行
java -jar target/memory-counter-adapter-1.0.0.jar

# 或使用 Maven 執行
mvn spring-boot:run
```

應用程式將在 `http://localhost:8080` 可用

### 健康檢查端點

- 健康檢查端點：`http://localhost:8080/health`
- 根端點：`http://localhost:8080/`

## Docker 容器化

### 建置 Docker 映像檔

```bash
docker build -t memory-counter-adapter .
```

### 執行 Docker 容器

```bash
docker run -p 8080:8080 memory-counter-adapter
```

## AWS 部署

### ECR 部署

使用提供的腳本建置並推送到 ECR：

```bash
./scripts/build-and-push.sh <aws-region> <ecr-repository-name> [tag]

# 範例：
./scripts/build-and-push.sh us-west-2 memory-counter-adapter latest
```

### ECS 部署

使用提供的腳本部署到 ECS：

```bash
./scripts/deploy-to-ecs.sh <aws-region> <cluster-name> <service-name> <task-definition-family> <image-uri>

# 範例：
./scripts/deploy-to-ecs.sh us-west-2 my-cluster memory-counter-service memory-counter-task 123456789.dkr.ecr.us-west-2.amazonaws.com/memory-counter-adapter:latest
```

## 完整部署流程

### 1. 準備 AWS 環境

確保 AWS CLI 已配置適當權限：

```bash
# 配置 AWS 認證
aws configure

# 驗證身份
aws sts get-caller-identity
```

### 2. 建置並推送到 ECR

```bash
# 建置並推送映像檔到 ECR
./scripts/build-and-push.sh us-west-2 memory-counter-adapter latest
```

腳本會自動：
- 建置 Docker 映像檔
- 建立 ECR repository（如果不存在）
- 推送映像檔到 ECR

### 3. 部署到 ECS（可選）

如果您使用 ECS，可以使用部署腳本：

```bash
./scripts/deploy-to-ecs.sh us-west-2 my-cluster memory-counter-service memory-counter-task <image-uri>
```

### 4. 驗證部署

部署完成後，可以透過以下方式驗證：

```bash
# 檢查健康狀態
curl http://your-service-endpoint/health

# 檢查服務資訊
curl http://your-service-endpoint/
```

## 配置說明

應用程式使用 `application.yml` 進行配置，主要設定：

- 伺服器埠號：8080
- Spring profiles 支援
- 管理端點已啟用
- 健康檢查已配置

## 環境變數

可以透過環境變數覆蓋配置：

- `SPRING_PROFILES_ACTIVE`：設定活動的 Spring profile
- `SERVER_PORT`：設定伺服器埠號

## 專案結構

```
├── src/
│   └── main/
│       ├── java/com/example/memorycounter/
│       │   ├── MemoryCounterApplication.java        # 主應用程式類別
│       │   └── controller/
│       │       └── HealthController.java            # 健康檢查控制器
│       └── resources/
│           └── application.yml                      # 應用程式配置
├── scripts/
│   ├── build-and-push.sh                          # ECR 建置推送腳本
│   └── deploy-to-ecs.sh                           # ECS 部署腳本
├── Dockerfile                                      # Docker 映像檔配置
├── pom.xml                                         # Maven 專案配置
└── README.md                                       # 專案說明文件
```

## 常見問題

### Q: 如何修改服務埠號？
A: 在 `application.yml` 中修改 `server.port` 設定，或使用環境變數 `SERVER_PORT`。

### Q: 如何查看應用程式日誌？
A: 
```bash
# Docker 容器日誌
docker logs <container-id>

# ECS 任務日誌（透過 CloudWatch）
aws logs get-log-events --log-group-name /ecs/memory-counter-task
```

### Q: 如何更新部署？
A: 重新執行建置推送腳本，然後執行部署腳本：
```bash
./scripts/build-and-push.sh us-west-2 memory-counter-adapter latest
./scripts/deploy-to-ecs.sh us-west-2 my-cluster memory-counter-service memory-counter-task <new-image-uri>
```

## 安全性考量

- 使用非 root 使用者執行容器
- 映像檔基於 Alpine Linux 減少攻擊面
- 健康檢查確保服務可用性
- 適當的 AWS IAM 權限配置