-- Script de referencia (T-SQL / SQL Server). As tabelas tambem sao criadas
-- automaticamente pelo Hibernate (ddl-auto=update) na primeira execucao.
CREATE TABLE marcas (
    id            BIGINT        NOT NULL PRIMARY KEY,
    nome_marca    VARCHAR(100)  NOT NULL,
    pais_origem   VARCHAR(50)   NOT NULL,
    ano_fundacao  INT           NOT NULL,
    site_oficial  VARCHAR(150)  NULL,
    ativa         BIT           NOT NULL
);

CREATE TABLE modelos (
    id                BIGINT        NOT NULL PRIMARY KEY,
    nome_modelo       VARCHAR(100)  NOT NULL,
    ano_lancamento    INT           NOT NULL,
    tipo_combustivel  VARCHAR(30)   NOT NULL,
    preco_base        FLOAT         NOT NULL,
    observacoes       VARCHAR(255)  NULL
);
