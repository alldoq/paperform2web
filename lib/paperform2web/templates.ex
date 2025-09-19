defmodule Paperform2web.Templates do
  @moduledoc """
  The Templates context.
  """

  import Ecto.Query, warn: false
  alias Paperform2web.Repo
  alias Paperform2web.Templates.Template

  @doc """
  Returns the list of active templates, ordered by sort_order.
  """
  def list_active_templates do
    Template
    |> where([t], t.is_active == true)
    |> order_by([t], t.sort_order)
    |> Repo.all()
  end

  @doc """
  Returns the list of all templates.
  """
  def list_templates do
    Repo.all(Template)
  end

  @doc """
  Gets a single template.
  """
  def get_template!(id), do: Repo.get!(Template, id)

  @doc """
  Gets a template by slug.
  """
  def get_template_by_slug(slug) do
    Repo.get_by(Template, slug: slug)
  end

  @doc """
  Gets the default template (first active template by sort order).
  """
  def get_default_template do
    Template
    |> where([t], t.is_active == true)
    |> order_by([t], t.sort_order)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Creates a template.
  """
  def create_template(attrs \\ %{}) do
    %Template{}
    |> Template.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a template.
  """
  def update_template(%Template{} = template, attrs) do
    template
    |> Template.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a template.
  """
  def delete_template(%Template{} = template) do
    Repo.delete(template)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking template changes.
  """
  def change_template(%Template{} = template, attrs \\ %{}) do
    Template.changeset(template, attrs)
  end
end