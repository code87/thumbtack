defmodule Thumbtack.ImageUpload.Uploader.TransformationTest do
  alias Thumbtack.ImageUpload.Style
  alias Thumbtack.ImageUpload.Transformation
  alias Thumbtack.ImageUpload.Uploader

  alias Vix.Vips

  use Thumbtack.TestCase

  def build_uploader(attrs \\ []) do
    Uploader.new(attrs)
  end

  describe "process(style_state, transformation, uploader)" do
    test "lazy-loads image on first transformation, applies transformation" do
      uploader = build_uploader(src_path: "test/fixtures/photo-wide.jpg")

      style_state = Style.new(image: nil)

      assert %Style{
               image: %Vix.Vips.Image{}
             } = Transformation.process(style_state, :square, uploader)
    end

    test "applies second transformation" do
      uploader = build_uploader()

      image = load_image_fixture("photo-square.heic")
      style_state = Style.new(image: image)

      assert %Style{
               image: %Vix.Vips.Image{} = transformed
             } = Transformation.process(style_state, {:resize, 256}, uploader)

      assert transformed.ref != image.ref
    end

    test "returns error if transformation fails" do
      uploader = build_uploader(src_path: "test/fixtures/photo-unknown.jpg")

      style_state = Style.new(image: nil)

      assert {:error, _reason} = Transformation.process(style_state, :square, uploader)
    end
  end

  describe "special_case: :thumbnail transformation" do
    test "loads image from another style state output" do
      uploader =
        build_uploader(
          state: %{
            original: %Style{image: nil, path: "test/fixtures/photo-square.heic"}
          }
        )

      style_state = Style.new()

      assert %Style{image: image} =
               Transformation.process(
                 style_state,
                 {:thumbnail, size: 64, source: :original},
                 uploader
               )

      assert Vips.Image.height(image) == 64
    end

    test "returns error if another style is invalid" do
      uploader =
        build_uploader(
          state: %{
            original: %Style{image: load_image_fixture("photo-square.heic")}
          }
        )

      style_state = Style.new()

      assert {:error, _reason} =
               Transformation.process(
                 style_state,
                 {:thumbnail, size: 64, source: :original},
                 uploader
               )
    end
  end
end
