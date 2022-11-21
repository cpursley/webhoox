defmodule Webhoox.Authentication do
  @moduledoc false
  import Plug.Conn

  def valid_signature?(conn, signing_secret, header) do
    [signature] = get_req_header(conn, header)
    body = conn.assigns[:raw_body]

    :crypto.mac(:hmac, :sha256, signing_secret, body)
    |> Base.encode16(case: :lower)
    |> Plug.Crypto.secure_compare(signature)
  end
end
