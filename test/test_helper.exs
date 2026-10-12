# O repo de teste mora no processo de boot. A base e SQLite efemera (arquivo
# temporario apagado ao fim): ":memory:" do ecto_sqlite3 nao atravessa
# conexoes (exqlite nao abre com SQLITE_OPEN_URI), e o migrador precisa de
# duas conexoes (trava + migracao). Entao o boot cria e migra com o pool
# comum, para em seguida trocar para o pool do sandbox sobre o mesmo arquivo.
db = Path.join(System.tmp_dir!(), "ypy-test-#{System.unique_integer([:positive])}.sqlite")

{:ok, _} = Ypy.TestRepo.start_link(database: db, pool_size: 2)

migracoes = Path.join(File.cwd!(), "priv/ypy/migrations")
_y_aplicadas = Ecto.Migrator.run(Ypy.TestRepo, migracoes, :up, all: true)

:ok = Ypy.TestRepo.stop()

{:ok, _} =
  Ypy.TestRepo.start_link(
    database: db,
    pool_size: 2,
    pool: Ecto.Adapters.SQL.Sandbox
  )

Ecto.Adapters.SQL.Sandbox.mode(Ypy.TestRepo, :manual)

# O :map do ecto_sqlite3 serializa por uma lib de JSON configuravel; o
# nucleo usa a que vem com o proprio Elixir.
Application.put_env(:ecto_sqlite3, :json_library, JSON)

ExUnit.start()

# Apagar sem fechar: o WAL guarda o que o checkpoint ainda nao despejou. O
# sandbox volta a automatico porque a suite acabou e ninguem tem a conexao.
ExUnit.after_suite(fn _results ->
  Ecto.Adapters.SQL.Sandbox.mode(Ypy.TestRepo, :auto)
  {:ok, _} = Ypy.TestRepo.query("PRAGMA wal_checkpoint(TRUNCATE)")
  :ok = Ypy.TestRepo.stop()
  File.rm(db)
end)
