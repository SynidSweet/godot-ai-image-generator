# Product Requirements Document: Godot AI Pixel Art Generator Plugin

## Project Overview

A Godot Engine plugin that generates pixel art game assets using Google's Gemini 2.5 Flash Image API (Nano Banana). The plugin enables game developers to rapidly create consistent pixel art assets (NPCs, furniture, items, etc.) by combining reference images with customizable prompt templates.

## Problem Statement

Creating pixel art assets for games is time-consuming and requires specialized artistic skills. Game developers need a tool that can:
- Generate multiple variations of similar assets quickly
- Maintain consistent art style across assets
- Allow iterative refinement of generated images
- Integrate directly into their Godot workflow

## Target Users

- Indie game developers working on pixel art games
- Game designers prototyping game concepts
- Solo developers without dedicated art resources
- Small teams looking to accelerate asset production

## Core Features

### 1. Template System

**Description**: Create, manage, and select reusable template configurations combining reference images and prompt templates.

**Requirements**:
- Create new templates with custom names (e.g., "NPC Character", "Furniture", "Props")
- Edit existing templates (modify reference image, base prompt, settings)
- Delete templates
- Select active template from dropdown/list
- Templates persist between sessions (saved to plugin config)
- Each template stores:
  - Reference image path
  - Base prompt text
  - Color palette settings
  - Target pixel resolution
  - Generation parameters (temperature, etc.)

### 2. Google Gemini 2.5 Flash Image Integration

**Description**: Interface with Google's Gemini 2.5 Flash Image API (Nano Banana) for AI-powered image generation.

**Requirements**:
- API key configuration (stored securely in plugin settings)
- Model ID: `gemini-2.5-flash-image` or `gemini-2.5-flash-image-preview`
- Support for text-to-image generation
- Support for image-to-image editing (for polish passes)
- Handle API errors gracefully with user-friendly messages
- Display API request status (processing, success, error)
- Cost tracking: Display estimated cost per generation (~$0.039 per image)

**API Documentation Reference**: https://ai.google.dev/gemini-api/docs/image-generation

### 3. Multi-Step Image Processing Pipeline

**Description**: Process images through multiple stages to ensure pixel art consistency.

#### Step 1: Color Palette Conformance
- Load reference image
- Extract or apply predefined color palette
- Reduce reference image colors to match palette
- Support for custom palette creation/import
- Common pixel art palettes (DB32, AAP-64, etc.) as presets
- Display before/after palette conformance

#### Step 2: AI Generation
- Combine base prompt + detail prompt + reference image
- Send to Gemini 2.5 Flash Image API
- Receive generated image
- Display result

#### Step 3: Pixelation
- Apply programmatic pixelation to generated image
- Target resolution (e.g., 32x32, 64x64, 128x128) configurable per template
- Nearest-neighbor downsampling to target resolution
- Optional upscaling for display purposes
- Preserve pixel-perfect alignment

#### Step 4: Optional Polish Pass (Iterative)
- "Polish" button to send pixelated image back to Gemini
- Include polish-specific prompt guidance
- Re-pixelate the polished result
- Can be triggered multiple times
- Display history of polish iterations
- Allow reverting to previous iteration

### 4. User Interface

**Description**: Comprehensive UI panel within Godot editor showing all stages of the generation process.

**Layout Requirements**:

```
┌─────────────────────────────────────────────────────┐
│  Template: [Dropdown v]  [New] [Edit] [Delete]     │
├─────────────────────────────────────────────────────┤
│  INPUT SECTION                                       │
│  ┌──────────────────┐  ┌────────────────────────┐  │
│  │  Reference Image │  │ Base Prompt:           │  │
│  │                  │  │ [text area]            │  │
│  │  [image preview] │  │                        │  │
│  │                  │  │ Detail Prompt:         │  │
│  │  [Select Image]  │  │ [text area]            │  │
│  └──────────────────┘  │                        │  │
│                         │ [Generate Button]      │  │
│                         └────────────────────────┘  │
├─────────────────────────────────────────────────────┤
│  PROCESSING PIPELINE                                 │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐│
│  │ 1. Palette   │ │ 2. Generated │ │ 3. Pixelated ││
│  │ Conformed    │ │ Image        │ │ Result       ││
│  │              │ │              │ │              ││
│  │ [preview]    │ │ [preview]    │ │ [preview]    ││
│  │              │ │              │ │              ││
│  └──────────────┘ └──────────────┘ └──────────────┘│
│                                                      │
│  ┌──────────────────────────────────────────────┐  │
│  │ 4. Polish (Optional)                          │  │
│  │ [Polish Button] Iterations: [0]               │  │
│  │                                                │  │
│  │ [preview of polished result]                  │  │
│  │                                                │  │
│  │ [Undo Polish] [Redo Polish]                   │  │
│  └──────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────┤
│  OUTPUT                                              │
│  Final Image: [large preview]                       │
│                                                      │
│  Filename: [text input].png                         │
│  [Save to Project] [Copy to Clipboard]              │
└─────────────────────────────────────────────────────┘
```

**UI Components**:
- Template selector and management buttons
- Reference image loader with preview
- Multi-line text areas for prompts
- Image preview panels for each pipeline stage
- Generation progress indicator
- Polish iteration counter and controls
- Save controls with filename input
- Status/error message display area

### 5. Image Export

**Description**: Save generated images to the project for immediate use.

**Requirements**:
- Save as PNG format (preserve transparency if applicable)
- Default save location: `res://generated_assets/`
- Organize by template name (e.g., `res://generated_assets/npcs/`)
- Auto-generate filenames with timestamp
- Allow custom filename override
- Copy to clipboard functionality
- Auto-refresh Godot FileSystem dock after save

## Technical Requirements

### Plugin Architecture

**Structure**:
```
addons/
└── ai_pixel_art_generator/
    ├── plugin.cfg
    ├── plugin.gd
    ├── ui/
    │   ├── main_panel.tscn
    │   ├── main_panel.gd
    │   ├── template_editor.tscn
    │   └── template_editor.gd
    ├── core/
    │   ├── gemini_client.gd
    │   ├── image_processor.gd
    │   ├── palette_manager.gd
    │   └── template_manager.gd
    ├── data/
    │   ├── templates.json
    │   └── palettes/
    │       ├── db32.json
    │       ├── aap64.json
    │       └── custom.json
    └── assets/
        └── icons/
```

### Dependencies

- **Godot Version**: 4.x (specify minimum version)
- **GDScript**: Primary language
- **HTTPRequest**: For Gemini API calls
- **Image Processing**: Native Godot Image class
- **JSON**: For template/palette storage

### API Integration

**Gemini API Details**:
- Endpoint: Google AI Gemini API
- Model: `gemini-2.5-flash-image`
- Authentication: API key (user-provided)
- Cost: ~$0.039 per image (~1290 output tokens)
- Rate limits: As per Google's API limits

### Image Processing Algorithms

**Color Palette Conformance**:
- Euclidean distance in RGB space
- K-means clustering for palette extraction
- Dithering options (none, Floyd-Steinberg, Bayer)

**Pixelation**:
- Nearest-neighbor downsampling
- Configurable target resolutions: 8x8, 16x16, 32x32, 64x64, 128x128, custom
- Integer scaling for upscaling display

## Non-Functional Requirements

### Performance
- Image processing should complete in < 2 seconds locally
- API calls should timeout after 30 seconds with error handling
- UI should remain responsive during API calls (use async/threading)

### Usability
- Clear visual feedback for all operations
- Undo/redo support for polish iterations
- Keyboard shortcuts for common actions
- Tooltips on all buttons/controls

### Reliability
- Validate API key before first use
- Handle network failures gracefully
- Auto-save work in progress
- Prevent data loss on Godot editor crash

### Security
- Store API key encrypted in Godot's project settings
- Never log API key to console
- Warn users about API costs before generation

## Future Enhancements (Out of Scope for v1.0)

- Batch generation mode (generate multiple variations at once)
- Animation frame generation (sprite sheets)
- Style transfer from existing pixel art
- Collaborative template sharing/marketplace
- Integration with asset library
- Auto-tagging and organization
- Version control integration
- Direct sprite import to AnimatedSprite nodes

## Success Metrics

- Time to generate usable pixel art asset: < 2 minutes (including polish iterations)
- User satisfaction: 4+ stars on Godot Asset Library
- Template reusability: Average 5+ generations per template
- Polish usage: 60%+ of users use polish feature

## Timeline Estimate

- **Phase 1**: Core plugin structure, UI layout (1 week)
- **Phase 2**: Gemini API integration (3-4 days)
- **Phase 3**: Image processing pipeline (1 week)
- **Phase 4**: Template system (3-4 days)
- **Phase 5**: Polish & testing (1 week)

**Total**: ~4 weeks for MVP

## Open Questions

1. Should we support animated sprite generation (multiple frames)?
2. What's the maximum image resolution we should support?
3. Should templates be shareable/exportable between projects?
4. Do we need offline mode with cached results?
5. Should we support other AI providers as fallback?

## Appendix

### Reference Links
- [Gemini API Image Generation Docs](https://ai.google.dev/gemini-api/docs/image-generation)
- [Godot Plugin Documentation](https://docs.godotengine.com/en/stable/tutorials/plugins/editor/index.html)
- [Nano Banana Announcement](https://developers.googleblog.com/en/introducing-gemini-2-5-flash-image/)

### Terminology
- **Nano Banana**: Nickname for Gemini 2.5 Flash Image model
- **Template**: Combination of reference image + prompts + settings
- **Polish Pass**: Iterative refinement step using AI
- **Pixelation**: Downsampling to target pixel resolution
- **Palette Conformance**: Reducing image colors to match defined palette
