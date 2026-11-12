-- SEEK PACK - PostgreSQL
-- Sistema de cadastro e rastreamento de encomendas

CREATE SCHEMA seek_pack;

-- 1. SEQUÊNCIAS

CREATE SEQUENCE seek_pack.seq_usuarios START 1;
CREATE SEQUENCE seek_pack.seq_encomendas START 1;
CREATE SEQUENCE seek_pack.seq_eventos START 1;

-- 2. TABELAS

CREATE TABLE seek_pack.usuarios (
    id INTEGER PRIMARY KEY DEFAULT nextval('seek_pack.seq_usuarios'),
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    data_cadastro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE seek_pack.encomendas (
    id INTEGER PRIMARY KEY DEFAULT nextval('seek_pack.seq_encomendas'),
    usuario_id INTEGER NOT NULL REFERENCES seek_pack.usuarios(id),
    codigo_rastreio VARCHAR(20) NOT NULL UNIQUE,
    origem VARCHAR(100) NOT NULL,
    destino VARCHAR(100) NOT NULL,
    previsao_entrega DATE,
    status VARCHAR(30) NOT NULL DEFAULT 'POSTADO'
        CHECK (status IN ('POSTADO', 'EM_TRANSITO', 'AGUARDANDO_RETIRADA', 'ENTREGUE'))
);

CREATE TABLE seek_pack.eventos_rastreamento (
    id INTEGER PRIMARY KEY DEFAULT nextval('seek_pack.seq_eventos'),
    encomenda_id INTEGER NOT NULL REFERENCES seek_pack.encomendas(id),
    status VARCHAR(30) NOT NULL
        CHECK (status IN ('POSTADO', 'EM_TRANSITO', 'AGUARDANDO_RETIRADA', 'ENTREGUE')),
    descricao VARCHAR(255) NOT NULL,
    localizacao VARCHAR(100) NOT NULL,
    data_evento TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Vincula as sequências às suas respectivas colunas.
ALTER SEQUENCE seek_pack.seq_usuarios OWNED BY seek_pack.usuarios.id;
ALTER SEQUENCE seek_pack.seq_encomendas OWNED BY seek_pack.encomendas.id;
ALTER SEQUENCE seek_pack.seq_eventos OWNED BY seek_pack.eventos_rastreamento.id;

-- 3. ÍNDICES

CREATE INDEX idx_encomendas_usuario
    ON seek_pack.encomendas(usuario_id);

CREATE INDEX idx_encomendas_status
    ON seek_pack.encomendas(status);

CREATE INDEX idx_eventos_encomenda_data
    ON seek_pack.eventos_rastreamento(encomenda_id, data_evento DESC, id DESC);

-- 4. FUNÇÃO E TRIGGER
-- Ao registrar um evento, atualiza o status da encomenda
-- somente se ele for o evento mais recente.

CREATE FUNCTION seek_pack.atualizar_status_encomenda()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE seek_pack.encomendas
    SET status = NEW.status
    WHERE id = NEW.encomenda_id
      AND NEW.id = (
          SELECT id
          FROM seek_pack.eventos_rastreamento
          WHERE encomenda_id = NEW.encomenda_id
          ORDER BY data_evento DESC, id DESC
          LIMIT 1
      );

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_atualizar_status
AFTER INSERT ON seek_pack.eventos_rastreamento
FOR EACH ROW
EXECUTE FUNCTION seek_pack.atualizar_status_encomenda();

-- 5. VIEW

CREATE VIEW seek_pack.vw_encomendas AS
SELECT
    e.id,
    e.codigo_rastreio,
    u.nome AS usuario,
    u.email,
    e.origem,
    e.destino,
    e.previsao_entrega,
    e.status
FROM seek_pack.encomendas e
JOIN seek_pack.usuarios u ON u.id = e.usuario_id;

-- 6. INSERÇÕES: 10 USUÁRIOS

INSERT INTO seek_pack.usuarios (nome, email) VALUES ('Ana Silva', 'ana@example.com');
INSERT INTO seek_pack.usuarios (nome, email) VALUES ('Bruno Costa', 'bruno@example.com');
INSERT INTO seek_pack.usuarios (nome, email) VALUES ('Carla Souza', 'carla@example.com');
INSERT INTO seek_pack.usuarios (nome, email) VALUES ('Daniel Santos', 'daniel@example.com');
INSERT INTO seek_pack.usuarios (nome, email) VALUES ('Eduarda Lima', 'eduarda@example.com');
INSERT INTO seek_pack.usuarios (nome, email) VALUES ('Felipe Alves', 'felipe@example.com');
INSERT INTO seek_pack.usuarios (nome, email) VALUES ('Gabriela Rocha', 'gabriela@example.com');
INSERT INTO seek_pack.usuarios (nome, email) VALUES ('Henrique Dias', 'henrique@example.com');
INSERT INTO seek_pack.usuarios (nome, email) VALUES ('Isabela Martins', 'isabela@example.com');
INSERT INTO seek_pack.usuarios (nome, email) VALUES ('João Oliveira', 'joao@example.com');

-- 7. INSERÇÕES: 10 ENCOMENDAS
-- Os IDs dos usuários correspondem à ordem das inserções acima.

INSERT INTO seek_pack.encomendas (usuario_id, codigo_rastreio, origem, destino, previsao_entrega)
VALUES (1, 'SP000000001BR', 'Florianópolis/SC', 'Porto Alegre/RS', '2026-12-01');

INSERT INTO seek_pack.encomendas (usuario_id, codigo_rastreio, origem, destino, previsao_entrega)
VALUES (2, 'SP000000002BR', 'Curitiba/PR', 'Mondaí/SC', '2026-12-02');

INSERT INTO seek_pack.encomendas (usuario_id, codigo_rastreio, origem, destino, previsao_entrega)
VALUES (3, 'SP000000003BR', 'Goiânia/GO', 'Brasília/DF', '2026-12-03');

INSERT INTO seek_pack.encomendas (usuario_id, codigo_rastreio, origem, destino, previsao_entrega)
VALUES (4, 'SP000000004BR', 'São Paulo/SP', 'Rio de Janeiro/RJ', '2026-12-04');

INSERT INTO seek_pack.encomendas (usuario_id, codigo_rastreio, origem, destino, previsao_entrega)
VALUES (5, 'SP000000005BR', 'Belo Horizonte/MG', 'Vitória/ES', '2026-12-05');

INSERT INTO seek_pack.encomendas (usuario_id, codigo_rastreio, origem, destino, previsao_entrega)
VALUES (6, 'SP000000006BR', 'Salvador/BA', 'Recife/PE', '2026-12-06');

INSERT INTO seek_pack.encomendas (usuario_id, codigo_rastreio, origem, destino, previsao_entrega)
VALUES (7, 'SP000000007BR', 'Fortaleza/CE', 'Natal/RN', '2026-12-07');

INSERT INTO seek_pack.encomendas (usuario_id, codigo_rastreio, origem, destino, previsao_entrega)
VALUES (8, 'SP000000008BR', 'Manaus/AM', 'Belém/PA', '2026-12-08');

INSERT INTO seek_pack.encomendas (usuario_id, codigo_rastreio, origem, destino, previsao_entrega)
VALUES (9, 'SP000000009BR', 'Campinas/SP', 'Curitiba/PR', '2026-12-09');

INSERT INTO seek_pack.encomendas (usuario_id, codigo_rastreio, origem, destino, previsao_entrega)
VALUES (10, 'SP000000010BR', 'Joinville/SC', 'Chapecó/SC', '2026-12-10');

-- 8. INSERÇÕES: 10 EVENTOS DE RASTREAMENTO
-- O trigger atualiza o status de cada encomenda.

INSERT INTO seek_pack.eventos_rastreamento (encomenda_id, status, descricao, localizacao)
VALUES (1, 'POSTADO', 'Encomenda postada.', 'Florianópolis/SC');

INSERT INTO seek_pack.eventos_rastreamento (encomenda_id, status, descricao, localizacao)
VALUES (2, 'EM_TRANSITO', 'Encomenda em transporte.', 'Curitiba/PR');

INSERT INTO seek_pack.eventos_rastreamento (encomenda_id, status, descricao, localizacao)
VALUES (3, 'ENTREGUE', 'Encomenda entregue.', 'Brasília/DF');

INSERT INTO seek_pack.eventos_rastreamento (encomenda_id, status, descricao, localizacao)
VALUES (4, 'POSTADO', 'Encomenda postada.', 'São Paulo/SP');

INSERT INTO seek_pack.eventos_rastreamento (encomenda_id, status, descricao, localizacao)
VALUES (5, 'EM_TRANSITO', 'Encomenda em transporte.', 'Belo Horizonte/MG');

INSERT INTO seek_pack.eventos_rastreamento (encomenda_id, status, descricao, localizacao)
VALUES (6, 'AGUARDANDO_RETIRADA', 'Disponível para retirada.', 'Recife/PE');

INSERT INTO seek_pack.eventos_rastreamento (encomenda_id, status, descricao, localizacao)
VALUES (7, 'POSTADO', 'Encomenda postada.', 'Fortaleza/CE');

INSERT INTO seek_pack.eventos_rastreamento (encomenda_id, status, descricao, localizacao)
VALUES (8, 'EM_TRANSITO', 'Encomenda em transporte.', 'Manaus/AM');

INSERT INTO seek_pack.eventos_rastreamento (encomenda_id, status, descricao, localizacao)
VALUES (9, 'ENTREGUE', 'Encomenda entregue.', 'Curitiba/PR');

INSERT INTO seek_pack.eventos_rastreamento (encomenda_id, status, descricao, localizacao)
VALUES (10, 'AGUARDANDO_RETIRADA', 'Disponível para retirada.', 'Chapecó/SC');

-- 9. PAPÉIS DE ACESSO
-- São papéis sem login, que podem ser concedidos a usuários do banco.

CREATE ROLE seek_pack_leitura NOLOGIN;
CREATE ROLE seek_pack_operador NOLOGIN;

GRANT USAGE ON SCHEMA seek_pack TO seek_pack_leitura, seek_pack_operador;

GRANT SELECT ON
    seek_pack.usuarios,
    seek_pack.encomendas,
    seek_pack.eventos_rastreamento,
    seek_pack.vw_encomendas
TO seek_pack_leitura;

GRANT SELECT, INSERT, UPDATE ON
    seek_pack.usuarios,
    seek_pack.encomendas
TO seek_pack_operador;

-- Eventos são apenas inseridos e consultados, preservando o histórico.
GRANT SELECT, INSERT ON seek_pack.eventos_rastreamento TO seek_pack_operador;
GRANT SELECT ON seek_pack.vw_encomendas TO seek_pack_operador;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA seek_pack TO seek_pack_operador;

-- Consulta de exemplo:
SELECT * FROM seek_pack.vw_encomendas ORDER BY id;
