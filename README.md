# Procesador de Imágenes — Infraestructura como Código (Terraform)

Arquitectura serverless desplegada en AWS con Terraform, que procesa imágenes subidas por un cliente HTTP, las almacena en S3, las encola en SQS y las recorta de forma circular mediante una Lambda asíncrona.

---

## Diagrama de Arquitectura

```mermaid
%%{
  init: {
    "theme": "base",
    "themeVariables": {
      "primaryColor": "#1e293b",
      "primaryTextColor": "#f8fafc",
      "primaryBorderColor": "#334155",
      "lineColor": "#94a3b8",
      "secondaryColor": "#0f172a",
      "tertiaryColor": "#1e293b",
      "background": "#0f172a",
      "mainBkg": "#1e293b",
      "nodeBorder": "#475569",
      "clusterBkg": "#0f172a",
      "titleColor": "#f8fafc",
      "edgeLabelBackground": "#1e293b",
      "fontFamily": "monospace"
    },
    "flowchart": { "curve": "basis", "padding": 20 }
  }
}%%

flowchart TD

  subgraph INTERNET["Internet"]
    CLIENT["Client\n---\nPOST /upload\nmultipart/form-data or JSON+base64\nMax size: 10 MB\nAllowed: jpg, png, gif, webp"]
  end

  subgraph AWS["AWS Account — Region: us-east-1"]

    subgraph EDGE["AWS Managed Edge Services — outside VPC"]

      APIGW["API Gateway HTTP API v2\n---\nRoute: POST /upload\nProtocol: HTTPS, TLS 1.2+\nPayload format: 2.0\nCORS: enabled\nStage: default, auto-deploy\nThrottling: 10,000 rps\nAccess logs to CloudWatch"]

      subgraph S3_SVC["Amazon S3 — Bucket: image-processor-env-images-suffix"]
        S3_UPLOADS["uploads/ prefix\n---\nStores: original images\nSSE: AES-256\nVersioning: enabled\nLifecycle: expire after 30 days\nAccess: fully private\nOn ObjectCreated fires SQS notification"]
        S3_PROCESSED["processed/ prefix\n---\nStores: cropped circular PNGs\nSSE: AES-256\nOutput: 40x40 px, PNG, transparent bg\nLifecycle: expire after 90 days\nAccess: fully private"]
      end

      subgraph SQS_SVC["Amazon SQS"]
        SQS_QUEUE["Main Queue\n---\nVisibility timeout: 360 s\nRetention: 1 day\nLong polling: 20 s\nMax receives before DLQ: 3"]
        SQS_DLQ["Dead-Letter Queue\n---\nRetention: 14 days\nCloudWatch alarm on any visible message"]
      end

    end

    subgraph VPC["VPC — CIDR: 10.0.0.0/16"]

      subgraph PRIV_A["Private Subnet AZ-a — 10.0.11.0/24"]
        LAMBDA_UPLOAD["upload-lambda\n---\nRuntime: nodejs20.x\nMemory: 256 MB — Timeout: 30 s"]
        LAMBDA_CROP["crop-lambda\n---\nRuntime: nodejs20.x\nMemory: 512 MB — Timeout: 60 s"]
      end

      subgraph VPCE["VPC Endpoints"]
        VPCE_S3["S3 Gateway Endpoint"]
        VPCE_SQS["SQS Interface Endpoint"]
      end

    end

  end

  CLIENT -->|"1 - HTTPS POST /upload"| APIGW
  APIGW -->|"2 - Lambda Proxy Invoke"| LAMBDA_UPLOAD
  LAMBDA_UPLOAD -->|"3 - s3:PutObject"| VPCE_S3
  VPCE_S3 -->|"writes to uploads/"| S3_UPLOADS
  S3_UPLOADS -->|"4 - S3 Event Notification"| SQS_QUEUE
  SQS_QUEUE -->|"5 - ESM trigger, batch size 5"| LAMBDA_CROP
  LAMBDA_CROP -->|"6 - s3:GetObject"| VPCE_S3
  LAMBDA_CROP -->|"7 - s3:PutObject"| VPCE_S3
  VPCE_S3 -->|"writes to processed/"| S3_PROCESSED
  SQS_QUEUE -->|"after 3 failed receives"| SQS_DLQ
```

---

## Estructura del Proyecto

```
project/
├── modules/
│   ├── networking/        # VPC, subnets, IGW, NAT GW, route tables, SGs
│   ├── storage/           # S3 bucket, lifecycle, notificaciones
│   ├── messaging/         # SQS main queue + DLQ, alarmas CloudWatch
│   ├── compute/           # Lambda functions, IAM roles
│   ├── observability/     # CloudWatch log groups
│   └── api_gateway/       # API Gateway REST, integración Lambda
├── envs/
│   ├── dev/               # Entorno de desarrollo
│   ├── qa/                # Entorno de QA
│   └── prod/              # Entorno de producción
├── lambda/
│   ├── upload/            # Código fuente Node.js upload-lambda
│   └── crop/              # Código fuente Node.js crop-lambda
└── README.md
```

---

## Prerrequisitos

- Terraform >= 1.6
- AWS CLI v2 configurado con perfil IAM con permisos sobre Lambda, S3, SQS, VPC, IAM y CloudWatch
- Node.js 20.x
- Git

## Flujo de trabajo con Gitflow

Las ramas del proyecto siguen la convención de Gitflow:

- `main` — código estable y desplegado
- `develop` — integración de funcionalidades
- `funcionalidad/<nombre>` — desarrollo de cada módulo

---

## Comandos Terraform

```bash
# Inicializar
terraform init

# Validar
terraform validate

# Planear
terraform plan -out=tfplan.qa

# Aplicar
terraform apply "tfplan.qa"

# Destruir
terraform destroy
```

---

## Entornos

| Entorno | Directorio |
|---|---|
| DEV | envs/dev |
| QA | envs/qa |
| PROD | envs/prod |

## Módulos

### networking
Provisiona VPC, subnets públicas y privadas en 2 AZs, Internet Gateway, NAT Gateways, Route Tables, Security Groups y VPC Endpoints para S3 (Gateway) y SQS (Interface).

### storage
Bucket S3 privado con SSE AES-256, versionado habilitado, lifecycle rules (uploads: 30 días, processed: 90 días) y notificación S3 → SQS al crear objetos en `uploads/`.

### messaging
Cola SQS principal con redrive policy hacia DLQ (máx. 3 reintentos), política de recurso para S3, y alarma CloudWatch cuando la DLQ tenga mensajes visibles.

### compute
Roles IAM con privilegio mínimo, Lambda `upload-service` (256 MB, 30s) y Lambda `crop-service` (512 MB, 60s) con VPC config, Event Source Mapping SQS → crop con `ReportBatchItemFailures`.

### observability
Log Groups de CloudWatch para ambas Lambdas y API Gateway, con retención configurable por entorno.

### api_gateway
API Gateway REST con ruta `POST /upload`, integración Lambda proxy, stage con auto-deploy y permisos de invocación.

---

## Flujo de Datos

1. El cliente envía `POST /upload` con la imagen al API Gateway
2. API Gateway invoca `upload-lambda`
3. `upload-lambda` sube la imagen al prefix `uploads/` del bucket S3 vía VPC Endpoint
4. S3 dispara una notificación a la cola SQS principal
5. El Event Source Mapping activa `crop-lambda` con batch size 5
6. `crop-lambda` descarga la imagen desde `uploads/`
7. `crop-lambda` genera un recorte circular 40×40 px en PNG
8. `crop-lambda` sube el resultado al prefix `processed/`
9. Si el procesamiento falla 3 veces, el mensaje pasa a la DLQ y se activa la alarma CloudWatch

---

## Convenciones de Commits

Este proyecto usa [Conventional Commits]
