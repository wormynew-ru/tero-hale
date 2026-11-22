import {
  ChevronDown,
  ChevronRight,
  FileCode2,
  FileText,
  Folder,
  FolderOpen,
  Search,
  X,
} from 'lucide-react';
import {
  FileExtensionFilter,
  FileTreeNode,
  GodotFileEntry,
} from '../utils/godotFiles';

interface FileTreeSidebarProps {
  tree: FileTreeNode[];
  selectedPath: string;
  searchQuery: string;
  extFilter: FileExtensionFilter;
  totalCount: number;
  filteredCount: number;
  expandedFolders: Record<string, boolean>;
  onSelectFile: (file: GodotFileEntry) => void;
  onSearchChange: (value: string) => void;
  onFilterChange: (filter: FileExtensionFilter) => void;
  onToggleFolder: (folderPath: string) => void;
  onResetFilters: () => void;
}

const FILTER_OPTIONS: { id: FileExtensionFilter; label: string }[] = [
  { id: 'all', label: 'Все' },
  { id: 'gd', label: '.gd' },
  { id: 'tscn', label: '.tscn' },
  { id: 'tres', label: '.tres' },
  { id: 'md', label: '.md' },
];

export function FileTreeSidebar({
  tree,
  selectedPath,
  searchQuery,
  extFilter,
  totalCount,
  filteredCount,
  expandedFolders,
  onSelectFile,
  onSearchChange,
  onFilterChange,
  onToggleFolder,
  onResetFilters,
}: FileTreeSidebarProps) {
  return (
    <div className="flex h-full flex-col bg-slate-900/60">
      <div className="border-b border-slate-800 p-3.5 space-y-3">
        <div className="flex items-center justify-between gap-2 text-xs text-slate-400">
          <span className="font-medium text-slate-200">godot_project/</span>
          <span className="font-mono tabular-nums">
            {filteredCount} / {totalCount}
          </span>
        </div>

        <div className="relative">
          <Search
            className="pointer-events-none absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-slate-500"
            aria-hidden="true"
          />
          <input
            type="search"
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
            placeholder="Поиск файла..."
            aria-label="Поиск файла в проекте Godot"
            className="h-9 w-full rounded-lg border border-slate-800 bg-slate-950 pl-8 pr-8 text-xs text-slate-100 placeholder:text-slate-500 focus:border-sky-500 focus:outline-none"
          />
          {searchQuery && (
            <button
              type="button"
              onClick={() => onSearchChange('')}
              aria-label="Очистить поиск"
              className="absolute right-1.5 top-1/2 flex h-6 w-6 -translate-y-1/2 items-center justify-center rounded text-slate-400 hover:bg-slate-800 hover:text-slate-100"
            >
              <X className="h-3.5 w-3.5" aria-hidden="true" />
            </button>
          )}
        </div>

        <div
          role="group"
          aria-label="Фильтр по типу файлов"
          className="grid grid-cols-5 gap-1 rounded-lg bg-slate-950 p-1"
        >
          {FILTER_OPTIONS.map((option) => {
            const active = extFilter === option.id;
            return (
              <button
                key={option.id}
                type="button"
                onClick={() => onFilterChange(option.id)}
                aria-pressed={active}
                className={`h-7 rounded-md px-1.5 text-xs font-medium transition-colors whitespace-nowrap shrink-0 focus-visible:outline-2 focus-visible:outline-sky-400 ${
                  active
                    ? 'bg-slate-800 text-sky-300'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                {option.label}
              </button>
            );
          })}
        </div>
      </div>

      <nav
        aria-label="Файлы проекта Godot"
        className="flex-1 overflow-y-auto px-2 py-2.5"
      >
        {tree.length === 0 ? (
          <div className="px-3 py-8 text-center">
            <p className="text-xs text-slate-400">
              Файлы по текущему фильтру не найдены.
            </p>
            <button
              type="button"
              onClick={onResetFilters}
              className="mt-3 inline-flex h-9 items-center rounded-lg border border-slate-700 bg-slate-900 px-3 text-xs font-medium text-slate-200 hover:bg-slate-800 whitespace-nowrap"
            >
              Сбросить фильтр
            </button>
          </div>
        ) : (
          <ul className="space-y-0.5">
            {tree.map((node) => (
              <TreeNodeItem
                key={node.path}
                node={node}
                depth={0}
                selectedPath={selectedPath}
                expandedFolders={expandedFolders}
                forceExpand={Boolean(searchQuery.trim() || extFilter !== 'all')}
                onSelectFile={onSelectFile}
                onToggleFolder={onToggleFolder}
              />
            ))}
          </ul>
        )}
      </nav>
    </div>
  );
}

interface TreeNodeItemProps {
  node: FileTreeNode;
  depth: number;
  selectedPath: string;
  expandedFolders: Record<string, boolean>;
  forceExpand: boolean;
  onSelectFile: (file: GodotFileEntry) => void;
  onToggleFolder: (folderPath: string) => void;
}

function TreeNodeItem({
  node,
  depth,
  selectedPath,
  expandedFolders,
  forceExpand,
  onSelectFile,
  onToggleFolder,
}: TreeNodeItemProps) {
  const paddingLeft = 10 + depth * 14;

  if (node.type === 'folder') {
    const isExpanded = forceExpand || expandedFolders[node.path] !== false;
    return (
      <li>
        <button
          type="button"
          onClick={() => onToggleFolder(node.path)}
          aria-expanded={isExpanded}
          style={{ paddingLeft: `${paddingLeft}px` }}
          className="flex min-h-[40px] md:min-h-[30px] w-full items-center gap-1.5 rounded-md pr-2 text-left text-xs font-medium text-slate-300 transition-colors hover:bg-slate-800/70 hover:text-slate-100 focus-visible:outline-2 focus-visible:outline-sky-400"
        >
          {isExpanded ? (
            <ChevronDown className="h-3.5 w-3.5 shrink-0 text-slate-500" aria-hidden="true" />
          ) : (
            <ChevronRight className="h-3.5 w-3.5 shrink-0 text-slate-500" aria-hidden="true" />
          )}
          {isExpanded ? (
            <FolderOpen className="h-3.5 w-3.5 shrink-0 text-amber-400/90" aria-hidden="true" />
          ) : (
            <Folder className="h-3.5 w-3.5 shrink-0 text-amber-400/80" aria-hidden="true" />
          )}
          <span className="truncate">{node.name}</span>
        </button>
        {isExpanded && node.children && node.children.length > 0 && (
          <ul className="space-y-0.5">
            {node.children.map((child) => (
              <TreeNodeItem
                key={child.path}
                node={child}
                depth={depth + 1}
                selectedPath={selectedPath}
                expandedFolders={expandedFolders}
                forceExpand={forceExpand}
                onSelectFile={onSelectFile}
                onToggleFolder={onToggleFolder}
              />
            ))}
          </ul>
        )}
      </li>
    );
  }

  const file = node.file!;
  const isSelected = file.path === selectedPath;
  const isDoc = file.extension === 'md';

  return (
    <li>
      <button
        type="button"
        onClick={() => onSelectFile(file)}
        aria-current={isSelected ? 'page' : undefined}
        style={{ paddingLeft: `${paddingLeft + 14}px` }}
        className={`flex min-h-[40px] md:min-h-[30px] w-full items-center gap-2 rounded-md pr-2.5 text-left text-xs transition-colors focus-visible:outline-2 focus-visible:outline-sky-400 ${
          isSelected
            ? 'bg-sky-500/15 font-medium text-sky-300'
            : 'text-slate-300 hover:bg-slate-800/60 hover:text-slate-100'
        }`}
      >
        {isDoc ? (
          <FileText
            className={`h-3.5 w-3.5 shrink-0 ${isSelected ? 'text-sky-400' : 'text-slate-500'}`}
            aria-hidden="true"
          />
        ) : (
          <FileCode2
            className={`h-3.5 w-3.5 shrink-0 ${isSelected ? 'text-sky-400' : 'text-slate-500'}`}
            aria-hidden="true"
          />
        )}
        <span className="truncate font-mono text-[12px]">{node.name}</span>
      </button>
    </li>
  );
}
