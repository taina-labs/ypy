# Ypy

The kernel of the Taina ecosystem. A library, not an application.

Ypy (Tupi: origin) is the shared base that the products are built on: the Taina
box (the community's private cloud), the hosted platform, and future products.
It carries two things and only two things:

1. **The schema.** The shapes of records and the wire contract. This is the
   artifact that clients (Swift, Kotlin) mirror and that products share, so a
   new product speaks the same vocabulary without re-deciding it.
2. **The pure core.** Identity (Maraca), signed content-addressed records
   (Ybira), the social model (zones, roles, the read rule), the mural and the
   assembly. Pure functions: no process, no database, no clock beyond what is
   passed in.

Everything that touches the world lives in adapters chosen by the product:
persistence (SQLite on a community box, Postgres on the hosted profile),
transport and auth, the HTTP surface, federation. The kernel never depends on a
product; a product depends on the kernel.

## Status

Design phase. The boundary, the module layout and the license are decided in
RFC 006 (to land in `taina-labs/tekoa`). This repository is a shell until that
lands. No `lib/` tree yet, on purpose: the contract comes first.

## Relationship to Pesque

`zeetech/pesque` is a Personal Data Server for ATProto, also in Elixir. Ypy
reuses its **pure protocol primitives** (DAG-CBOR, CID, the Merkle Search Tree,
TID, CAR, varint, base32, base58, secp256k1, the record and commit shapes) under
its WTFPL license. Ypy does NOT take Pesque's global-ATProto semantics (the PLC
directory, the OAuth server, the relay crawl, the firehose, the entryway): the
Taina kernel is a community-first, `did:web`-first, praça-only shape, and
federation between Tekoas is a later concern.

## License

MPL-2.0 (Mozilla Public License 2.0). File-level copyleft: changes to Ypy's own
files stay open, and a product, including a proprietary one like the hosted
platform, can depend on Ypy and keep its own files closed. That is why MPL over
AGPL: the kernel is a code dependency of products, and one of them may be
proprietary.

Files derived from Pesque carry its WTFPL provenance and are relicensed here
under MPL-2.0, which WTFPL permits. See "Relationship to Pesque".
