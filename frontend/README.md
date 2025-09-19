# Paperform2Web Frontend

A minimalistic Vue 3 frontend for the Paperform2Web application with blue/gray design and Tailwind CSS.

## Features

- **Minimalistic Design**: Clean blue/gray color scheme with modern styling
- **File Upload**: Drag & drop interface with progress tracking
- **Real-time Processing**: Live status updates with progress bars
- **Document Viewer**: Modal viewer with HTML and JSON data views
- **Responsive Layout**: Works on desktop and mobile devices
- **Error Handling**: Comprehensive error states and user feedback

## Tech Stack

- **Vue 3** with Composition API
- **Tailwind CSS** for styling
- **Heroicons** for icons
- **Axios** for API communication
- **Vite** for development and building

## Setup

1. Install dependencies:
```bash
cd frontend
npm install
```

2. Start development server:
```bash
npm run dev
```

3. Build for production:
```bash
npm run build
```

The frontend will be available at `http://localhost:3000` and will proxy API requests to the Phoenix backend at `http://localhost:4000`.

## Component Structure

### Core Components

- **App.vue** - Main application layout
- **FileUpload.vue** - Drag & drop file upload with progress
- **ProcessingStatus.vue** - Real-time processing status display
- **DocumentList.vue** - List of processed documents
- **DocumentViewer.vue** - Modal viewer for document details
- **StatusBadge.vue** - Status indicator component

### Features

#### File Upload
- Drag & drop interface
- File validation (type and size)
- Upload progress bar
- Model selection (Llama 2, Llama 3, Mistral, etc.)
- Error handling with user-friendly messages

#### Processing Status
- Real-time status polling
- Progress indicators
- Processing time tracking
- Error message display
- Retry functionality for failed uploads

#### Document Management
- Clean list view with document previews
- Status badges for quick status identification
- Date formatting (relative and absolute)
- Document type detection from AI processing

#### Document Viewer
- Modal interface with HTML and JSON views
- Live HTML preview in iframe
- Structured JSON data display
- Download functionality
- Processing metadata display

## API Integration

The frontend integrates with the Phoenix backend through:

- **Documents API**: Upload, list, view, and manage documents
- **Auth API**: Check authentication status and test connections
- **Real-time Updates**: Polling for processing status changes

## Styling

### Color Scheme
- **Primary Blue**: #3b82f6 (blue-500) with various shades
- **Gray Scale**: #f9fafb to #111827 for neutral elements
- **Status Colors**: Green (success), Red (error), Blue (processing)

### Design Principles
- Minimalistic and clean interface
- Consistent spacing and typography
- Subtle shadows and borders
- Smooth transitions and hover effects
- Mobile-first responsive design

## Usage

1. **Upload Documents**: Drag files to the upload area or click to browse
2. **Monitor Processing**: Watch real-time progress in the processing queue
3. **View Results**: Click on completed documents to view HTML output
4. **Download**: Export processed documents as HTML files

The interface automatically handles:
- File validation and error reporting
- Progress tracking and status updates
- Connection status monitoring
- Responsive layout adjustments