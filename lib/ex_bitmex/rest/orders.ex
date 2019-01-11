defmodule ExBitmex.Rest.Orders do
  alias ExBitmex.Rest

  @type credentials :: ExBitmex.Credentials.t()
  @type order :: ExBitmex.Order.t()
  @type rate_limit :: ExBitmex.RateLimit.t()
  @type auth_error_reason :: Rest.HTTPClient.auth_error_reason()
  @type params :: map
  @type error_msg :: String.t()
  @type shared_error_reason :: :timeout | auth_error_reason
  @type insufficient_balance_error_reason :: {:insufficient_balance, error_msg}
  @type nonce_not_increasing_error_reason :: {:nonce_not_increasing, error_msg}

  @type create_error_reason ::
          shared_error_reason
          | insufficient_balance_error_reason
          | nonce_not_increasing_error_reason

  @spec create(credentials, params) ::
          {:ok, order, rate_limit} | {:error, create_error_reason, rate_limit | nil}
  def create(%ExBitmex.Credentials{} = credentials, params) when is_map(params) do
    "/order"
    |> Rest.HTTPClient.auth_post(credentials, params)
    |> parse_response
  end

  @type amend_error_reason :: shared_error_reason | insufficient_balance_error_reason

  @spec amend(credentials, params) ::
          {:ok, order, rate_limit} | {:error, amend_error_reason, rate_limit | nil}
  def amend(%ExBitmex.Credentials{} = credentials, params) when is_map(params) do
    "/order"
    |> Rest.HTTPClient.auth_put(credentials, params)
    |> parse_response
  end

  @type cancel_error_reason :: shared_error_reason

  @spec cancel(credentials, params) ::
          {:ok, [order], rate_limit} | {:error, cancel_error_reason, rate_limit | nil}
  def cancel(%ExBitmex.Credentials{} = credentials, params) when is_map(params) do
    "/order"
    |> Rest.HTTPClient.auth_delete(credentials, params)
    |> parse_response
  end

  defp parse_response({:ok, data, rate_limit}) when is_list(data) do
    orders =
      data
      |> Enum.map(&to_struct/1)
      |> Enum.map(fn {:ok, o} -> o end)

    {:ok, orders, rate_limit}
  end

  defp parse_response({:ok, data, rate_limit}) when is_map(data) do
    {:ok, order} = data |> to_struct
    {:ok, order, rate_limit}
  end

  defp parse_response(
         {:error,
          {
            :bad_request,
            %{
              "error" => %{
                "message" => "Account has insufficient Available Balance" <> _ = msg,
                "name" => "ValidationError"
              }
            }
          }, rate_limit}
       ) do
    {:error, {:insufficient_balance, msg}, rate_limit}
  end

  defp parse_response(
         {:error,
          {
            :bad_request,
            %{
              "error" => %{
                "message" => "Nonce is not increasing. This nonce:" <> _ = msg,
                "name" => "HTTPError"
              }
            }
          }, rate_limit}
       ) do
    {:error, {:nonce_not_increasing, msg}, rate_limit}
  end

  defp parse_response({:error, _, _} = error), do: error

  defp to_struct(data) do
    data
    |> Mapail.map_to_struct(
      ExBitmex.Order,
      transformations: [:snake_case]
    )
  end
end
