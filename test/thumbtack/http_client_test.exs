defmodule Thumbtack.HttpClientTest do
  # see test/support/fake_httpc.ex
  use Thumbtack.TestCase

  alias Thumbtack.HttpClient
  alias Vix.Vips

  describe "download(url)" do
    test "downloads url to temp file" do
      assert {:ok, path} = HttpClient.download("https://example.com/photo-small.jpg")
      assert {:ok, %Vips.Image{}} = Vips.Image.new_from_file(path)
    end

    test "returns 404 not found" do
      assert {:error, 404} = HttpClient.download("https://example.com/photo-unknown.jpg")
    end

    test "returns error on bad url" do
      assert {:error, _reason} = HttpClient.download("https://example.com")
    end
  end
end
