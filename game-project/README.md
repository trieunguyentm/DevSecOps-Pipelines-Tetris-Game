# Tetris React

A classic Tetris game built with React JS.

## Features

- Classic Tetris gameplay with all 7 tetrominoes (I, J, L, O, S, T, Z)
- Ghost piece preview showing where the piece will land
- Next piece queue (3 upcoming pieces)
- Score, level, and line tracking
- Increasing speed as levels progress
- Wall kick rotation system
- Pause/Resume functionality
- Beautiful neon-themed UI with glow effects
- Responsive design

## Controls

| Key | Action |
|-----|--------|
| ← → | Move left/right |
| ↑ | Rotate |
| ↓ | Soft drop |
| Space | Hard drop |
| P | Pause/Resume |
| Enter | Start game |

## Getting Started

### Local Development

```bash
npm install
npm start
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Build for Production

```bash
npm run build
```

### Docker

Build and run with Docker:

```bash
docker build -t tetris-react .
docker run -p 8080:80 tetris-react
```

Open [http://localhost:8080](http://localhost:8080) in your browser.

## Tech Stack

- **React 18** - UI framework
- **CSS3** - Custom styling with gradients and glow effects
- **Nginx** - Production web server (Docker)
- **Docker** - Containerization with multi-stage build
