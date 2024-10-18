defmodule Thumbtack do
  @moduledoc """
  Root module.

  The key modules of the Thumbtack library are:
    * `Thumbtack.ImageUpload`
    * `Thumbtack.Storage`
      * `Thumbtack.Storage.Local`

  ### Configuration Options
    * `:repo` - your app Ecto repository. Example: `MyApp.Repo`
    * `:storage` - storage provider. One of:
      * `Thumbtack.Storage.Local`
      * `Thumbtack.Storage.S3` (not available yet)

  Example:
      config :thumbtack,
        repo: MyApp.Repo,
        storage: Thumbtack.Storage.Local

  """

  @otp_app :thumbtack

  @doc """
  Returns configured Ecto repository.

  Example:
      Thumbtack.repo()
      > MyApp.Repo

  """
  def repo, do: config(:repo)

  @doc """
  Returns configured storage module.

  Example:
      Thumbtack.storage()
      > Thumbtack.Storage.Local

  """
  def storage, do: config(:storage)

  @doc false
  # internal use only
  def config(module_or_key \\ __MODULE__), do: Application.get_env(@otp_app, module_or_key)
end
