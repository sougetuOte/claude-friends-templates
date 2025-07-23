# Quickstart Media Guidelines

This document outlines recommendations for creating quickstart videos or GIF animations to help new users get started with Claude Friends Templates.

## Recommended Content

### 1. Setup Animation (30-60 seconds)
Show the following steps:
```
1. Clone the template
2. Run ./setup.sh
3. Enter project name
4. Choose language
5. See "Setup Complete!" message
```

### 2. First Agent Interaction (60-90 seconds)
Demonstrate:
```
1. Type /agent:planner
2. Planner greets user
3. User describes project idea
4. Planner creates requirements
5. Show the generated requirements.md
```

### 3. Agent Handoff Demo (30-60 seconds)
Show smooth transition:
```
1. Planner completes design
2. Type /agent:builder
3. Builder reads handover
4. Builder starts implementation
5. Show TDD cycle with 🔴→🟢→✅
```

## Technical Specifications

### For GIF Animations
- **Tool**: asciinema + svg-term-cli (recommended)
- **Resolution**: 800x600 or 1024x768
- **Frame rate**: 10-15 fps
- **File size**: < 5MB per GIF
- **Color scheme**: Match Claude Code theme

### For Videos
- **Format**: MP4 (H.264)
- **Resolution**: 1920x1080 or 1280x720
- **Duration**: 2-3 minutes total
- **Audio**: Optional voiceover or background music
- **Subtitles**: English and Japanese versions

## Recording Script Example

```bash
# Terminal recording script
asciinema rec demo.cast

# In the recording:
echo "Welcome to Claude Friends Templates!"
sleep 2
./setup.sh
# (interact with setup)
sleep 2
echo "Now let's start with the Planner agent..."
# (show agent interaction)

# Convert to GIF
svg-term --in demo.cast --out demo.svg --window
# Then convert SVG to GIF using online tools
```

## Placeholder Locations

Add media in these locations:
1. **README.md**: After the "See the Magic in Action" section
2. **Website/Docs**: Landing page hero section
3. **GitHub**: Repository social preview image

## Alternative: ASCII Art Demo

For immediate visual impact without media files:

```
┌─────────────────────────────────────┐
│  Claude Friends Setup               │
├─────────────────────────────────────┤
│  Project name: my-todo-app          │
│  Language: [1] English [2] Japanese │
│  > 1                                │
│                                     │
│  ✅ Setup complete!                 │
│  Ready to start with /agent:planner │
└─────────────────────────────────────┘
```

## Community Contributions

We welcome community-created demos! Guidelines:
- Keep it simple and focused
- Show real workflow, not just features
- Include both success and error handling
- Make it beginner-friendly

---
*Note: Actual media files are not included in the template to keep it lightweight. This document serves as a guide for creating them.*