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
 * `vault.on('create')` for the whole vault on load). The backfill itself
 * is deferred until the new file's metadata settles — see
 * `_scheduleBackfill` — so we don't race with concurrent on-create
 * plugins (Templater, QuickAdd, …) that write the file shortly after
 * its creation.
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

// After vault.on('create'), wait until the file's metadata has been quiet
// for this long before backfilling. Long enough to outlast Templater's own
// 300ms create-handler delay plus its template write.
const BACKFILL_SETTLE_MS = 500;

// Upper bound in case no metadataCache 'changed' event ever fires for the
// new file (e.g. no template plugin, file stays empty).
const BACKFILL_FALLBACK_MS = 3000;

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
    // Wait until the target file's metadata has settled before we touch its
    // frontmatter. Concurrent on-create plugins (Templater, QuickAdd, …)
    // typically write template content within the first few hundred ms after
    // creation; firing earlier produces a write race that mangles YAML.
    //
    // Strategy: each metadataCache 'changed' event for the target resets a
    // BACKFILL_SETTLE_MS debounce timer. A BACKFILL_FALLBACK_MS hard cap
    // covers the case where no other plugin writes the file and 'changed'
    // never fires.
    let fired = false;
    let settleTimer = null;
    let fallbackTimer = null;
    let changedRef = null;

    const fire = () => {
      if (fired) return;
      fired = true;
      if (settleTimer !== null) clearTimeout(settleTimer);
      if (fallbackTimer !== null) clearTimeout(fallbackTimer);
      if (changedRef) this.app.metadataCache.offref(changedRef);
      this._backfillAliasesFromInboundLinks(targetFile).catch((err) =>
        console.error(LOG_TAG, err)
      );
    };

    changedRef = this.app.metadataCache.on('changed', (file) => {
      if (file.path !== targetFile.path) return;
      if (settleTimer !== null) clearTimeout(settleTimer);
      settleTimer = setTimeout(fire, BACKFILL_SETTLE_MS);
    });
    this.registerEvent(changedRef);

    fallbackTimer = setTimeout(fire, BACKFILL_FALLBACK_MS);
    this.register(() => {
      if (settleTimer !== null) clearTimeout(settleTimer);
      if (fallbackTimer !== null) clearTimeout(fallbackTimer);
    });
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
