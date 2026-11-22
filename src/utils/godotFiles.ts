export type FileExtensionFilter = 'all' | 'gd' | 'tscn' | 'tres' | 'md';

export type SyntaxLanguage = 'gdscript' | 'godot-resource' | 'ini' | 'markdown' | 'svg' | 'text';

export interface GodotFileEntry {
  path: string;
  name: string;
  extension: string;
  content: string;
  lineCount: number;
  byteSize: number;
  language: SyntaxLanguage;
  languageLabel: string;
}

export interface FileTreeNode {
  type: 'folder' | 'file';
  name: string;
  path: string;
  children?: FileTreeNode[];
  file?: GodotFileEntry;
}

export type TokenKind =
  | 'plain'
  | 'keyword'
  | 'type'
  | 'annotation'
  | 'string'
  | 'number'
  | 'comment'
  | 'section'
  | 'property'
  | 'heading';

export interface SyntaxToken {
  text: string;
  kind: TokenKind;
}

const GDSCRIPT_KEYWORDS = new Set([
  'extends',
  'class_name',
  'func',
  'var',
  'const',
  'enum',
  'signal',
  'if',
  'elif',
  'else',
  'for',
  'while',
  'match',
  'return',
  'break',
  'continue',
  'pass',
  'and',
  'or',
  'not',
  'in',
  'is',
  'as',
  'true',
  'false',
  'null',
  'self',
  'super',
]);

const GDSCRIPT_TYPES = new Set([
  'void',
  'bool',
  'int',
  'float',
  'String',
  'Vector2',
  'Color',
  'Array',
  'Dictionary',
  'Node',
  'Control',
  'Resource',
  'Error',
  'Button',
  'Label',
  'ProgressBar',
  'RichTextLabel',
  'PanelContainer',
  'HBoxContainer',
  'VBoxContainer',
  'ScrollContainer',
  'TabContainer',
  'AspectRatioContainer',
  'TextureRect',
  'HFlowContainer',
  'ColorRect',
  'StyleBoxFlat',
  'Line2D',
  'PackedVector2Array',
  'PackedStringArray',
  'TextServer',
  'Engine',
  'ResourceSaver',
  'ResourceLoader',
  'GameManager',
  'CombatSystem',
  'ItemData',
  'CropData',
  'EnemyData',
  'LocationData',
  'SkillNodeData',
  'DarkSkillNodeData',
  'HeroClassData',
  'AbilityData',
  'PetData',
  'SaveData',
  'NumberFormatter',
]);

const ROOT_PRIORITY: Record<string, number> = {
  'CLAUDE.md': 1,
  'ROADMAP.md': 2,
  'CHANGELOG.md': 3,
  'TZ.md': 4,
  'project.godot': 5,
  'icon.svg': 6,
};

export function detectLanguage(filePath: string): { language: SyntaxLanguage; label: string } {
  const lower = filePath.toLowerCase();
  if (lower.endsWith('.gd')) {
    return { language: 'gdscript', label: 'GDScript' };
  }
  if (lower.endsWith('.tscn')) {
    return { language: 'godot-resource', label: 'Godot Scene' };
  }
  if (lower.endsWith('.tres')) {
    return { language: 'godot-resource', label: 'Godot Resource' };
  }
  if (lower.endsWith('.godot')) {
    return { language: 'ini', label: 'Godot Config' };
  }
  if (lower.endsWith('.md')) {
    return { language: 'markdown', label: 'Markdown' };
  }
  if (lower.endsWith('.svg')) {
    return { language: 'svg', label: 'SVG' };
  }
  return { language: 'text', label: 'Text' };
}

export function getFileExtension(filePath: string): string {
  const name = filePath.split('/').pop() ?? filePath;
  const dotIdx = name.lastIndexOf('.');
  if (dotIdx === -1) return '';
  return name.slice(dotIdx + 1).toLowerCase();
}

export function normalizeGodotFiles(rawModules: Record<string, string>): GodotFileEntry[] {
  const entries: GodotFileEntry[] = [];

  for (const [rawKey, content] of Object.entries(rawModules)) {
    const cleanedPath = rawKey.replace(/^\/?godot_project\//, '').replace(/^\.\.\/godot_project\//, '');
    if (!cleanedPath) continue;

    const name = cleanedPath.split('/').pop() ?? cleanedPath;
    const extension = getFileExtension(cleanedPath);
    const { language, label } = detectLanguage(cleanedPath);
    const normalizedContent = typeof content === 'string' ? content : String(content ?? '');
    const lineCount = normalizedContent.length === 0 ? 0 : normalizedContent.split(/\r?\n/).length;
    const byteSize = new TextEncoder().encode(normalizedContent).length;

    entries.push({
      path: cleanedPath,
      name,
      extension,
      content: normalizedContent,
      lineCount,
      byteSize,
      language,
      languageLabel: label,
    });
  }

  return entries.sort((a, b) => comparePaths(a.path, b.path));
}

function comparePaths(a: string, b: string): number {
  const aParts = a.split('/');
  const bParts = b.split('/');
  const aIsRoot = aParts.length === 1;
  const bIsRoot = bParts.length === 1;

  if (aIsRoot && bIsRoot) {
    const aPrio = ROOT_PRIORITY[a] ?? 99;
    const bPrio = ROOT_PRIORITY[b] ?? 99;
    if (aPrio !== bPrio) return aPrio - bPrio;
  }

  return a.localeCompare(b, 'en');
}

export function filterGodotFiles(
  files: GodotFileEntry[],
  query: string,
  extFilter: FileExtensionFilter
): GodotFileEntry[] {
  const normalizedQuery = query.trim().toLowerCase();

  return files.filter((file) => {
    if (extFilter !== 'all' && file.extension !== extFilter) {
      return false;
    }
    if (!normalizedQuery) {
      return true;
    }
    return (
      file.path.toLowerCase().includes(normalizedQuery) ||
      file.name.toLowerCase().includes(normalizedQuery)
    );
  });
}

export function buildFileTree(files: GodotFileEntry[]): FileTreeNode[] {
  const rootNodes: FileTreeNode[] = [];

  for (const file of files) {
    const parts = file.path.split('/');
    let currentLevel = rootNodes;
    let currentPath = '';

    for (let i = 0; i < parts.length; i++) {
      const part = parts[i];
      currentPath = currentPath ? `${currentPath}/${part}` : part;
      const isFile = i === parts.length - 1;

      if (isFile) {
        currentLevel.push({
          type: 'file',
          name: part,
          path: currentPath,
          file,
        });
      } else {
        let folderNode = currentLevel.find((node) => node.type === 'folder' && node.name === part);
        if (!folderNode) {
          folderNode = {
            type: 'folder',
            name: part,
            path: currentPath,
            children: [],
          };
          currentLevel.push(folderNode);
        }
        currentLevel = folderNode.children!;
      }
    }
  }

  sortTreeNodes(rootNodes);
  return rootNodes;
}

function sortTreeNodes(nodes: FileTreeNode[]): void {
  nodes.sort((a, b) => {
    if (a.type !== b.type) {
      return a.type === 'folder' ? -1 : 1;
    }
    if (a.type === 'file' && b.type === 'file') {
      const aPrio = ROOT_PRIORITY[a.path] ?? 99;
      const bPrio = ROOT_PRIORITY[b.path] ?? 99;
      if (aPrio !== bPrio) return aPrio - bPrio;
    }
    return a.name.localeCompare(b.name, 'en');
  });

  for (const node of nodes) {
    if (node.children) {
      sortTreeNodes(node.children);
    }
  }
}

export function formatByteSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} Б`;
  return `${(bytes / 1024).toFixed(1)} КБ`;
}

export function tokenizeLine(line: string, language: SyntaxLanguage): SyntaxToken[] {
  if (line.length === 0) {
    return [{ text: '', kind: 'plain' }];
  }

  if (language === 'markdown') {
    return tokenizeMarkdownLine(line);
  }
  if (language === 'godot-resource' || language === 'ini') {
    return tokenizeGodotConfigOrResourceLine(line);
  }
  if (language === 'gdscript') {
    return tokenizeGDScriptLine(line);
  }
  return [{ text: line, kind: 'plain' }];
}

function tokenizeMarkdownLine(line: string): SyntaxToken[] {
  if (/^\s*#{1,6}\s/.test(line)) {
    return [{ text: line, kind: 'heading' }];
  }
  if (/^\s*```/.test(line)) {
    return [{ text: line, kind: 'section' }];
  }
  if (/^\s*<!--/.test(line) || /^\s*-->/.test(line)) {
    return [{ text: line, kind: 'comment' }];
  }
  const tokens: SyntaxToken[] = [];
  const regex = /(`[^`]+`)/g;
  let lastIndex = 0;
  let match: RegExpExecArray | null;
  while ((match = regex.exec(line)) !== null) {
    if (match.index > lastIndex) {
      tokens.push({ text: line.slice(lastIndex, match.index), kind: 'plain' });
    }
    tokens.push({ text: match[0], kind: 'string' });
    lastIndex = match.index + match[0].length;
  }
  if (lastIndex < line.length) {
    tokens.push({ text: line.slice(lastIndex), kind: 'plain' });
  }
  return tokens.length > 0 ? tokens : [{ text: line, kind: 'plain' }];
}

function tokenizeGodotConfigOrResourceLine(line: string): SyntaxToken[] {
  const trimmed = line.trimStart();
  if (trimmed.startsWith(';')) {
    return [{ text: line, kind: 'comment' }];
  }
  if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
    return [{ text: line, kind: 'section' }];
  }

  const eqIdx = line.indexOf('=');
  if (eqIdx > 0 && !line.slice(0, eqIdx).includes('"')) {
    const keyPart = line.slice(0, eqIdx);
    const valPart = line.slice(eqIdx + 1);
    return [
      { text: keyPart, kind: 'property' },
      { text: '=', kind: 'plain' },
      ...tokenizeValueLiterals(valPart),
    ];
  }

  return tokenizeValueLiterals(line);
}

function tokenizeGDScriptLine(line: string): SyntaxToken[] {
  const tokens: SyntaxToken[] = [];
  let i = 0;

  while (i < line.length) {
    const ch = line[i];

    if (ch === '#') {
      tokens.push({ text: line.slice(i), kind: 'comment' });
      break;
    }

    if (ch === '"' || ch === "'") {
      const quote = ch;
      let j = i + 1;
      while (j < line.length) {
        if (line[j] === '\\') {
          j += 2;
          continue;
        }
        if (line[j] === quote) {
          j++;
          break;
        }
        j++;
      }
      tokens.push({ text: line.slice(i, j), kind: 'string' });
      i = j;
      continue;
    }

    if (ch === '@') {
      const rest = line.slice(i);
      const match = /^@[A-Za-z_][A-Za-z0-9_]*/.exec(rest);
      if (match) {
        tokens.push({ text: match[0], kind: 'annotation' });
        i += match[0].length;
        continue;
      }
    }

    if (ch === '%' || ch === '$') {
      const rest = line.slice(i);
      const match = /^[%$][A-Za-z_][A-Za-z0-9_/]*/.exec(rest);
      if (match) {
        tokens.push({ text: match[0], kind: 'property' });
        i += match[0].length;
        continue;
      }
    }

    if (/[0-9]/.test(ch)) {
      const rest = line.slice(i);
      const match = /^[0-9]+(\.[0-9]+)?/.exec(rest);
      if (match) {
        tokens.push({ text: match[0], kind: 'number' });
        i += match[0].length;
        continue;
      }
    }

    if (/[A-Za-z_]/.test(ch)) {
      const rest = line.slice(i);
      const match = /^[A-Za-z_][A-Za-z0-9_]*/.exec(rest);
      if (match) {
        const word = match[0];
        let kind: TokenKind = 'plain';
        if (GDSCRIPT_KEYWORDS.has(word)) {
          kind = 'keyword';
        } else if (GDSCRIPT_TYPES.has(word)) {
          kind = 'type';
        }
        tokens.push({ text: word, kind });
        i += word.length;
        continue;
      }
    }

    tokens.push({ text: ch, kind: 'plain' });
    i++;
  }

  return mergePlainTokens(tokens);
}

function tokenizeValueLiterals(input: string): SyntaxToken[] {
  const tokens: SyntaxToken[] = [];
  const regex = /("[^"]*"|\b(?:true|false|null)\b|\b(?:ExtResource|SubResource|Resource|Color|Vector2|Array|PackedStringArray)\b|\b-?\d+(?:\.\d+)?\b)/g;
  let lastIndex = 0;
  let match: RegExpExecArray | null;

  while ((match = regex.exec(input)) !== null) {
    if (match.index > lastIndex) {
      tokens.push({ text: input.slice(lastIndex, match.index), kind: 'plain' });
    }
    const val = match[0];
    let kind: TokenKind = 'plain';
    if (val.startsWith('"')) {
      kind = 'string';
    } else if (val === 'true' || val === 'false' || val === 'null') {
      kind = 'keyword';
    } else if (/^-?\d/.test(val)) {
      kind = 'number';
    } else {
      kind = 'type';
    }
    tokens.push({ text: val, kind });
    lastIndex = match.index + val.length;
  }

  if (lastIndex < input.length) {
    tokens.push({ text: input.slice(lastIndex), kind: 'plain' });
  }

  return tokens.length > 0 ? tokens : [{ text: input, kind: 'plain' }];
}

function mergePlainTokens(tokens: SyntaxToken[]): SyntaxToken[] {
  const merged: SyntaxToken[] = [];
  for (const token of tokens) {
    const prev = merged[merged.length - 1];
    if (prev && prev.kind === token.kind && token.kind === 'plain') {
      prev.text += token.text;
    } else {
      merged.push({ ...token });
    }
  }
  return merged;
}
