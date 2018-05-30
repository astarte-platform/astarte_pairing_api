#
# This file is part of Astarte.
#
# Astarte is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Astarte is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Astarte.  If not, see <http://www.gnu.org/licenses/>.
#
# Copyright (C) 2017-2018 Ispirata Srl
#

defmodule Astarte.Pairing.APIWeb.DeviceController do
  use Astarte.Pairing.APIWeb, :controller

  alias Astarte.Pairing.API.Credentials
  alias Astarte.Pairing.API.Credentials.AstarteMQTTV1
  alias Astarte.Pairing.APIWeb.CredentialsView
  alias Astarte.Pairing.APIWeb.CredentialsStatusView

  action_fallback Astarte.Pairing.APIWeb.FallbackController

  def create_credentials(conn, %{
        "realm_name" => realm,
        "hw_id" => hw_id,
        "protocol" => "astarte_mqtt_v1",
        "data" => params
      }) do
    alias AstarteMQTTV1.Credentials, as: AstarteCredentials

    with device_ip <- get_ip(conn),
         {:ok, secret} <- get_secret(conn),
         {:ok, %AstarteCredentials{} = credentials} <-
           Credentials.get_astarte_mqtt_v1(realm, hw_id, secret, device_ip, params) do
      conn
      |> put_status(:created)
      |> render(CredentialsView, "show_astarte_mqtt_v1.json", credentials: credentials)
    end
  end

  def verify_credentials(conn, %{
        "realm_name" => realm,
        "hw_id" => hw_id,
        "protocol" => "astarte_mqtt_v1",
        "data" => params
      }) do
    alias AstarteMQTTV1.CredentialsStatus, as: CredentialsStatus

    with {:ok, secret} <- get_secret(conn),
         {:ok, %CredentialsStatus{} = status} <-
           Credentials.verify_astarte_mqtt_v1(realm, hw_id, secret, params) do
      render(conn, CredentialsStatusView, "show_astarte_mqtt_v1.json", credentials_status: status)
    end
  end

  defp get_secret(conn) do
    case get_req_header(conn, "authorization") do
      ["bearer " <> secret] -> {:ok, secret}
      _ -> {:error, :unauthorized}
    end
  end

  defp get_ip(conn) do
    conn.remote_ip
    |> :inet_parse.ntoa()
    |> to_string()
  end
end
