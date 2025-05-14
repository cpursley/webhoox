defmodule Webhoox.Adapter.S3Test do
  use ExUnit.Case
  import Plug.Conn
  import Plug.Test

  alias Webhoox.Adapter
  alias Webhoox.Webhook.S3

  @api_key "valid-api-key"

  @s3_params_1 %{
    "Records" => [
      %{
        "eventName" => "s3:ObjectCreated:Put",
        "s3" => %{
          "object" => %{
            "key" => "myphoto.jpg"
          }
        }
      }
    ]
  }

  @s3_params_2 %{
    "EventName" => "s3:ObjectCreated:Put",
    "Key" => "myphoto.jpg",
    "Records" => [
      %{
        "eventName" => "s3:ObjectCreated:Put",
        "s3" => %{
          "object" => %{
            "key" => "myphoto.jpg"
          }
        }
      }
    ]
  }

  defp setup_webhook(s3_params) do
    conn(:post, "/_incoming", s3_params)
    |> put_req_header("authorization", "Bearer " <> @api_key)
  end

  describe "Authorization" do
    test "authorized webhook" do
      conn = setup_webhook(@s3_params_1)

      {:ok, _conn, %S3{}} = Adapter.S3.handle_webhook(conn, TestProcessor, api_key: @api_key)

      assert_receive {:webhook, %S3{}}
    end

    test "unauthorized webhook" do
      conn = setup_webhook(@s3_params_1)

      {:error, _conn, resp} =
        Adapter.S3.handle_webhook(conn, TestProcessor, api_key: "incorrect key")

      refute_receive {:webhook, %S3{}}
      assert resp == %{body: %{code: "401", message: "Unauthorized"}, code: :unauthorized}
    end
  end

  describe "Just Records" do
    test "webhook" do
      conn = setup_webhook(@s3_params_1)

      {:ok, _conn, %S3{} = resp} =
        Adapter.S3.handle_webhook(conn, TestProcessor, api_key: @api_key)

      assert_receive {:webhook, %S3{}}

      records = @s3_params_1["Records"]
      [record] = records

      assert resp == %S3{
               event: record["eventName"],
               key: record["s3"]["object"]["key"],
               records: records
             }
    end

    test "normalizes data" do
      records = @s3_params_1["Records"]
      [record] = records

      assert %S3{
               event: record["eventName"],
               key: record["s3"]["object"]["key"],
               records: records
             } == Adapter.S3.normalize_params(@s3_params_1)
    end
  end

  describe "EventName, Key and Records" do
    test "webhook" do
      conn = setup_webhook(@s3_params_2)

      {:ok, _conn, %S3{} = resp} =
        Adapter.S3.handle_webhook(conn, TestProcessor, api_key: @api_key)

      assert_receive {:webhook, %S3{}}

      assert resp == %S3{
               event: @s3_params_2["EventName"],
               key: @s3_params_2["Key"],
               records: @s3_params_2["Records"]
             }
    end

    test "normalizes data" do
      assert %S3{
               event: @s3_params_2["EventName"],
               key: @s3_params_2["Key"],
               records: @s3_params_2["Records"]
             } == Adapter.S3.normalize_params(@s3_params_2)
    end
  end
end
