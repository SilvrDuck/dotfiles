'use strict';

/*
 * Note Aliases Auto-Save
 *
 * Two complementary flows:
 *
 * 1. editor-change (debounced): when the cursor sits just past a freshly
 *    completed `[[Target|Alias]]` and Target already exists, append `Alias`
 *    to Target's frontmatter `aliases:`. Skips silently if the target is
 *    missing — we don't surprise-create files from typing.
 *
 * 2. vault create (post-resolve): when a new note is born — typically by
 *    clicking an aliased link that pointed to a not-yet-existing note —
 *    scan the metadata cache for every aliased inbound link and write all
 *    of them into the new note's frontmatter at once. This catches the
 *    multi-source case where A had `[[B|foo]]` and C had `[[B|bar]]`
 *    before B existed; both aliases land when B is finally created.
 *
 * The vault-create handler is registered inside `workspace.onLayoutReady`
 * so it doesn't fire for every existing file at startup (Obsidian replays
 * `vault.on('create')` for the whole vault on load), and the scan runs
 * only after the next `metadataCache.on('resolved')` so resolvedLinks is
 * up-to-date for the newly created file.
 *
 * Uses only stable obsidian exports — no @codemirror/view import.
 *
 * Companion to pulsovi/obsidian-note-aliases, which provides the manual
 * "save alias" command. This plugin does not depend on that one at runtime.
 */

const {
  Plugin,
  TFile,
  parseFrontMatterAliases,
  debounce,
} = require('obsidian');

const WIKILINK_RE = /\[\[(?<target>[^[|#]*)(?:#[^[|]*)?\|(?<alias>[^\]]*)\]\]/gu;
const DEBOUNCE_MS = 250;
const LOG_TAG = '[note-aliases-autosave]';

class NoteAliasesAutosavePlugin extends Plugin {
  async onload() {
    this._lastSavedKey = '';
    this._handleChange = debounce(this._handleChange.bind(this), DEBOUNCE_MS, true);

    this.registerEvent(
      this.app.workspace.on('editor-change', (editor, info) => {
        this._handleChange(editor, info);
      })
    );

    this.app.workspace.onLayoutReady(() => {
      this.registerEvent(
        this.app.vault.on('create', (file) => {
          if (!(file instanceof TFile) || file.extension !== 'md') return;
          this._scheduleBackfill(file);
        })
      );
    });
  }

  _scheduleBackfill(targetFile) {
    const ref = this.app.metadataCache.on('resolved', () => {
      this.app.metadataCache.offref(ref);
      this._backfillAliasesFromInboundLinks(targetFile).catch((err) =>
        console.error(LOG_TAG, err)
      );
    });
    this.registerEvent(ref);
  }

  async _handleChange(editor, info) {
    try {
      await this._maybeSaveAlias(editor, info);
    } catch (err) {
      console.error(LOG_TAG, err);
    }
  }

  async _maybeSaveAlias(editor, info) {
    const sourceFile = info?.file;
    if (!sourceFile) return;

    const cursor = editor.getCursor();
    const line = editor.getLine(cursor.line);

    if (!line.slice(0, cursor.ch).endsWith(']]')) return;

    const link = this._linkContaining(line, cursor.ch);
    if (!link || !link.alias) return;

    const dedupKey = [
      sourceFile.path,
      cursor.line,
      link.start,
      link.target,
      link.alias,
    ].join('\x1f');
    if (dedupKey === this._lastSavedKey) return;
    this._lastSavedKey = dedupKey;

    const targetFile = this.app.metadataCache.getFirstLinkpathDest(
      link.target,
      sourceFile.path
    );
    if (!targetFile || targetFile.extension !== 'md') return;
    if (targetFile.path === sourceFile.path) return;

    await this.app.fileManager.processFrontMatter(targetFile, (frontmatter) => {
      const existing = parseFrontMatterAliases(frontmatter) ?? [];
      if (existing.includes(link.alias)) return;
      frontmatter.aliases = [...existing, link.alias];
    });
  }

  async _backfillAliasesFromInboundLinks(targetFile) {
    const { metadataCache, vault } = this.app;
    const aliases = new Set();

    for (const [sourcePath, destinations] of Object.entries(metadataCache.resolvedLinks)) {
      if (sourcePath === targetFile.path) continue;
      if (!destinations[targetFile.path]) continue;
      const sourceFile = vault.getAbstractFileByPath(sourcePath);
      if (!(sourceFile instanceof TFile)) continue;

      const cache = metadataCache.getFileCache(sourceFile);
      const refs = [
        ...(cache?.links ?? []),
        ...(cache?.frontmatterLinks ?? []),
      ];
      for (const link of refs) {
        if (!link.displayText) continue;
        const resolved = metadataCache.getFirstLinkpathDest(link.link, sourcePath);
        if (resolved?.path === targetFile.path) aliases.add(link.displayText);
      }
    }

    if (aliases.size === 0) return;

    try {
      await this.app.fileManager.processFrontMatter(targetFile, (frontmatter) => {
        const existing = new Set(parseFrontMatterAliases(frontmatter) ?? []);
        let changed = false;
        for (const alias of aliases) {
          if (!existing.has(alias)) {
            existing.add(alias);
            changed = true;
          }
        }
        if (changed) frontmatter.aliases = [...existing];
      });
    } catch (err) {
      console.error(LOG_TAG, 'backfill failed', err);
    }
  }

  _linkContaining(line, ch) {
    for (const match of line.matchAll(WIKILINK_RE)) {
      const start = match.index ?? 0;
      const end = start + match[0].length;
      if (start <= ch && end >= ch) {
        const { target, alias } = match.groups;
        return { target, alias, start, end };
      }
    }
    return null;
  }
}

module.exports = NoteAliasesAutosavePlugin;
