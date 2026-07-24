import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Static build, relative paths so it can be hosted anywhere.
export default defineConfig({
  base: './',
  plugins: [react()],
})
