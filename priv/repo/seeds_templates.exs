# Template Seeds
alias Paperform2web.Repo
alias Paperform2web.Templates.Template

# Default CSS template
default_css = """
<style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; background: #f4f4f4; }
    .container { max-width: 800px; margin: 0 auto; background: white; box-shadow: 0 0 20px rgba(0,0,0,0.1); min-height: 100vh; }
    .document-header { background: #2c3e50; color: white; padding: 2rem; text-align: center; }
    .document-title { font-size: 2rem; margin-bottom: 0.5rem; }
    .document-type-badge { background: #3498db; padding: 0.5rem 1rem; border-radius: 20px; display: inline-block; font-size: 0.9rem; }
    .document-content { padding: 2rem; }
    .section { margin-bottom: 1.5rem; }
    .form-title { color: #2c3e50; margin-bottom: 2rem; text-align: center; }
    .form-section { color: #2c3e50; margin: 2rem 0 1rem 0; border-bottom: 2px solid #e9ecef; padding-bottom: 0.5rem; }
    .form-group { margin-bottom: 1.5rem; }
    .form-label { display: block; margin-bottom: 0.5rem; font-weight: bold; color: #2c3e50; }
    .section-header { color: #2c3e50; margin-bottom: 1rem; }
    .section-paragraph { margin-bottom: 1rem; }
    .section-list { margin-left: 1.5rem; }
    .section-table { width: 100%; border-collapse: collapse; margin-bottom: 1rem; }
    .section-table th, .section-table td { border: 1px solid #ddd; padding: 0.75rem; text-align: left; }
    .section-table th { background: #f8f9fa; font-weight: bold; }
    .form-field { margin-bottom: 1rem; }
    .form-field label { display: block; margin-bottom: 0.5rem; font-weight: bold; }
    .form-field input, .form-field textarea, .form-field select { padding: 0.5rem; border: 1px solid #ddd; border-radius: 4px; width: 100%; font-family: inherit; }
    .form-field textarea { resize: vertical; min-height: 100px; }
    .form-field input[type="checkbox"], .form-field input[type="radio"] { width: auto; margin-right: 0.5rem; }
    .form-field .field-value { padding: 0.5rem; background: #f8f9fa; border: 1px solid #e9ecef; border-radius: 4px; }
    .bold { font-weight: bold; }
    .italic { font-style: italic; }
    .font-large { font-size: 1.5rem; }
    .font-medium { font-size: 1.2rem; }
    .font-small { font-size: 0.9rem; }
    .align-center { text-align: center; }
    .align-right { text-align: right; }
    .align-left { text-align: left; }
</style>
"""

# Minimal CSS template
minimal_css = """
<style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: Georgia, serif; line-height: 1.8; color: #222; background: white; }
    .container { max-width: 700px; margin: 0 auto; padding: 2rem; }
    .document-header { border-bottom: 2px solid #eee; padding-bottom: 1rem; margin-bottom: 2rem; }
    .document-title { font-size: 1.8rem; margin-bottom: 0.5rem; }
    .document-content { }
    .section { margin-bottom: 1.5rem; }
    .bold { font-weight: bold; }
    .italic { font-style: italic; }
</style>
"""

# Dark CSS template
dark_css = """
<style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #e0e0e0; background: #1a1a1a; }
    .container { max-width: 800px; margin: 0 auto; background: #2d2d2d; box-shadow: 0 0 20px rgba(0,0,0,0.5); min-height: 100vh; }
    .document-header { background: #1e3a5f; color: white; padding: 2rem; text-align: center; }
    .document-title { font-size: 2rem; margin-bottom: 0.5rem; }
    .document-type-badge { background: #4a90e2; padding: 0.5rem 1rem; border-radius: 20px; display: inline-block; font-size: 0.9rem; }
    .document-content { padding: 2rem; }
    .section { margin-bottom: 1.5rem; }
    .form-title { color: #2c3e50; margin-bottom: 2rem; text-align: center; }
    .form-section { color: #2c3e50; margin: 2rem 0 1rem 0; border-bottom: 2px solid #e9ecef; padding-bottom: 0.5rem; }
    .form-group { margin-bottom: 1.5rem; }
    .form-label { display: block; margin-bottom: 0.5rem; font-weight: bold; color: #2c3e50; }
    .section-table { width: 100%; border-collapse: collapse; margin-bottom: 1rem; }
    .section-table th, .section-table td { border: 1px solid #555; padding: 0.75rem; text-align: left; }
    .section-table th { background: #3a3a3a; font-weight: bold; }
    .form-field input, .form-field textarea, .form-field select { padding: 0.5rem; border: 1px solid #555; border-radius: 4px; width: 100%; background: #3a3a3a; color: #e0e0e0; font-family: inherit; }
    .form-field textarea { resize: vertical; min-height: 100px; }
    .form-field input[type="checkbox"], .form-field input[type="radio"] { width: auto; margin-right: 0.5rem; }
    .form-field .field-value { padding: 0.5rem; background: #3a3a3a; border: 1px solid #555; border-radius: 4px; }
    .bold { font-weight: bold; }
    .italic { font-style: italic; }
</style>
"""

# Pure HTML template (no CSS) - like the attached image
pure_html_css = ""

# Create templates
templates = [
  %{
    name: "Default Professional",
    slug: "default",
    description: "Clean, professional styling with blue accents and modern design elements",
    css_content: default_css,
    is_active: true,
    sort_order: 1
  },
  %{
    name: "Minimal Clean",
    slug: "minimal",
    description: "Simple, typography-focused design with clean lines",
    css_content: minimal_css,
    is_active: true,
    sort_order: 2
  },
  %{
    name: "Dark Mode",
    slug: "dark",
    description: "Dark background with light text for reduced eye strain",
    css_content: dark_css,
    is_active: true,
    sort_order: 3
  },
  %{
    name: "Pure HTML",
    slug: "pure",
    description: "No styling - pure HTML structure for maximum compatibility",
    css_content: pure_html_css,
    is_active: true,
    sort_order: 4
  }
]

# Insert templates (skip if already exists)
Enum.each(templates, fn template_attrs ->
  case Repo.get_by(Template, slug: template_attrs.slug) do
    nil ->
      %Template{}
      |> Template.changeset(template_attrs)
      |> Repo.insert!()
      IO.puts("Created template: #{template_attrs.name}")
    
    existing ->
      # Update existing template
      existing
      |> Template.changeset(template_attrs)
      |> Repo.update!()
      IO.puts("Updated template: #{template_attrs.name}")
  end
end)

IO.puts("Templates seeded successfully!")