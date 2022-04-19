defmodule Webhoox.Adapter.HasuraTest do
  use ExUnit.Case
  use Plug.Test

  alias Webhoox.Adapter
  alias Webhoox.Data.Hasura

  @api_key "valid-api-key"

  # Hasura Action: https://hasura.io/docs/latest/graphql/core/actions/action-handlers/#http-handler
  @hasura_action_params %{
    "action" => %{"name" => "UserLogin"},
    "input" => %{"password" => "secretpassword", "username" => "jake"},
    "request_query" => "some mutation",
    "session_variables" => %{
      "x-hasura-role" => "user",
      "x-hasura-user-id" => "423"
    }
  }

  # Hasura Event: https://hasura.io/docs/latest/graphql/core/event-triggers/payload.html#json-payload
  @hasura_event_params %{
    "created_at" => "2018-09-05T07:14:21.601701Z",
    "event" => %{
      "data" => %{"new" => %{"id" => "42", "name" => "john doe"}, "old" => nil},
      "op" => "INSERT",
      "session_variables" => %{
        "x-hasura-allowed-roles" => "['user', 'boo', 'admin']",
        "x-hasura-role" => "admin",
        "x-hasura-user-id" => "1"
      }
    },
    "id" => "85558393-c75d-4d2f-9c15-e80591b83894",
    "table" => %{"name" => "users", "schema" => "public"},
    "trigger" => %{"name" => "insert_user_trigger"}
  }

  defp setup_webhook(hasura_params) do
    conn(:post, "/_incoming", hasura_params)
    |> put_req_header("api-key", @api_key)
  end

  describe "Authorization" do
    test "authorized webhook" do
      conn = setup_webhook(@hasura_action_params)

      {:ok, _conn, %Hasura.Action{}} =
        Adapter.Hasura.handle_webhook(conn, TestProcessor, api_key: @api_key)

      assert_receive {:webhook, %Hasura.Action{}}
    end

    test "unauthorized webhook" do
      conn = setup_webhook(@hasura_event_params)

      {:error, _conn, resp} =
        Adapter.Hasura.handle_webhook(conn, TestProcessor, api_key: "incorrect key")

      refute_receive {:webhook, %Hasura.Event{}}
      assert resp == %{body: %{code: "401", message: "Unauthorized"}, code: :unauthorized}
    end
  end

  describe "Action" do
    test "webhook" do
      conn = setup_webhook(@hasura_action_params)

      {:ok, _conn, %Hasura.Action{} = resp} =
        Adapter.Hasura.handle_webhook(conn, TestProcessor, api_key: @api_key)

      assert_receive {:webhook, %Hasura.Action{}}

      assert resp == %Hasura.Action{
               name: @hasura_action_params["action"]["name"],
               input: @hasura_action_params["input"],
               session_variables: @hasura_action_params["session_variables"]
             }
    end

    test "normalizes data" do
      assert %Hasura.Action{
               name: @hasura_action_params["action"]["name"],
               input: @hasura_action_params["input"],
               session_variables: @hasura_action_params["session_variables"]
             } == Adapter.Hasura.normalize_params(@hasura_action_params)
    end
  end

  describe "Event" do
    test "webhook" do
      conn = setup_webhook(@hasura_event_params)

      {:ok, _conn, %Hasura.Event{} = resp} =
        Adapter.Hasura.handle_webhook(conn, TestProcessor, api_key: @api_key)

      assert_receive {:webhook, %Hasura.Event{}}

      assert resp == %Hasura.Event{
               id: @hasura_event_params["id"],
               name: @hasura_event_params["trigger"]["name"],
               table: @hasura_event_params["table"],
               data: @hasura_event_params["event"]["data"],
               operation: @hasura_event_params["event"]["op"],
               session_variables: @hasura_event_params["event"]["session_variables"],
               created_at: @hasura_event_params["created_at"]
             }
    end

    test "normalizes data" do
      assert %Hasura.Event{
               id: @hasura_event_params["id"],
               name: @hasura_event_params["trigger"]["name"],
               table: @hasura_event_params["table"],
               data: @hasura_event_params["event"]["data"],
               operation: @hasura_event_params["event"]["op"],
               session_variables: @hasura_event_params["event"]["session_variables"],
               created_at: @hasura_event_params["created_at"]
             } == Adapter.Hasura.normalize_params(@hasura_event_params)
    end
  end
end
