import { defineConfig } from 'vite';
import path from 'path';
import fg from 'fast-glob';

const htmlInputs = fg.sync(['src/index.html', 'src/demos/**/demo.html']).reduce((entries, file) => {
  const name = file
    .replace(/^src\//, '')         // z. B. demos/custom/demo.html
    .replace(/\.html$/, '')        // → demos/custom/demo
    .replace(/\//g, '_');          // → demos_custom_demo

  entries[name] = path.resolve(__dirname, file);
  return entries;
}, {} as Record<string, string>);

export default defineConfig({
  root: 'src',
  base: './',
  build: {
    outDir: '../dist',
    emptyOutDir: true,
    rollupOptions: {
      input: htmlInputs
    }
  }
});