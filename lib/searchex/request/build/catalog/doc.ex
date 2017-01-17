defmodule Searchex.Request.Build.Catalog.Doc do

  @moduledoc false

  defstruct docid:      ""   ,
            catid:      0    ,
            fileid:     0    ,
            filename:   ""   ,
            startline:  0    ,
            startbyte:  0    ,
            doclength:  0    ,
            wordcount:  0    ,
            wordstems:  []   ,
            fields:     %{}  , 
            body:       ""   ,
            score:      0

  alias Searchex.Request.Build.Catalog.Doc

  def generate_from_catalog(catalog, params) do
    catalog.bucketscans
    |> extract_docs
    |> extract_fields(params.input_fields)
  end

  defp extract_docs(bucketscans) do
    bucketscans
    |> Task.async_stream(__MODULE__, :gen_docs, [], timeout: 600_000) # ten minutes...
    |> Enum.to_list
    |> Enum.map(fn(el) -> elem(el, 1) end)
    |> List.flatten
  end

  def gen_docs(bucketscan) do
    pairs     = bucketscan.docsep_locations
    inputs    = pairs |> Enum.with_index(1)
    Enum.reduce(inputs, [], fn(pair, acc) -> acc ++ [gen_doc(pair, bucketscan)] end)
    |> Enum.reduce({[], 0}, fn(doc, acc) -> setline(doc, acc) end )
    |> elem(0)
  end

  defp setline(doc, {doclist, count}) do
    newcount = count + countlines(doc.body)
    newdoc   = %Doc{doc | startline: newcount}
    {doclist ++ [newdoc], newcount}
  end

  defp countlines(string) do
    Regex.scan(~r/\n/, string) |> Enum.count
  end

  defp gen_doc({{position, offset}, idx}, bucketscan) do
    body = String.slice(bucketscan.rawdata, position, offset)
    %Doc{
      docid:     Util.Ext.Term.digest(body)      ,
      fileid:    idx                             ,
      filename:  bucketscan.bucket_id            ,
      startbyte: position                        ,
      doclength: offset                          ,
      wordcount: Util.Ext.String.wordcount(body) ,
      wordstems: Util.Ext.String.wordstems(body) ,
      body:      body
    }
  end

  defp extract_fields(docs, input_fields) do
    docs
    |> Enum.reduce({[], %{}}, fn(doc, acc) -> get_fields(doc, acc, input_fields) end)
    |> elem(0)
  end

  defp get_fields(doc, {doclist, old_fields}, input_fields) do
    alt_input_fields = input_fields || []
    reg_fields = Enum.map alt_input_fields, fn({field_name, _field_spec}) ->
      {field_name, reg_field(input_fields, doc, field_name)}
    end
    new_fields = Map.merge(old_fields, Enum.into(reg_fields, %{}))
    new_doc    = %Doc{doc | fields: new_fields}
    {doclist ++ [new_doc], new_fields}
  end

  defp reg_field(input_fields, doc, field_name) do
    regstr  = input_fields[field_name].regex
    if caps = Regex.named_captures(~r/#{regstr}/, doc.body) do
      [head | _tail] = Map.values caps
      head
    else
       nil
    end
  end
end
