defmodule Thumbtack.ImageUploadTest do
  use Thumbtack.TestCase

  describe "__using__(opts)" do
    test "validates format" do
      assert_raise ArgumentError, fn ->
        defmodule GifImage do
          use Thumbtack.ImageUpload,
            foreign_key: :user_id,
            format: :gif
        end
      end
    end

    test "defines image_output_format/0" do
      defmodule JpgImage do
        use Thumbtack.ImageUpload,
          foreign_key: :user_id,
          format: :jpg
      end

      assert :jpg == JpgImage.image_upload_format()
    end

    test "format defaults to :png" do
      defmodule PngImage do
        use Thumbtack.ImageUpload, foreign_key: :user_id
      end

      assert :png == PngImage.image_upload_format()
    end
  end
end
