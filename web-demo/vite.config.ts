import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// base './' so the build works from any static path (GitHub Pages, file server).
export default defineConfig({ base: './', plugins: [react()] })
