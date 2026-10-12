# Ypy

O kernel do ecossistema Taina. Uma biblioteca, nao uma aplicacao.

Ypy (Tupi: origem) e a base compartilhada sobre a qual os produtos sao
construidos: o box do Taina (a nuvem privada da comunidade), a plataforma
hospedada e os produtos futuros. Ela carrega duas coisas, e so duas:

1. **O schema.** As formas de record e o contrato de fio. E o artefato que os
   clientes (Swift, Kotlin) espelham e que os produtos compartilham, para que
   um produto novo fale o mesmo vocabulario sem redecidir.
2. **O nucleo puro.** Identidade (Maraca), records assinados e endereçados por
   conteudo (Ybira), o modelo social (zonas, papeis, a regra de leitura), o
   mural e a assembleia. Funcoes puras: sem processo, sem banco, sem relogio
   alem do que e passado como argumento.

Tudo que toca o mundo vive em adapters escolhidos pelo produto: persistencia
(SQLite no box da comunidade), transporte e autenticacao, a superficie HTTP, a
federacao. O kernel nunca depende de um produto; um produto depende do kernel.

## Status

As primitivas puras de protocolo ja estao em `lib/`: DAG-CBOR, CID, varint,
base32, base58, secp256k1 e TID. O nucleo de identidade e protocolo esta
entrando conforme o RFC 006; o resto segue a sequencia de build.

## Como consumir

Para o mantenedor de um produto (o box do Taina, a plataforma hospedada),
quatro passos, na ordem (RFC_006 secoes 6, 7 e 10):

1. **A dependencia.** No `mix.exs` do produto: `{:ypy, "~> 0.1"}`. O Ypy nao
   importa nada de produto, nao le config de produto e nao nomeia modulo de
   produto.
2. **As migracoes.** `mix ypy.install` copia as migracoes do kernel para
   `priv/repo/migrations` do produto, com a versao preservada
   (`--migrations-path` troca o caminho). Rodar de novo substitui a versao,
   nunca duplica. Quem roda as migracoes e o `mix ecto.migrate` do produto.
3. **Os lexicons no boot.** O produto carrega o indice uma vez, com o
   diretorio do kernel primeiro e o dele depois (um lexicon do produto
   sobrescreve um do kernel de mesmo id):

   ```elixir
   {entries, problems} =
     Ypy.Lexicon.Registry.load([
       Application.app_dir(:ypy, "priv/lexicons"),
       "priv/lexicons"
     ])
   ```

4. **O Repo e do produto.** O kernel nao define `Ypy.Repo` nem le config
   global: toda funcao de contexto recebe o repo como primeiro argumento. Os
   adapters de blob e de chave o produto escolhe (`Ypy.BlobStore.Disk` e
   `Ypy.KeyStore.Files` sao os do kernel):

   ```elixir
   Ypy.Ybira.upload(Taina.Repo, keys, blobs, scope, tmp_path, mime: mime)
   ```

## Relacao com o Pesque

`zeetech/pesque` e um Personal Data Server para ATProto, tambem em Elixir. O
Ypy reusa as **primitivas puras de protocolo** dele (DAG-CBOR, CID, a Merkle
Search Tree, TID, CAR, varint, base32, base58, secp256k1, as formas de record e
commit) sob a licenca WTFPL do Pesque. O Ypy NAO adota a semantica global-ATProto
do Pesque (o diretorio PLC, o servidor OAuth, o crawl de relay, o firehose, o
entryway): o kernel do Taina e community-first, `did:web`-first e praca-only, e
a federacao entre Tekoas e um assunto posterior.

## Licenca

MPL-2.0 (Mozilla Public License 2.0). Copyleft por arquivo: mudancas nos
arquivos do proprio Ypy ficam abertas, e um produto, inclusive proprietario
como a plataforma hospedada, pode depender do Ypy e manter os proprios arquivos
fechados. E por isso MPL e nao AGPL: o kernel e dependencia de codigo dos
produtos, e um deles pode ser proprietario.

Arquivos derivados do Pesque carregam a proveniencia WTFPL dele e sao
relicenciados aqui sob MPL-2.0, o que o WTFPL permite. Ver "Relacao com o
Pesque".
