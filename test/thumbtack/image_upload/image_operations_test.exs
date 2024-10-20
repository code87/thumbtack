defmodule Thumbtack.ImageUpload.ImageOperationsTest do
  alias Thumbtack.ImageUpload.ImageOperations
  alias Vix.Vips

  use Thumbtack.TestCase

  describe "errors" do
    test "returns error if file does not exist at path" do
      assert {:error, "" <> _reason} = ImageOperations.square("test/fixtures/photo-unknown.jpg")
      assert {:error, "" <> _reason} = ImageOperations.resize("test/fixtures/photo-unknown.jpg", 128)
    end

    test "returns error if file is in unknown format" do
      assert {:error, "" <> _reason} =
               ImageOperations.thumbnail("test/fixtures/corrupted.jpg", 24)
    end
  end

  describe "square(image_or_path)" do
    test "tall image" do
      image = load_image_fixture("photo-tall.png")

      assert {:ok, transformed} = ImageOperations.square(image)
      assert Vips.Image.width(transformed) == 256
      assert Vips.Image.height(transformed) == 256
    end

    test "wide image" do
      image = load_image_fixture("photo-wide.jpg")

      assert {:ok, transformed} = ImageOperations.square(image)

      assert Vips.Image.width(transformed) == 318
      assert Vips.Image.height(transformed) == 318
    end

    test "does nothing for square image" do
      image = load_image_fixture("photo-square.heic")

      assert {:ok, transformed} = ImageOperations.square(image)
      assert image.ref == transformed.ref
    end

    test "loads image when path is given" do
      assert {:ok, image} = ImageOperations.square("test/fixtures/photo-wide.jpg")
      assert Vips.Image.width(image) == 318
      assert Vips.Image.height(image) == 318
    end
  end

  describe "resize(image_or_path, size: size)" do
    test "width > height" do
      image = load_image_fixture("photo-wide.jpg")

      {:ok, transformed} = ImageOperations.resize(image, 256)

      assert Vips.Image.width(transformed) == 256
      assert Vips.Image.height(transformed) < 256
    end

    test "height > width" do
      image = load_image_fixture("photo-tall.png")

      {:ok, transformed} = ImageOperations.resize(image, 256)

      assert Vips.Image.height(transformed) == 256
      assert Vips.Image.width(transformed) < 256
    end

    test "does nothing for images smaller or equal to size" do
      image = load_image_fixture("photo-square.heic")

      {:ok, transformed} = ImageOperations.resize(image, 512)

      assert image.ref == transformed.ref
    end

    test "loads image when path is given" do
      assert {:ok, image} = ImageOperations.resize("test/fixtures/photo-square.heic", 256)
      assert Vips.Image.width(image) == 256
      assert Vips.Image.height(image) == 256
    end
  end

  describe "thumbnail(path)" do
    test "makes thumbnail from image file located at given path" do
      path = "test/fixtures/photo-square.heic"

      {:ok, transformed} = ImageOperations.thumbnail(path, 24)
      assert Vips.Image.width(transformed) == 24
      assert Vips.Image.height(transformed) == 24
    end
  end
end
