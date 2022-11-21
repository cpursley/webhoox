defmodule Webhoox.Adapter.ParsioTest do
  use ExUnit.Case

  alias Webhoox.Adapter
  alias Webhoox.Data.Parsio

  @signature "751a9f2aa47aafff214cf2320ff8bfaa2d31ab939b9bbc364a6c3339b43b8db1"
  @signing_secret "signing_secret"

  @parsio_params %{
    "doc_id" => "730650df7ff9cax011f312c5",
    "event" => "doc.parsed",
    "mailbox_id" => "3306422e7ff9za0011f4f2b0",
    "payload" => %{
      "filename" => "some_filename.eml",
      "parsed" => %{"some_key" => "some_value"},
      "template_id" => "33064a347ff9za0011f30375"
    }
  }

  describe "Doc Parsed webhook" do
    test "processes valid webhook" do
      conn = TestHelper.setup_webhook(@parsio_params, @signature, "parsio-signature")

      {:ok, _conn, %Parsio{} = resp} =
        Adapter.Parsio.handle_webhook(conn, TestProcessor, signing_secret: @signing_secret)

      assert_receive {:webhook, %Parsio{}}

      assert resp == %Parsio{
               event: @parsio_params["event"],
               mailbox_id: @parsio_params["mailbox_id"],
               doc_id: @parsio_params["doc_id"],
               filename: @parsio_params["payload"]["filename"],
               template_id: @parsio_params["payload"]["template_id"],
               parsed: @parsio_params["payload"]["parsed"]
             }
    end

    test "normalizes data" do
      assert %Parsio{
               event: @parsio_params["event"],
               mailbox_id: @parsio_params["mailbox_id"],
               doc_id: @parsio_params["doc_id"],
               filename: @parsio_params["payload"]["filename"],
               template_id: @parsio_params["payload"]["template_id"],
               parsed: @parsio_params["payload"]["parsed"]
             } == Adapter.Parsio.normalize_params(@parsio_params)
    end
  end
end
