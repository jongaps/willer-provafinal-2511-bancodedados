create table jogadores(
	id serial primary key,
	nickname varchar(100) not null,
	email varchar(200) not null,
	senha varchar(100) not null,
	status varchar(100) default 'Ativo' check(status in('Ativo', 'Inativo', 'Banido'))
);
create table categorias_partidas(
	id serial primary key,
	nome_jogo varchar(100) not null,
	genero varchar(100) not null
);
create table partidas(
	id serial primary key,
	jogador_id int references jogadores(id),
	categoria_partida_id int references categorias_partidas(id),
	titulo_partida varchar(100) not null,
	data_agendada_partida date not null,
	data_criacao_partida date,
	status_disputa varchar(100) default 'Não Iniciada' check(status_disputa in('Não Iniciada', 'Encerrada', 'Agendada'))
);
create table historico_partidas(
	id serial primary key,
	jogador_id int references jogadores(id),
	partida_id int references partidas(id),
	descricao varchar(500) not null,
	registro_data timestamp default current_timestamp
);



create or replace function fn_trg_validar_partida()
returns trigger as $$
declare
	status_jogador varchar(100);
begin
	select status into status_jogador
	from jogadores
	where id = new.jogador_id;

	if status_jogador is null then
		raise exception 'Jogador não é válido';
	end if;

	if status_jogador <> 'Ativo' then
		raise exception 'O jogador encontra-se %', status_jogador;
	end if;

	new.data_criacao_partida := current_timestamp;

	return new;
end;
$$ language plpgsql;

create trigger trg_validar_partida
before insert on partidas
for each row
execute function fn_trg_validar_partida();


create or replace function fn_log_historico_de_partidas()
returns trigger as $$
begin
	insert into historico_partidas (partida_id, descricao) values
	(1, 'Partida foi marcada');

	return new;
end;
$$ language plpgsql;

create trigger trg_registrar_partida
after insert on partidas
for each row
execute function fn_log_historico_de_partidas();


INSERT INTO jogadores (nickname, email, senha, status) VALUES
('FalleN', 'fallen@cs.com.br', '123456', 'Ativo'),
('Aspas', 'aspas@valorant.com.br', 'senha123', 'Ativo'),
('Nobru', 'nobru@ff.com.br', 'capa999', 'Ativo'),
('Troller_BR', 'troller@ban.com', '000000', 'Banido');

INSERT INTO categorias_partidas (nome_jogo, genero) VALUES
('Counter-Strike 2', 'FPS'),
('Valorant', 'FPS Tático'),
('League of Legends', 'MOBA');

INSERT INTO partidas (jogador_id, categoria_partida_id, titulo_partida, data_agendada_partida, status_disputa) VALUES
(1, 1, 'FURIA vs MIBR', CURRENT_DATE + 7, 'Agendada'),
(2, 2, 'LOUD vs Sentinels', CURRENT_DATE + 2, 'Agendada'),
(3, 3, 'paiN Gaming vs Kabum', CURRENT_DATE + 15, 'Não Iniciada');


create view vw_painel_principal as
select
	j.nickname,
	p.titulo_partida,
	cp.genero,
	p.data_agendada_partida,
	p.status_disputa
from
	partidas p
join
	jogadores j on j.id = p.jogador_id
join
	categorias_partidas cp on cp.id = p.categoria_partida_id


create or replace function fn_buscar_jogadores(termo_pesq varchar)
returns table(
	id int,
	nickname varchar,
	email varchar,
	status varchar
)
as
$$
begin
	return query
select
	j.id,
	j.nickname,
	j.email,
	j.status
from
	jogadores j
where
	j.nickname ilike '%' || termo_pesq || '%';
end;
$$ language plpgsql;


create view vw_cronograma_partidas as
select 
    p.titulo_partida,
    p.data_agendada_partida,
    p.status_disputa,
    p.data_agendada_partida - current_date as dias_restantes,
    j.nickname as jogador_responsavel
from
	partidas p
join
	jogadores j on p.jogador_id = j.id
order by
	p.data_agendada_partida asc;
