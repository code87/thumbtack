defmodule Thumbtack.ImageTest do
  use Thumbtack.TestCase

  alias Thumbtack.Image
  alias Vix.Vips

  describe "load_image(path)" do
    test "loads image" do
      assert {:ok, %Vips.Image{}} = Image.load_image("test/fixtures/photo-small.jpg")
    end

    test "returns error if file does not exist" do
      assert {:error, "" <> _message} = Image.load_image("test/fixtures/photo-unknown.jpg")
    end

    test "returns error if file format is unknown" do
      assert {:error, "" <> _message} = Image.load_image("test/fixtures/corrupted.jpg")
    end
  end

  describe "save_image(image, path, format)" do
    test "saves image in a given format" do
      image = load_image_fixture("photo-square.heic")
      tempfile_path = Thumbtack.Utils.generate_tempfile_path(".jpg")

      assert :ok = Image.save_image(image, tempfile_path, :jpg)
      assert File.exists?(tempfile_path)
    end

    test "default format is png" do
      image = load_image_fixture("photo-small.jpg")

      tempfile_path = Thumbtack.Utils.generate_tempfile_path(".png")
      assert :ok = Image.save_image(image, tempfile_path)
      assert File.exists?(tempfile_path)
    end

    test "raises if format is not supported" do
      image = load_image_fixture("photo-small.jpg")

      assert_raise ArgumentError, fn ->
        Image.save_image(image, "/tmp/image.gif", :gif)
      end
    end
  end

  describe "format_supported?(format)" do
    test "returns true if format is supported" do
      assert Image.format_supported?(:jpg)
      assert Image.format_supported?(:png)
    end

    test "returns false if format is not supported" do
      refute Image.format_supported?(:gif)
    end
  end

  describe "format_extension(format)" do
    test "returns .extension if format is supported" do
      assert ".jpg" == Image.format_extension(:jpg)
      assert ".png" == Image.format_extension(:png)
    end

    test "raises if format is not supported" do
      assert_raise ArgumentError, fn ->
        Image.format_extension(:gif)
      end
    end
  end

  describe "dimensions(image)" do
    test "returns tuple with width and height" do
      image = load_image_fixture("photo-small.jpg")
      {322, 128} = Image.dimensions(image)
    end
  end

  describe "square(image_or_path)" do
    test "tall image" do
      image = load_image_fixture("photo-tall.png")

      assert {:ok, transformed} = Image.square(image)
      assert {256, 256} = Image.dimensions(transformed)
    end

    test "wide image" do
      image = load_image_fixture("photo-wide.jpg")

      assert {:ok, transformed} = Image.square(image)
      assert {318, 318} = Image.dimensions(transformed)
    end

    test "does nothing for square image" do
      image = load_image_fixture("photo-square.heic")

      assert {:ok, transformed} = Image.square(image)
      assert image.ref == transformed.ref
    end

    test "loads image when path is given" do
      assert {:ok, image} = Image.square("test/fixtures/photo-wide.jpg")
      assert {318, 318} = Image.dimensions(image)
    end

    test "returns error if file does not exist" do
      assert {:error, "" <> _message} = Image.square("test/fixtures/photo-unknown.jpg")
    end
  end

  describe "resize(image_or_path, size: size)" do
    test "width > height" do
      image = load_image_fixture("photo-wide.jpg")

      {:ok, transformed} = Image.resize(image, 256)
      assert {256, height} = Image.dimensions(transformed)
      assert height < 256
    end

    test "height > width" do
      image = load_image_fixture("photo-tall.png")

      {:ok, transformed} = Image.resize(image, 256)
      assert {width, 256} = Image.dimensions(transformed)
      assert width < 256
    end

    test "does nothing for images smaller or equal to size" do
      image = load_image_fixture("photo-square.heic")

      {:ok, transformed} = Image.resize(image, 512)
      assert image.ref == transformed.ref
    end

    test "loads image when path is given" do
      assert {:ok, image} = Image.resize("test/fixtures/photo-square.heic", 256)
      {256, 256} = Image.dimensions(image)
    end

    test "returns error if file does not exist" do
      assert {:error, "" <> _message} = Image.resize("test/fixtures/photo-unknown.jpg", 256)
    end
  end

  describe "thumbnail(path)" do
    test "makes thumbnail from image file located at given path" do
      path = "test/fixtures/photo-square.heic"

      {:ok, transformed} = Image.thumbnail(path, 24)
      assert {24, 24} = Image.dimensions(transformed)
    end

    test "returns error if file does not exist" do
      assert {:error, "" <> _message} = Image.thumbnail("test/fixtures/photo-unknown.jpg", 24)
    end

    test "raises if image is given" do
      image = load_image_fixture("photo-small.jpg")

      assert_raise ArgumentError, fn ->
        Image.thumbnail(image, 24)
      end
    end
  end
end
