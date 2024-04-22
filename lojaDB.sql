CREATE TABLE usuario(
	idUsuario INT IDENTITY(1,1) PRIMARY KEY,
	login VARCHAR(100),
	senha VARCHAR(30)
);

CREATE SEQUENCE idPessoa START WITH 1 INCREMENT BY 1;

CREATE TABLE pessoa(
	idPessoa INT PRIMARY KEY DEFAULT NEXT VALUE FOR idPessoa,
	nome VARCHAR(255),
	logradouro VARCHAR(255),
	cidade VARCHAR(255),
	estado VARCHAR(2),
	telefone VARCHAR(255),
	email VARCHAR(255)
);

CREATE TABLE pessoaFisica(
	idPessoa INT NOT NULL,
	cpf VARCHAR(11) NOT NULL,
	FOREIGN KEY (idPessoa) REFERENCES pessoa(idPessoa)
);

CREATE TABLE pessoaJuridica(
	idPessoa INT NOT NULL,
	cnpj VARCHAR(14) NOT NULL,
	FOREIGN KEY (idPessoa) REFERENCES pessoa(idPessoa)
);

CREATE TABLE produto(
	idProduto INT PRIMARY KEY NOT NULL,
	nome VARCHAR(255),
	quantidade INT,
	precoVenda DECIMAL(10, 2)
);

CREATE TABLE movimento(
	idMovimento INT IDENTITY(1,1) PRIMARY KEY,
	idUsuario INT NOT NULL,
	idPessoa INT NOT NULL,
	idProduto INT NOT NULL,
	quantidade INT,
	tipo VARCHAR(1),
	valorUnitario DECIMAL(10,2),
	FOREIGN KEY (idUsuario) REFERENCES usuario(idUsuario),
	FOREIGN KEY (idPessoa) REFERENCES pessoa(idPessoa),
	FOREIGN KEY (idProduto) REFERENCES produto(idProduto),
	CONSTRAINT TIPO_MOVIMENTO_INVALIDO CHECK (tipo IN ('E', 'S'))
);

-- CRIAÇÃO DOS USUÁRIOS
INSERT INTO usuario (login, senha) VALUES ('op1', 'op1');
INSERT INTO usuario (login, senha) VALUES ('op2', 'op2');

SELECT * FROM usuario;


-- CRIAÇÃO DOS PRODUTOS
INSERT INTO produto (idProduto, nome, quantidade, precoVenda) VALUES (1, 'Banana', 100, 5.00);
INSERT INTO produto (idProduto, nome, quantidade, precoVenda) VALUES (3, 'Laranja', 500, 2.00);
INSERT INTO produto (idProduto, nome, quantidade, precoVenda) VALUES (4, 'Manga', 100, 4.00);

SELECT * FROM produto;

-- CRIAÇÃO DE PESSOA FISICA
DECLARE @PFId INT;
SET @PFId = NEXT VALUE FOR idPessoa;

INSERT INTO pessoa (idPessoa, nome, logradouro, cidade, estado, telefone, email)
VALUES (@PFId, 'Joao', 'Rua 12, casa 3, Quitanda', 'Riacho do Sul', 'PA', '1111-1111', 'joao@riacho.com');

INSERT INTO pessoaFisica (idPessoa, cpf) VALUES (@PFId, '11111111111');

SELECT * FROM pessoa AS p INNER JOIN pessoaFisica AS pf ON p.idPessoa = pf.idPessoa;

-- CRIAÇÃO DE PESSOA JURÍDICA
DECLARE @PJId INT;
SET @PJId = NEXT VALUE FOR idPessoa;

INSERT INTO pessoa (idPessoa, nome, logradouro, cidade, estado, telefone, email)
VALUES (@PJId, 'JJC', 'Rua 11. Centro', 'Riacho do Norte', 'PA', '1212-1212', 'jjc@riacho.com');

INSERT INTO pessoaJuridica (idPessoa, cnpj) VALUES (@PJId, '22222222222222');

SELECT * FROM pessoa AS p INNER JOIN pessoaJuridica AS pj ON p.idPessoa = pj.idPessoa;

-- CRIAÇÃO DA MOVIMENTAÇÃO
INSERT INTO movimento (idUsuario, idPessoa, idProduto, quantidade, tipo, valorUnitario) VALUES 
	(1, @PFId, 1, 20, 'S', 4.00),
	(1, @PFId, 3, 15, 'S', 2.00),
	(2, @PFId, 3, 10, 'S', 3.00),
	(1, @PJId, 3, 15, 'E', 5.00),
	(1, @PJId, 4, 20, 'E', 4.00);

SELECT * FROM movimento;

-- DADOS COMPLETOS PESSOAS FÍSICAS
SELECT * FROM pessoa AS p INNER JOIN pessoaFisica AS pf ON p.idPessoa = pf.idPessoa;

-- DADOS COMPELTOS PESSOAS JURÍDICAS
SELECT * FROM pessoa AS p INNER JOIN pessoaJuridica AS pj ON p.idPessoa = pj.idPessoa;

-- MOVIMENTAÇÃO DE ENTRADA, COM PRODUTO, FORNECEDOR, QUANTIDADE, PREÇO UNITÁRIO E VALOR TOTAL
SELECT m.idMovimento,
	m.tipo,
	produto.nome AS Produto,
	p.nome as Fornecedor,
	m.quantidade AS Quantidade,
	m.valorUnitario AS 'Preço Unitário',
	m.quantidade * m.valorUnitario AS 'valorTotal'
FROM movimento AS m 
INNER JOIN pessoa AS p ON m.idPessoa = p.idPessoa
INNER JOIN produto ON m.idProduto = produto.idProduto
WHERE m.tipo = 'E';

-- MOVIMENTAÇÃO DE SAÍDA, COM PRODUTO, COMPRADOR, QUANTIDADE, PREÇO UNITÁRIO E VALOR TOTAL
SELECT m.idMovimento,
	m.tipo,
	produto.nome AS Produto,
	p.nome AS Comprador,
	m.quantidade AS Quantidade,
	m.valorUnitario AS 'Preço Unitário',
	m.quantidade * m.valorUnitario AS 'Valor Total'
FROM movimento AS m
INNER JOIN produto ON m.idProduto = produto.idProduto
INNER JOIN pessoa AS p ON m.idPessoa = p.idPessoa
WHERE m.tipo = 'S';

-- VALOR TOTAL DAS ENTRADAS AGRUPADAS POR PRODUTO
SELECT produto.idProduto, produto.nome AS produto,
	SUM(m.quantidade * m.valorUnitario) AS total
FROM movimento AS m
INNER JOIN produto ON m.idProduto = produto.idProduto
WHERE m.tipo = 'E'
GROUP BY produto.nome, produto.idProduto;

-- VALOR TOTAL DAS SAÍDAS AGRUPADAS POR PRODUTO
SELECT produto.idProduto, produto.nome AS produto,
	SUM(m.quantidade * m.valorUnitario) AS total
FROM movimento AS m
INNER JOIN produto ON m.idProduto = produto.idProduto
WHERE m.tipo = 'S'
GROUP BY produto.nome, produto.idProduto;

-- OPERADORES QUE NÃO EFETUARAM MOVIMENTAÇÕES DE ENTRADA (COMPRA)
SELECT u.* FROM usuario AS u
LEFT JOIN movimento AS m ON m.idUsuario = u.idUsuario AND m.tipo = 'E'
WHERE m.idMovimento IS NULL;

-- VALOR TOTAL DE ENTRADA, AGRUPADO POR OPERADOR
SELECT u.idUsuario, u.login AS operador,
	SUM(m.quantidade * m.valorUnitario) AS total
FROM movimento AS m
INNER JOIN usuario as u ON m.idUsuario = u.idUsuario
WHERE m.tipo = 'E'
GROUP BY u.login, u.idUsuario;

-- VALOR TOTAL DE SAÍDA, AGRUPADO POR OPERADOR
SELECT u.idUsuario, u.login AS operador,
	SUM(m.quantidade * m.valorUnitario) AS total
FROM movimento AS m
INNER JOIN usuario as u ON m.idUsuario = u.idUsuario
WHERE m.tipo = 'S'
GROUP BY u.login, u.idUsuario;

-- VALOR MÉDIO DE VENDA POR PRODUTO, UTILIZANDO MÉDIA PONDERADA
SELECT p.idProduto, 
       p.nome AS produto,
       SUM(m.quantidade * m.valorUnitario) / SUM(m.quantidade) AS valorMedio
FROM movimento m
INNER JOIN produto p ON m.idProduto = p.idProduto
WHERE m.tipo = 'S'
GROUP BY p.idProduto, p.nome;