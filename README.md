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
