defmodule Paperform2webWeb.ErrorJSONTest do
  use Paperform2webWeb.ConnCase, async: true

  test "renders 404" do
    assert Paperform2webWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert Paperform2webWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
