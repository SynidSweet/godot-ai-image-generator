# Godot AI Pixel Art Generator

A Godot Engine plugin that generates pixel art game assets using Google's Gemini 2.5 Flash Image API (Nano Banana).

## Features

- 🎨 **Template System**: Create reusable templates for different asset types (NPCs, furniture, props)
- 🤖 **AI-Powered Generation**: Leverage Gemini 2.5 Flash Image for high-quality image generation
- 🎯 **Multi-Step Pipeline**:
  1. Automatic color palette conformance
  2. AI image generation
  3. Pixelation to target resolution
  4. Optional iterative polish passes
- 🖼️ **Visual Pipeline**: See each processing stage in the UI
- 💾 **Direct Export**: Save generated assets directly to your project
- ♻️ **Iterative Refinement**: Polish and refine with undo/redo support

## Requirements

- **Godot Engine**: 4.0 or higher
- **Google Gemini API Key**: Get one at [Google AI Studio](https://ai.google.dev/)
- **Internet Connection**: Required for API calls

## Installation

### From Godot Asset Library (Coming Soon)
1. Open Godot Editor
2. Go to AssetLib tab
3. Search for "AI Pixel Art Generator"
4. Click Download and Install

### Manual Installation
1. Download the latest release from [GitHub Releases](https://github.com/yourusername/godot-ai-image-generator/releases)
2. Extract the `addons/ai_pixel_art_generator/` folder to your project's `addons/` directory
3. Enable the plugin in Project → Project Settings → Plugins

## Setup

1. **Enable the Plugin**
   - Go to Project → Project Settings → Plugins
   - Find "AI Pixel Art Generator" and check Enable

2. **Configure API Key**
   - Open the plugin panel (bottom dock)
   - Click Settings
   - Enter your Gemini API key
   - Click Validate to test connection

3. **Create Your First Template**
   - Click "New Template"
   - Upload a reference image
   - Write a base prompt (e.g., "pixel art character, 32x32, top-down view")
   - Select a color palette (DB32, AAP-64, or custom)
   - Set target resolution
   - Save template

## Usage

1. **Select a Template**: Choose from your saved templates
2. **Add Details**: Enter specific details in the detail prompt (e.g., "blue shirt, red hat")
3. **Generate**: Click Generate to start the pipeline
4. **Review Stages**: Watch as your image is processed through each stage
5. **Polish (Optional)**: Click Polish to refine the result iteratively
6. **Save**: Enter a filename and save to your project

## API Costs

Gemini 2.5 Flash Image pricing: ~$0.039 per image (~1290 output tokens at $30/million tokens)

The plugin displays estimated costs before generation.

## Development Setup

### Prerequisites
- Godot Engine 4.x
- Git
- GUT (Godot Unit Test) - included in the project

### Clone and Setup
```bash
git clone https://github.com/yourusername/godot-ai-image-generator.git
cd godot-ai-image-generator

# Open project in Godot
godot --editor project.godot
```

### Running Tests
1. Open Godot Editor
2. Go to the GUT panel (bottom dock)
3. Click "Run All Tests"

Or via command line:
```bash
# Run tests from command line (requires GUT CLI setup)
godot -s addons/gut/gut_cmdln.gd -gtest=res://test/
```

### Project Structure
```
godot-ai-image-generator/
├── addons/
│   ├── ai_pixel_art_generator/    # Main plugin
│   │   ├── plugin.cfg
│   │   ├── plugin.gd
│   │   ├── core/                   # Core logic
│   │   ├── models/                 # Data models
│   │   ├── api/                    # Gemini API client
│   │   ├── storage/                # File I/O
│   │   ├── services/               # Business logic
│   │   ├── ui/                     # User interface
│   │   └── data/                   # Preset palettes
│   └── gut/                        # GUT testing framework
├── test/
│   ├── unit/                       # Unit tests
│   └── integration/                # Integration tests
├── PRD.md                          # Product Requirements
├── IMPLEMENTATION_PLAN.md          # Development plan
└── README.md                       # This file
```

### Coding Standards
- Follow [Godot GDScript Style Guide](https://docs.godotengine.com/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- Use static typing everywhere
- Write tests before implementation (TDD)
- Document public APIs with comments
- Keep functions small and focused

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) file for details

## Acknowledgments

- **Google Gemini Team**: For the amazing Nano Banana model
- **Godot Engine**: For the incredible game engine
- **DawnBringer**: For the DB32 palette
- **AAP-64**: For the AAP-64 palette

## Support

- 📖 [User Guide](USER_GUIDE.md)
- 🐛 [Report Issues](https://github.com/yourusername/godot-ai-image-generator/issues)
- 💬 [Discussions](https://github.com/yourusername/godot-ai-image-generator/discussions)

## Roadmap

See [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) for detailed development roadmap.

### Planned Features (v2.0+)
- Batch generation mode
- Animation frame generation
- Style transfer from existing pixel art
- Template marketplace
- Additional AI provider support

---

**⚠️ Note**: This plugin requires an active internet connection and a valid Google Gemini API key. API usage is subject to Google's pricing and terms of service.
