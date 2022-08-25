defmodule Webhoox.Adapter.ParsioTest do
  use ExUnit.Case
  use Plug.Test

  alias Webhoox.Adapter
  alias Webhoox.Data.Parsio

  # Parsio Webhook: https://help.parsio.io/data-export-integrations/send-data-to-webhook-1
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

  defp setup_webhook(parsio_params) do
    conn(:post, "/_incoming", parsio_params)
  end

  describe "Doc" do
    test "webhook" do
      conn = setup_webhook(@parsio_params)

      {:ok, _conn, %Parsio{} = resp} = Adapter.Parsio.handle_webhook(conn, TestProcessor)

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
