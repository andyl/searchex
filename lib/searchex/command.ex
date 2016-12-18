defmodule Searchex.Command do
  @moduledoc """
  Main Searchex workflow

  1. Read Configuration
  2. Build Catalog
  3. Build Index
  4. Perform Query

  This workflow establishes a dependency chain, with higher level steps
  depending on the outputs of lower level steps.  Each step generates an
  intermediate output which can be cached to minimize re-execution of
  compute-intensive steps.  The command structure is based on `Shake`.
  """

  alias Util.Cache

  @doc """
  Generate the catalog for `cfg_name`

  The catalog is a Map that contains all configuration data, document text and meta-data.

  The catalog is generated from a config file, stored at `~/.Searchex.Configs/<cfg_name>.yml`.

  The catalog is cached on disk at `~/.searchex/data/<cfg_name>_cat.dat`.
  """
  def catalog(cfg_name) do
    Searchex.Command.Catalog.exec(cfg_name) |> Cache.save(cfg_name)
  end

  @doc """
  Generate the index for `cfg_name`

  The index is a data structure used for fast search and retrieval.

  The index lives in a Process Tree, one worker for each keyword.
  """
  def index(cfg_name) do
    Searchex.Command.Index.exec(cfg_name) |> Cache.save(cfg_name)
  end

  @doc """
  Generate both the catalog and the index for `cfg_name` in one step
  """
  def build(cfg_name) do
    Searchex.Command.Build.exec(cfg_name) |> Cache.save(cfg_name)
  end

  @doc false
  @altdoc """
  Return info about the collection

  - Number of documents
  - Generation date
  - Average size of documents
  - etc.
  """
  def info(cfg_name) do
    Searchex.Command.Info.exec(cfg_name)
  end

  @doc """
  Query the collection
  """
  def query(cfg_name, query) do
    Searchex.Command.Query.exec(cfg_name, query) |> Cache.save(cfg_name)
  end

  @doc """
  Show last results
  """
  def results(cfg_name) do
    Searchex.Command.Results.exec(cfg_name)
  end

  @doc false
  # Show document text
  def show(cfg_name, tgt_id) do
    Searchex.Command.Show.exec(cfg_name, tgt_id)
  end

  @doc false
  @nodoc """
  Removed all cached files.
  """
  def clean do
    File.ls(SearchexOld.settings[:data])
    |> elem(1)
    |> Enum.map(fn(x) -> File.rm!(SearchexOld.settings[:data] <> "/" <> x) end)
    {:ok}
  end

end
