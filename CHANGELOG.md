# Changelog

### 0.0.6 (Nov 8 2024)
* after upload, URLs were not being appended with timestamps. Fixed.

### 0.0.5 (Nov 5 2024)
* timestamps added to image urls
* multiple images now shift indexes on delete

### 0.0.4 (Oct 22 2024)

* linter warning fixed
* repo transaction removed from `m:Thumbtack.ImageUpload`


### 0.0.3 (Oct 20 2024)

* `m:Thumbtack.ImageUpload`:
  * `:format` option added
  * callback API changed
* `:resize` image transformation now supports rectangles


### 0.0.2 (Oct 19 2024)

* `m:Thumbtack.ImageUpload` callback API changed
* `Ecto.Schema.schema/2` macro call removed from `m:Thumbtack.ImageUpload`
* improved documentation


### 0.0.1 (Oct 18 2024)

* initial release
