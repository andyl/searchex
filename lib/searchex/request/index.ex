defmodule Searchex.Request.Index do

  @moduledoc false

  use Shreq.Module
  alias Searchex.Request.Build.Index

  @doc """
  The API for the module - takes a config name and returns
  a frame with Params, Catalog and Index filled.
  """
  def exec(cfg_snip) do
    call(%Frame{cfg_snip: cfg_snip}, [])
  end

  step Searchex.Request.Catalog
  step :generate_index

  def generate_index(frame, _opts) do
    child_digest = "idx_#{frame.cfg_name}_" <> Frame.get_digest(frame, :params)
    if map = Util.Cache.get_cache(frame, child_digest) do
      Index.map_to_otp(map, child_digest)
    else
      Index.create_from_frame(frame, child_digest)
      Util.Cache.put_cache(frame, child_digest, Index.otp_to_map(child_digest))
    end
    %Frame{frame | index: Util.Ext.String.to_atom(child_digest)}
  end
end
