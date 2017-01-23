 defmodule Searchex.Adapter.Type.Filesys do

   alias Shreq.Frame
   alias Util.TimeStamp

  def init(_args) do
    Util.Ext.IO.tins("INIT FILESYS", color: "RED")
  end

  def default_settings do
    %{
      type:         "Filesys"                 ,
      module:       __MODULE__                ,
      filesys_roots:   []                        ,
      filesys_types:   ~w(txt md js exs ex)      ,
      filesys_maxnum:  100                       ,
      filesys_maxkb:   200                       ,
      filesys_depth:   2                         ,
      filesys_skips:   ~w(^\\..+ ^\_ deps docs)
      }
  end

  def cursor(%Frame{cfg_name: cfg_name} = frame) do
    term   = Util.Adapter.event_ids(frame, :create)
             |> Enum.map(fn(file) -> TimeStamp.filepath_timestamp(file) end)
             |> TimeStamp.newest
    digest = Util.Ext.Term.digest({cfg_name, term})
    {:digest, digest}
  end

  def events(frame) do
    list = frame
           |> file_list
           |> Util.Ext.File.ls_r(frame.params.adapter)
           |> Enum.map(fn(elem) -> {:create, elem} end)
    [{:files, list}]
  end

  def rawdata(filename, frame) do
    maxkb = frame.params.adapter.filesys_maxkb
    File.stream!(filename, [], maxkb * 1024) |> Enum.at(0)
  end

  def shake(frame, opts) do
    Searchex.Adapter.Shreq.Filesys.call(frame, opts)
  end

  # -----

  defp file_list(frame) do
    alias Searchex.Request.Util.Helpers
    absolute_roots = Helpers.expanded_filesys_roots(frame)
    Util.Ext.File.ls_r absolute_roots, frame.params.adapter
  end
end
