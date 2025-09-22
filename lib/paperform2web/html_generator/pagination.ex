defmodule Paperform2web.HtmlGenerator.Pagination do
  @moduledoc """
  PDF pagination functionality for multi-page documents.
  Provides CSS styling and JavaScript navigation for paginated content.
  """

  @doc """
  Generates paginated content for PDF documents with multiple pages.
  """
  def generate_pdf_paginated_content(data, editing_mode, content_generator) do
    pages = data["pages"] || []
    total_pages = length(pages)

    pages_html = pages
    |> Enum.with_index()
    |> Enum.map_join("\n", fn {page_data, index} ->
      page_number = index + 1
      is_first_page = page_number == 1

      """
      <div class="pdf-page" id="page-#{page_number}" style="#{if not is_first_page, do: "display: none;", else: ""}">
        <div class="page-header">
          <h2 class="page-title">Page #{page_number} of #{total_pages}</h2>
        </div>
        #{content_generator.(page_data["content"], editing_mode)}
      </div>
      """
    end)

    """
    <main class="document-content pdf-paginated-content">
        #{pages_html}
        <div class="pagination-controls">
          <button id="prev-page" class="page-btn" onclick="previousPage()" disabled>← Previous</button>
          <span id="page-info" class="page-info">Page 1 of #{total_pages}</span>
          <button id="next-page" class="page-btn" onclick="nextPage()">Next →</button>
        </div>
    </main>
    """
  end

  @doc """
  Generates CSS styles for pagination functionality.
  """
  def generate_pagination_css() do
    """
    <style>
        .pdf-paginated-content {
            position: relative;
            min-height: 70vh;
        }

        .pdf-page {
            transition: opacity 0.3s ease-in-out;
        }

        .page-header {
            border-bottom: 2px solid #e5e7eb;
            margin-bottom: 2rem;
            padding-bottom: 1rem;
        }

        .page-title {
            color: #374151;
            font-size: 1.5rem;
            font-weight: 600;
            margin: 0;
        }

        .pagination-controls {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 1rem;
            margin-top: 3rem;
            padding: 2rem 0;
            border-top: 1px solid #e5e7eb;
        }

        .page-btn {
            background: #3b82f6;
            color: white;
            border: none;
            padding: 0.75rem 1.5rem;
            border-radius: 0.5rem;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s ease;
            font-size: 0.875rem;
        }

        .page-btn:hover:not(:disabled) {
            background: #2563eb;
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
        }

        .page-btn:disabled {
            background: #9ca3af;
            cursor: not-allowed;
            transform: none;
            box-shadow: none;
        }

        .page-info {
            font-weight: 500;
            color: #374151;
            font-size: 0.875rem;
            min-width: 100px;
            text-align: center;
        }

        .pdf-paginated .container {
            max-width: none;
            width: 100%;
        }
    </style>
    """
  end

  @doc """
  Generates JavaScript for pagination navigation.
  """
  def generate_pagination_javascript(pages) do
    total_pages = length(pages)

    """
    <script>
        let currentPage = 1;
        const totalPages = #{total_pages};

        function showPage(pageNumber) {
            // Hide all pages
            for (let i = 1; i <= totalPages; i++) {
                const page = document.getElementById('page-' + i);
                if (page) {
                    page.style.display = 'none';
                }
            }

            // Show the requested page
            const targetPage = document.getElementById('page-' + pageNumber);
            if (targetPage) {
                targetPage.style.display = 'block';
            }

            // Update controls
            updatePaginationControls();

            // Scroll to top
            window.scrollTo({top: 0, behavior: 'smooth'});
        }

        function nextPage() {
            if (currentPage < totalPages) {
                currentPage++;
                showPage(currentPage);
            }
        }

        function previousPage() {
            if (currentPage > 1) {
                currentPage--;
                showPage(currentPage);
            }
        }

        function updatePaginationControls() {
            const prevBtn = document.getElementById('prev-page');
            const nextBtn = document.getElementById('next-page');
            const pageInfo = document.getElementById('page-info');

            if (prevBtn) prevBtn.disabled = currentPage <= 1;
            if (nextBtn) nextBtn.disabled = currentPage >= totalPages;
            if (pageInfo) pageInfo.textContent = `Page ${currentPage} of ${totalPages}`;
        }

        // Keyboard navigation
        document.addEventListener('keydown', function(e) {
            if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
                e.preventDefault();
                nextPage();
            } else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
                e.preventDefault();
                previousPage();
            }
        });

        // Initialize
        document.addEventListener('DOMContentLoaded', function() {
            updatePaginationControls();
        });
    </script>
    """
  end
end