defmodule Paperform2web.HtmlGenerator.CssThemes do
  @moduledoc """
  CSS theme generation for HTML documents.
  """

  def generate_css(theme) do
    base_css = case theme do
      "minimal" -> minimal_css()
      "dark" -> dark_css()
      "modern" -> modern_css()
      "classic" -> classic_css()
      "colorful" -> colorful_css()
      "newspaper" -> newspaper_css()
      "elegant" -> elegant_css()
      _ -> default_css()
    end

    # Add 80% width container rule and radio button styling for all themes
    full_width_css = """
    <style>
        .container {
            max-width: none !important;
            width: 80% !important;
            margin: 0 auto;
            padding: 1rem;
        }

        /* Radio button field styling */
        .radio-field {
            margin-bottom: 1rem;
        }
        .radio-group-label {
            display: block;
            font-weight: 600;
            margin-bottom: 0.5rem;
            color: #374151;
        }
        .radio-options {
            display: flex;
            flex-direction: column;
            gap: 0.25rem;
        }
        .radio-options .radio-option {
            display: flex;
            align-items: center;
            margin-bottom: 0;
        }
        .radio-options label {
            display: inline;
            align-items: center;
            font-weight: normal;
            cursor: pointer;
            padding: 0;
            margin: 0;
            margin-left: 0.5rem;
        }
        .radio-options input[type="radio"] {
            margin: 0;
            transform: scale(1.2);
        }

        /* Form field label improvements */
        .form-field label {
            margin-bottom: 0.125rem;
        }

        /* Ensure checkbox fields are properly aligned */
        .form-field.checkbox-field {
            align-items: center;
        }
        .form-field.checkbox-field label {
            margin-left: 0.5rem;
            margin-bottom: 0;
        }
    </style>
    """

    base_css <> full_width_css
  end

  def default_css do
    """
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; background: #f4f4f4; }
        .container { max-width: 800px; margin: 0 auto; background: white; box-shadow: 0 0 20px rgba(0,0,0,0.1); min-height: 100vh; }
        .document-header { background: #2c3e50; color: white; padding: 2rem; text-align: center; }
        .document-title { font-size: 2rem; margin-bottom: 0.5rem; }
        .document-type-badge { background: #3498db; padding: 0.5rem 1rem; border-radius: 20px; display: inline-block; font-size: 0.9rem; }
        .document-content { padding: 2rem; }
        .section { margin-bottom: 1.5rem; }
        .section-header { color: #2c3e50; margin-bottom: 1rem; }
        .section-paragraph { margin-bottom: 1rem; }
        .section-list { margin-left: 1.5rem; }
        .section-table { width: 100%; border-collapse: collapse; margin-bottom: 1rem; }
        .section-table th, .section-table td { border: 1px solid #ddd; padding: 0.75rem; text-align: left; }
        .section-table th { background: #f8f9fa; font-weight: bold; }
        .form-field { margin-bottom: 1rem; }
        .form-field label { display: block; margin-bottom: 0.125rem; font-weight: bold; }
        .form-question { margin-bottom: 0.75rem; font-weight: bold; color: #333; font-size: 1rem; }
        .form-field input[type="text"], .form-field input[type="email"], .form-field input[type="tel"], .form-field input[type="date"], .form-field input[type="number"], .form-field textarea, .form-field select { padding: 0.5rem; border: 1px solid #ddd; border-radius: 4px; width: 100%; }
        .form-field select { background: white; background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e"); background-position: right 0.5rem center; background-repeat: no-repeat; background-size: 1.5em 1.5em; padding-right: 2.5rem; appearance: none; }
        .form-field select:focus { border-color: #3498db; outline: none; box-shadow: 0 0 0 2px rgba(52, 152, 219, 0.2); }
        .form-field input[type="checkbox"], .form-field input[type="radio"] { width: auto; margin-right: 0.5rem; transform: scale(1.2); }
        .form-field.checkbox-field { display: flex; align-items: flex-start; }
        .form-field.checkbox-field label { margin-bottom: 0; font-weight: normal; flex: 1; }
        .form-field.checkbox-field input[type="checkbox"] { margin-top: 2px; flex-shrink: 0; }
        .bold { font-weight: bold; }
        .italic { font-style: italic; }
        .font-large { font-size: 1.5rem; }
        .font-medium { font-size: 1.2rem; }
        .font-small { font-size: 0.9rem; }
        .align-center { text-align: center; }
        .align-right { text-align: right; }
        .align-left { text-align: left; }
        .document-metadata { background: #ecf0f1; padding: 1.5rem; border-top: 1px solid #bdc3c7; }
        .metadata-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin-top: 1rem; }
        .metadata-item { background: white; padding: 1rem; border-radius: 6px; }
    </style>
    """
  end

  def minimal_css do
    """
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: Georgia, serif; line-height: 1.8; color: #222; background: white; }
        .container { max-width: 700px; margin: 0 auto; padding: 2rem; }
        .document-header { border-bottom: 2px solid #eee; padding-bottom: 1rem; margin-bottom: 2rem; }
        .document-title { font-size: 1.8rem; margin-bottom: 0.5rem; }
        .document-content { }
        .section { margin-bottom: 1.5rem; }
        .form-field { margin-bottom: 1rem; }
        .form-field label { display: block; margin-bottom: 0.125rem; font-weight: 500; }
        .form-question { margin-bottom: 0.75rem; font-weight: 600; color: #2c3e50; font-size: 1rem; }
        .form-field input[type="text"], .form-field input[type="email"], .form-field input[type="tel"], .form-field input[type="date"], .form-field input[type="number"], .form-field textarea, .form-field select { padding: 0.5rem; border: 1px solid #ddd; border-radius: 0; width: 100%; font-family: inherit; }
        .form-field select:focus, .form-field input:focus, .form-field textarea:focus { border-color: #333; outline: none; }
        .form-field input[type="checkbox"], .form-field input[type="radio"] { width: auto; margin-right: 0.5rem; transform: scale(1.2); }
        .form-field.checkbox-field { display: flex; align-items: flex-start; }
        .form-field.checkbox-field label { margin-bottom: 0; font-weight: normal; flex: 1; }
        .form-field.checkbox-field input[type="checkbox"] { margin-top: 2px; flex-shrink: 0; }
        .bold { font-weight: bold; }
        .italic { font-style: italic; }
    </style>
    """
  end

  def dark_css do
    """
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #e0e0e0; background: #1a1a1a; }
        .container { max-width: 800px; margin: 0 auto; background: #2d2d2d; box-shadow: 0 0 20px rgba(0,0,0,0.5); min-height: 100vh; }
        .document-header { background: #1e3a5f; color: white; padding: 2rem; text-align: center; }
        .document-title { font-size: 2rem; margin-bottom: 0.5rem; }
        .document-type-badge { background: #4a90e2; padding: 0.5rem 1rem; border-radius: 20px; display: inline-block; font-size: 0.9rem; }
        .document-content { padding: 2rem; }
        .section { margin-bottom: 1.5rem; }
        .section-table { width: 100%; border-collapse: collapse; margin-bottom: 1rem; }
        .section-table th, .section-table td { border: 1px solid #555; padding: 0.75rem; text-align: left; }
        .section-table th { background: #3a3a3a; font-weight: bold; }
        .form-field input[type="text"], .form-field input[type="email"], .form-field input[type="tel"], .form-field input[type="date"], .form-field input[type="number"], .form-field textarea, .form-field select { padding: 0.5rem; border: 1px solid #555; border-radius: 4px; width: 100%; background: #3a3a3a; color: #e0e0e0; }
        .form-field select { background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%23e0e0e0' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e"); background-position: right 0.5rem center; background-repeat: no-repeat; background-size: 1.5em 1.5em; padding-right: 2.5rem; appearance: none; }
        .form-field select:focus { border-color: #64b5f6; outline: none; box-shadow: 0 0 0 2px rgba(100, 181, 246, 0.3); }
        .form-field input[type="checkbox"], .form-field input[type="radio"] { width: auto; margin-right: 0.5rem; transform: scale(1.2); accent-color: #4a90e2; }
        .form-field.checkbox-field { display: flex; align-items: flex-start; }
        .form-field.checkbox-field label { margin-bottom: 0; font-weight: normal; flex: 1; }
        .form-field.checkbox-field input[type="checkbox"] { margin-top: 2px; flex-shrink: 0; }
        .bold { font-weight: bold; }
        .italic { font-style: italic; }
    </style>
    """
  end

  def modern_css do
    """
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif; line-height: 1.6; color: #1f2937; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
        .container { max-width: 900px; margin: 2rem auto; background: white; border-radius: 20px; box-shadow: 0 25px 50px rgba(0,0,0,0.15); overflow: hidden; }
        .document-header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 3rem 2rem; text-align: center; position: relative; }
        .document-header::after { content: ''; position: absolute; bottom: 0; left: 0; right: 0; height: 4px; background: linear-gradient(90deg, #ff6b6b, #4ecdc4, #45b7d1, #96ceb4, #feca57); }
        .document-title { font-size: 2.5rem; font-weight: 700; margin: 0; text-shadow: 0 2px 4px rgba(0,0,0,0.2); }
        .document-content { padding: 3rem; }
        .section { margin-bottom: 2rem; }
        .form-section { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; margin: 2rem -1rem 2rem -1rem; padding: 1rem 2rem; border-radius: 15px; font-weight: 600; }
        .form-label { color: #4a5568; font-weight: 600; margin-bottom: 0.125rem; display: block; }
        .form-question { margin-bottom: 1rem; font-weight: 600; color: #2d3748; font-size: 1.1rem; }
        .form-field input, .form-field textarea, .form-field select { background: #f7fafc; border: 2px solid #e2e8f0; border-radius: 12px; padding: 1rem; width: 100%; transition: all 0.3s ease; font-size: 1rem; font-family: inherit; }
        .form-field input:focus, .form-field textarea:focus, .form-field select:focus { border-color: #667eea; box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1); outline: none; background: white; }
        .form-field select { background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%234a5568' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='m6 8 4 4 4-4'/%3e%3c/svg%3e"); background-position: right 1rem center; background-repeat: no-repeat; background-size: 1.5em 1.5em; padding-right: 3rem; appearance: none; }
        .form-field { margin-bottom: 1.5rem; }
        .form-field input[type="checkbox"], .form-field input[type="radio"] { width: auto; margin-right: 0.75rem; transform: scale(1.3); accent-color: #667eea; }
        .form-field.checkbox-field { display: flex; align-items: flex-start; background: #f7fafc; padding: 1rem; border-radius: 12px; border: 2px solid #e2e8f0; }
        .form-field.checkbox-field label { margin-bottom: 0; font-weight: normal; flex: 1; }
        .form-field.checkbox-field input[type="checkbox"] { margin-top: 3px; flex-shrink: 0; }
        .bold { font-weight: 700; }
        .italic { font-style: italic; }
    </style>
    """
  end

  def classic_css do
    """
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Times New Roman', Times, serif; line-height: 1.7; color: #2c3e50; background: #f8f9fa; }
        .container { max-width: 750px; margin: 2rem auto; background: white; border: 3px double #8b4513; padding: 0; }
        .document-header { background: #8b4513; color: #f4e4c1; padding: 2rem; text-align: center; border-bottom: 3px double #654321; }
        .document-title { font-size: 2.2rem; font-weight: normal; letter-spacing: 2px; text-transform: uppercase; }
        .document-content { padding: 2.5rem; background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="white"/><rect width="1" height="100" fill="%23e8e8e8" x="25"/><rect width="1" height="100" fill="%23e8e8e8" x="50"/><rect width="1" height="100" fill="%23e8e8e8" x="75"/></svg>'); }
        .section { margin-bottom: 2rem; }
        .form-section { border-left: 4px solid #8b4513; padding-left: 1rem; margin: 2rem 0 1.5rem 0; font-weight: bold; font-size: 1.1rem; text-transform: uppercase; letter-spacing: 1px; }
        .form-label { font-weight: bold; margin-bottom: 0.125rem; display: block; color: #5d4037; }
        .form-question { margin-bottom: 0.8rem; font-weight: bold; color: #3e2723; font-size: 1rem; }
        .form-field input, .form-field textarea, .form-field select { border: 2px solid #8b4513; background: #fefefe; padding: 0.7rem; width: 100%; font-family: inherit; border-radius: 0; }
        .form-field input:focus, .form-field textarea:focus, .form-field select:focus { outline: 2px solid #d2691e; outline-offset: 2px; }
        .form-field select { background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%238b4513' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='m6 8 4 4 4-4'/%3e%3c/svg%3e"); background-position: right 0.7rem center; background-repeat: no-repeat; background-size: 1.5em 1.5em; padding-right: 2.5rem; appearance: none; }
        .form-field { margin-bottom: 1.2rem; }
        .form-field input[type="checkbox"], .form-field input[type="radio"] { width: auto; margin-right: 0.5rem; transform: scale(1.2); accent-color: #8b4513; }
        .form-field.checkbox-field { display: flex; align-items: flex-start; }
        .form-field.checkbox-field label { margin-bottom: 0; font-weight: normal; flex: 1; }
        .form-field.checkbox-field input[type="checkbox"] { margin-top: 2px; flex-shrink: 0; }
        .bold { font-weight: bold; }
        .italic { font-style: italic; }
    </style>
    """
  end

  def colorful_css do
    """
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Comic Sans MS', cursive, sans-serif; line-height: 1.6; color: #2c3e50; background: linear-gradient(45deg, #ff9a9e 0%, #fecfef 50%, #fecfef 100%); }
        .container { max-width: 850px; margin: 1rem auto; background: white; border-radius: 25px; overflow: hidden; box-shadow: 0 20px 40px rgba(0,0,0,0.1); border: 5px solid transparent; background-clip: padding-box; }
        .container::before { content: ''; position: absolute; top: 0; left: 0; right: 0; bottom: 0; background: linear-gradient(45deg, #ff6b6b, #4ecdc4, #45b7d1, #96ceb4, #feca57, #ff9ff3); border-radius: 25px; padding: 5px; mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0); -webkit-mask-composite: destination-out; }
        .document-header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 2.5rem; text-align: center; }
        .document-title { font-size: 2.3rem; font-weight: bold; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); animation: rainbow 3s linear infinite; }
        @keyframes rainbow { 0% { filter: hue-rotate(0deg); } 100% { filter: hue-rotate(360deg); } }
        .document-content { padding: 2.5rem; background: linear-gradient(135deg, #fff9e6 0%, #f0f8ff 100%); }
        .section { margin-bottom: 2rem; }
        .form-section { background: linear-gradient(135deg, #ff6b6b, #4ecdc4); color: white; padding: 1rem 1.5rem; border-radius: 20px; margin: 2rem 0 1.5rem 0; font-weight: bold; text-shadow: 1px 1px 2px rgba(0,0,0,0.2); }
        .form-label { color: #e91e63; font-weight: bold; margin-bottom: 0.125rem; display: block; text-shadow: 1px 1px 2px rgba(0,0,0,0.1); }
        .form-field input, .form-field textarea, .form-field select { background: linear-gradient(135deg, #fff 0%, #f8f9ff 100%); border: 3px solid #ff6b6b; border-radius: 15px; padding: 1rem; width: 100%; font-size: 1rem; transition: all 0.3s ease; font-family: inherit; }
        .form-field input:focus, .form-field textarea:focus, .form-field select:focus { border-color: #4ecdc4; transform: scale(1.02); box-shadow: 0 5px 15px rgba(78, 205, 196, 0.3); outline: none; }
        .form-field select { background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%23ff6b6b' stroke-linecap='round' stroke-linejoin='round' stroke-width='2.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e"); background-position: right 1rem center; background-repeat: no-repeat; background-size: 1.5em 1.5em; padding-right: 3rem; appearance: none; }
        .form-field { margin-bottom: 1.5rem; }
        .form-field input[type="checkbox"], .form-field input[type="radio"] { width: auto; margin-right: 0.75rem; transform: scale(1.4); accent-color: #ff6b6b; }
        .form-field.checkbox-field { display: flex; align-items: flex-start; background: linear-gradient(135deg, #fff 0%, #f8f9ff 100%); padding: 1rem; border-radius: 15px; border: 3px solid #ff6b6b; }
        .form-field.checkbox-field label { margin-bottom: 0; font-weight: bold; color: #e91e63; flex: 1; text-shadow: 1px 1px 2px rgba(0,0,0,0.1); }
        .form-field.checkbox-field input[type="checkbox"] { margin-top: 3px; flex-shrink: 0; }
        .bold { font-weight: bold; color: #e91e63; }
        .italic { font-style: italic; color: #9c27b0; }
    </style>
    """
  end

  def newspaper_css do
    """
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Times New Roman', Times, serif; line-height: 1.5; color: #000; background: #f5f5dc; }
        .container { max-width: 800px; margin: 1rem auto; background: white; border: 2px solid #000; }
        .document-header { background: #000; color: white; padding: 1rem; text-align: center; border-bottom: 4px double #000; }
        .document-title { font-size: 2rem; font-weight: bold; letter-spacing: 3px; text-transform: uppercase; font-family: 'Old English Text MT', serif; }
        .document-content { padding: 2rem; column-count: 2; column-gap: 2rem; column-rule: 1px solid #ccc; }
        .section { margin-bottom: 1.5rem; break-inside: avoid; }
        .form-section { column-span: all; background: #000; color: white; padding: 0.5rem 1rem; margin: 1.5rem 0; font-weight: bold; text-align: center; letter-spacing: 2px; text-transform: uppercase; border-top: 2px solid #000; border-bottom: 2px solid #000; }
        .form-label { font-weight: bold; margin-bottom: 0.125rem; display: block; text-transform: uppercase; font-size: 0.9rem; letter-spacing: 1px; }
        .form-field input, .form-field textarea, .form-field select { border: none; border-bottom: 2px solid #000; background: transparent; padding: 0.5rem 0; width: 100%; font-family: inherit; }
        .form-field input:focus, .form-field textarea:focus, .form-field select:focus { outline: none; border-bottom-color: #666; }
        .form-field select { background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%23000' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='m6 8 4 4 4-4'/%3e%3c/svg%3e"); background-position: right 0.5rem center; background-repeat: no-repeat; background-size: 1.2em 1.2em; padding-right: 2rem; appearance: none; }
        .form-field { margin-bottom: 1rem; column-span: all; }
        .form-field input[type="checkbox"], .form-field input[type="radio"] { width: auto; margin-right: 0.5rem; transform: scale(1.1); accent-color: #000; }
        .form-field.checkbox-field { display: flex; align-items: flex-start; column-span: all; }
        .form-field.checkbox-field label { margin-bottom: 0; font-weight: bold; text-transform: uppercase; font-size: 0.9rem; letter-spacing: 1px; flex: 1; }
        .form-field.checkbox-field input[type="checkbox"] { margin-top: 2px; flex-shrink: 0; }
        .bold { font-weight: bold; text-transform: uppercase; }
        .italic { font-style: italic; }
        @media (max-width: 768px) { .document-content { column-count: 1; } }
    </style>
    """
  end

  def elegant_css do
    """
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Playfair Display', 'Georgia', serif; line-height: 1.7; color: #2c3e50; background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%); }
        .container { max-width: 900px; margin: 3rem auto; background: white; border-radius: 2px; box-shadow: 0 0 50px rgba(0,0,0,0.1); position: relative; }
        .container::before { content: ''; position: absolute; top: 0; left: 0; right: 0; height: 8px; background: linear-gradient(90deg, #d4af37, #ffd700, #d4af37); }
        .document-header { background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%); color: #ecf0f1; padding: 4rem 3rem 3rem 3rem; text-align: center; position: relative; }
        .document-header::after { content: ''; position: absolute; bottom: -10px; left: 50%; transform: translateX(-50%); width: 100px; height: 4px; background: #d4af37; }
        .document-title { font-size: 2.8rem; font-weight: 300; letter-spacing: 3px; text-shadow: 0 2px 4px rgba(0,0,0,0.3); }
        .document-content { padding: 4rem 3rem; }
        .section { margin-bottom: 2.5rem; }
        .form-section { color: #2c3e50; font-size: 1.3rem; font-weight: 300; margin: 3rem 0 2rem 0; padding-bottom: 0.5rem; border-bottom: 2px solid #d4af37; letter-spacing: 1px; }
        .form-label { color: #5d6d7e; font-weight: 400; margin-bottom: 0.125rem; display: block; font-size: 1.1rem; }
        .form-field input, .form-field textarea, .form-field select { background: #fcfcfc; border: 1px solid #d5d8dc; padding: 1.2rem; width: 100%; font-family: 'Source Sans Pro', sans-serif; font-size: 1rem; transition: all 0.3s ease; }
        .form-field input:focus, .form-field textarea:focus, .form-field select:focus { border-color: #d4af37; box-shadow: 0 0 10px rgba(212, 175, 55, 0.2); outline: none; background: white; }
        .form-field select { background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%235d6d7e' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e"); background-position: right 1.2rem center; background-repeat: no-repeat; background-size: 1.5em 1.5em; padding-right: 3rem; appearance: none; }
        .form-field { margin-bottom: 2rem; }
        .form-field input[type="checkbox"], .form-field input[type="radio"] { width: auto; margin-right: 0.8rem; transform: scale(1.2); accent-color: #d4af37; }
        .form-field.checkbox-field { display: flex; align-items: flex-start; }
        .form-field.checkbox-field label { margin-bottom: 0; font-weight: 400; flex: 1; font-size: 1.1rem; }
        .form-field.checkbox-field input[type="checkbox"] { margin-top: 3px; flex-shrink: 0; }
        .bold { font-weight: 600; }
        .italic { font-style: italic; color: #7f8c8d; }
    </style>
    """
  end
end