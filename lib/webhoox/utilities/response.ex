defmodule Webhoox.Utility.Response do
  def unauthorized_request(conn) do
    error_resp = %{
      body: %{message: "Unauthorized", code: "401"},
      code: :unauthorized
    }

    {:error, conn, error_resp}
  end

  def bad_request(conn) do
    error_resp = %{
      body: %{message: "Bad Request", code: "400"},
      code: :bad_request
    }

    {:error, conn, error_resp}
  end
end
