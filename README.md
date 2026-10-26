# modelocarro — Checkpoint 3

API REST em **Java 17 + Spring Boot** para gerenciamento de **marcas** e **modelos** de
carros, com persistência em **Microsoft SQL Server** (Spring Data JPA). A imagem é
conteinerizada com **Docker**, publicada no **Docker Hub** por um workflow do **GitHub
Actions** e implantada no **Microsoft Azure** (Azure Container Apps + Azure SQL Database).

Microservices and Web Engineering — Check Point 3 (2º semestre/2026).

## Links para avaliação

| Item | URL |
|---|---|
| Repositório GitHub | `https://github.com/<usuario>/<repositorio>` |
| Imagem no Docker Hub | `https://hub.docker.com/r/<usuario-dockerhub>/modelocarro` |
| Aplicação no Azure | `https://<rm>-modelocarro.<hash>.brazilsouth.azurecontainerapps.io` |
| Swagger UI (Azure) | `https://<url-azure>/` |
| OpenAPI JSON (Azure) | `https://<url-azure>/v3/api-docs` |

## Integrantes

| Nome completo | RM |
|---|---|
| Nicolas Varella Barros Padovam | 556586 |
| Vitor Portela Fantinato | 554540 |

---

## Tecnologias

- Java 17 e Spring Boot 4 (Web MVC, Validation, Data JPA)
- Spring Data JPA / Hibernate (`SQLServerDialect`) e driver `mssql-jdbc`
- SpringDoc OpenAPI (Swagger UI)
- Lombok e ModelMapper
- Maven (wrapper `mvnw` incluso)
- Docker / Docker Compose, GitHub Actions, Azure Container Apps e Azure SQL Database

## Arquitetura em camadas

```
src/main/java/br/com/fiap/vitorportelaf/modelocarro
├── Application.java
├── config/       # OpenApiConfig (metadados do Swagger)
├── controller/   # endpoints REST /api/v1 (MarcaController, ModeloController, PingController)
├── dto/          # requisição/resposta (CreateRequest, UpdateRequest, Response) com Bean Validation
├── exception/    # GlobalExceptionHandler (400 com mensagens por campo)
├── mapper/       # conversão DTO <-> entidade (ModelMapper)
├── model/        # entidades JPA (Marca -> tabela marcas, Modelo -> tabela modelos)
├── repository/   # interfaces Spring Data JPA
└── service/      # regras de negócio e acesso aos repositórios
```

Fluxo: `Controller → Service → Repository → SQL Server`. O controller só trabalha com
DTOs, e as entidades nunca são expostas diretamente.

| Entidade | Tabela | Colunas |
|---|---|---|
| `Marca` | `marcas` | `id`, `nome_marca`, `pais_origem`, `ano_fundacao`, `site_oficial`, `ativa` |
| `Modelo` | `modelos` | `id`, `nome_modelo`, `ano_lancamento`, `tipo_combustivel`, `preco_base`, `observacoes` |

As tabelas são criadas pelo Hibernate (`ddl-auto=update`). O DDL equivalente está em
[`scripts/schema.sql`](scripts/schema.sql). Só o **database** precisa existir.

---

## 1. Configuração da conexão com o SQL Server

A conexão é definida por *profiles* em `src/main/resources`:

| Profile | Arquivo | Uso |
|---|---|---|
| `dev` | `application-dev.properties` | SQL Server local em `localhost:1433`, database `api`, usuário `sa`, senha `1q2w3e4R@` |
| `prd` | `application-prd.properties` | tudo por **variáveis de ambiente** (Docker e Azure) |

Variáveis do profile `prd`:

| Variável | Descrição | Local (compose) | Azure |
|---|---|---|---|
| `SPRING_PROFILES_ACTIVE` | profile | `prd` | `prd` |
| `DB_SERVER_URL` | host | `sqlserver` | `<servidor>.database.windows.net` |
| `DB_SERVER_PORT` | porta | `1433` | `1433` |
| `DB_SCHEMA` | database | `api` | `api` |
| `DB_USER` | usuário | `sa` | admin do Azure SQL |
| `DB_PWD` | senha | `1q2w3e4R@` | senha do Azure SQL |
| `DB_ENCRYPT` | TLS na conexão (padrão `true`) | `false` | `true` |
| `DB_TRUST_CERT` | confia em certificado autoassinado (padrão `false`) | `true` | `false` |

> Nenhuma credencial de produção fica no repositório. A senha `1q2w3e4R@` serve apenas
> para o SQL Server local de desenvolvimento.

## 2. Executar localmente

### Opção A — tudo com Docker Compose (API + SQL Server)

```bash
docker compose up -d --build
# aguarde ~1 min e acesse http://localhost:8080/
docker compose down -v      # para encerrar e apagar os dados
```

O compose sobe o SQL Server, cria o database `api` e inicia a API no profile `prd`.

### Opção B — Maven + SQL Server em container

```bash
docker run -d --name sqlserver -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=1q2w3e4R@" \
  -p 1433:1433 mcr.microsoft.com/mssql/server:2022-latest

# após ~20s, crie o database
docker exec -it sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "1q2w3e4R@" -C \
  -Q "CREATE DATABASE api"

./mvnw spring-boot:run -Dspring-boot.run.profiles=dev      # Windows: mvnw.cmd spring-boot:run "-Dspring-boot.run.profiles=dev"
```

## 3. Executar com Docker (imagem publicada)

```bash
docker pull <usuario-dockerhub>/modelocarro:latest   # ou :v1, :<sha>

docker run -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prd \
  -e DB_SERVER_URL=host.docker.internal \
  -e DB_SERVER_PORT=1433 \
  -e DB_SCHEMA=api \
  -e DB_USER=sa \
  -e DB_PWD='1q2w3e4R@' \
  -e DB_ENCRYPT=false -e DB_TRUST_CERT=true \
  <usuario-dockerhub>/modelocarro:latest
```

No Linux, adicione `--add-host=host.docker.internal:host-gateway`. Para construir a imagem
localmente, use `docker build -t modelocarro:local .` (o `Dockerfile` tem build multi-stage
e já compila o projeto).

## 4. Continuous Delivery — GitHub Actions

| Workflow | Gatilho | O que faz |
|---|---|---|
| [`continuous_delivery.yml`](.github/workflows/continuous_delivery.yml) | push na `develop` (ou manual) | build da imagem e push no Docker Hub com as tags `latest`, `v<nº execução>` e `<sha curto>` |
| [`deploy.yml`](.github/workflows/deploy.yml) | push na `main` (ou manual) | atualiza o Azure Container App com a imagem `:latest` (opcional) |

Configuração em **Settings → Secrets and variables → Actions**:

| Tipo | Nome | Valor |
|---|---|---|
| Variable | `DOCKER_USER` | usuário do Docker Hub |
| Secret | `DOCKER_TOKEN` | *Personal access token* do Docker Hub |
| Secret | `AZURE_CREDENTIALS`, `DB_SERVER_URL`, `DB_SERVER_PORT`, `DB_SCHEMA`, `DB_USER`, `DB_PWD` | só para o `deploy.yml` |
| Variable | `AZURE_RESOURCE_GROUP`, `AZURE_CONTAINER_APP` | só para o `deploy.yml` |

Nenhuma credencial fica no código: tudo vem de *secrets* e *variables*.

## 5. Deploy no Azure

O passo a passo completo, do Docker ao Azure, está em **[DEPLOY_AZURE.md](DEPLOY_AZURE.md)**:
Azure SQL Database (serverless) + Azure Container Apps rodando a imagem do Docker Hub, com
a senha do banco guardada como *secret* do Container App.

## 6. Testar a API

Swagger UI: `http://localhost:8080/` (local) ou `https://<url-azure>/` (Azure).

| Método | Endpoint | Descrição | Sucesso | Erros |
|---|---|---|---|---|
| GET | `/ping` | health check (`pong`) | 200 | — |
| POST | `/api/v1/marcas` | cadastra marca | 201 | 400, 409 (id já existe) |
| GET | `/api/v1/marcas` | lista marcas | 200 | — |
| GET | `/api/v1/marcas/{id}` | busca marca | 200 | 404 |
| PUT | `/api/v1/marcas/{id}` | altera marca (todos os campos) | 200 | 400, 404 |
| DELETE | `/api/v1/marcas/{id}` | exclui marca | 204 | 404 |
| POST | `/api/v1/modelos` | cadastra modelo | 201 | 400, 409 |
| GET | `/api/v1/modelos` | lista modelos | 200 | — |
| GET | `/api/v1/modelos/{id}` | busca modelo | 200 | 404 |
| PUT | `/api/v1/modelos/{id}` | altera modelo | 200 | 400, 404 |
| DELETE | `/api/v1/modelos/{id}` | exclui modelo | 204 | 404 |

> O `id` é informado pelo cliente no POST.

### Roteiro com `curl`

Troque `BASE` pela URL do Azure para testar o ambiente implantado.

```bash
BASE=http://localhost:8080

# Marcas
curl -i -X POST $BASE/api/v1/marcas -H "Content-Type: application/json" \
  -d '{"id":1,"nome":"Toyota","paisOrigem":"Japão","anoFundacao":1937,"siteOficial":"https://www.toyota.com","ativa":true}'
curl $BASE/api/v1/marcas
curl $BASE/api/v1/marcas/1
curl -i -X PUT $BASE/api/v1/marcas/1 -H "Content-Type: application/json" \
  -d '{"nome":"Toyota Motor","paisOrigem":"Japão","anoFundacao":1937,"siteOficial":"https://global.toyota","ativa":true}'
curl -i -X DELETE $BASE/api/v1/marcas/1

# Modelos
curl -i -X POST $BASE/api/v1/modelos -H "Content-Type: application/json" \
  -d '{"id":1,"nome":"Corolla","anoLancamento":2024,"tipoCombustivel":"Flex","precoBase":150000.0,"observacoes":"Versão XEi"}'
curl $BASE/api/v1/modelos
curl -i -X PUT $BASE/api/v1/modelos/1 -H "Content-Type: application/json" \
  -d '{"nome":"Corolla Hybrid","anoLancamento":2025,"tipoCombustivel":"Híbrido","precoBase":185000.0,"observacoes":"Versão Altis"}'
curl -i -X DELETE $BASE/api/v1/modelos/1

# Validação -> 400 com mensagens por campo
curl -i -X POST $BASE/api/v1/marcas -H "Content-Type: application/json" -d '{"id":2}'
```

### Conferir os dados no SQL Server

```bash
# local
docker exec -it sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "1q2w3e4R@" -C -d api \
  -Q "SELECT * FROM marcas; SELECT * FROM modelos;"
```

No Azure, use **Portal → SQL database `api` → Query editor** com `SELECT * FROM marcas;`.
