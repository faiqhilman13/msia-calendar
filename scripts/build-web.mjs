// Copies the web app into www/, the folder Capacitor packages into the iOS and Android apps.
// The repo root also holds studies/, netlify/ and the native projects, which must not ship.
import { cpSync, rmSync, mkdirSync, existsSync } from 'node:fs';

const FILES = ['index.html', 'design.css', 'styles.css', 'app.js', 'import.js', 'manifest.webmanifest', 'sw.js', 'data', 'assets', 'icons'];
rmSync('www', { recursive: true, force: true });
mkdirSync('www');
for (const f of FILES) {
  if (!existsSync(f)) throw new Error(`Missing ${f}`);
  cpSync(f, `www/${f}`, { recursive: true });
}
console.log(`www/ ready (${FILES.length} entries)`);
