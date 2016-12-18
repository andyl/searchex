defmodule SearchexOldTest do
  use ExUnit.Case, async: true

    describe "#version" do
      test "execution" do
        assert SearchexOld.version != nil
      end

      test ":ok return value" do
        {status, _msg} = SearchexOld.version()
        assert  status == :ok
      end
    end

    describe "#settings" do
      test "map values" do
        assert SearchexOld.settings.cfgs != nil
        assert SearchexOld.settings.docs != nil
        assert SearchexOld.settings.data != nil
      end
    end
end
