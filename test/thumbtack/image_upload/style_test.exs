defmodule Thumbtack.ImageUpload.StyleTest do
  alias Thumbtack.ImageUpload.Uploader
  alias Thumbtack.ImageUpload.Style

  alias Vix.Vips

  use Thumbtack.TestCase

  describe "apply_transformations(style_state, transformations, uploader)" do
    test "applies transformations" do
      uploader = Uploader.new(src_path: "test/fixtures/photo-small.jpg")

      transformations = [:square, {:resize, 256}]

      style_state = Style.new()

      assert %Style{image: image} =
               Style.apply_transformations(style_state, transformations, uploader)

      assert 128 == Vips.Image.height(image)
      assert 128 == Vips.Image.width(image)
    end

    test "returns error if one of transformations fail" do
      uploader = Uploader.new(src_path: "test/fixtures/photo-unknown.jpg")

      transformations = [:square, {:resize, 256}]

      style_state = Style.new()

      assert {:error, _reason} =
               Style.apply_transformations(style_state, transformations, uploader)
    end
  end

  describe "save(style_state)" do
    test "saves style image to temporary file" do
      style_state = Style.new(image: load_image_fixture("photo-square.heic"))

      assert %Style{path: path} = Style.save(style_state)
      assert File.exists?(path)
    end

    test "saves in jpeg format" do
      style_state = Style.new(image: load_image_fixture("photo-square.heic"))

      %Style{path: path} = Style.save(style_state)

      assert String.ends_with?(path, ".jpg")
      assert {:ok, {%Vips.Image{}, _flags}} = Vips.Operation.jpegload(path)
    end
  end
end
