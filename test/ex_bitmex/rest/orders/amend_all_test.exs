defmodule ExBitmex.Rest.Orders.AmendAllTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    HTTPoison.start()
    :ok
  end

  @credentials %ExBitmex.Credentials{
    api_key: System.get_env("BITMEX_API_KEY"),
    api_secret: System.get_env("BITMEX_SECRET")
  }

  test ".amend_all returns the order response" do
    use_cassette "rest/orders/amend_all_ok" do
      assert {:ok, order_1, _} =
               ExBitmex.Rest.Orders.create(
                 @credentials,
                 %{
                   symbol: "XBTUSD",
                   side: "Buy",
                   orderQty: 1,
                   price: 100
                 }
               )

      assert {:ok, order_2, _} =
               ExBitmex.Rest.Orders.create(
                 @credentials,
                 %{
                   symbol: "XBTUSD",
                   side: "Buy",
                   orderQty: 1,
                   price: 105
                 }
               )

      assert {:ok, amended_orders, _} =
               ExBitmex.Rest.Orders.amend_all(
                 @credentials,
                 %{
                   orderID: order_1.order_id,
                   price: 100.5,
                   leavesQty: 2
                 },
                 %{
                   orderID: order_2.order_id,
                   price: 105.5,
                   leavesQty: 3
                 }
               )

      assert [%ExBitmex.Order{} = amended_order_1, %ExBitmex.Order{} = amended_order_2] =
               amended_orders

      assert amended_order_1.price == 100.5
      assert amended_order_1.leaves_qty == 2
      assert amended_order_2.price == 105.5
      assert amended_order_2.leaves_qty == 3
    end
  end

  # test ".amend returns an error tuple when there is a timeout" do
  #   use_cassette "rest/orders/amend_timeout" do
  #     assert {:error, :timeout, nil} =
  #              ExBitmex.Rest.Orders.amend(
  #                @credentials,
  #                %{
  #                  orderID: "8d6f2649-7477-4db5-e32a-d8d5bf99dd9b",
  #                  leavesQty: 3
  #                }
  #              )
  #   end
  # end
end
