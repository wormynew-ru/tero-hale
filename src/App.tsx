import { useMemo, useState } from 'react';
import { Menu, X } from 'lucide-react';
import { CodeViewer } from './components/CodeViewer';
import { FileTreeSidebar } from './components/FileTreeSidebar';
import {
  LaunchGuideBanner,
  LaunchGuideRestoreButton,
} from './components/LaunchGuideBanner';
import {
  buildFileTree,
  FileExtensionFilter,
  filterGodotFiles,
  GodotFileEntry,
  normalizeGodotFiles,
} from './utils/godotFiles';

const RAW_GODOT_MODULES = import.meta.glob(
  '/godot_project/**/*.{gd,tscn,tres,md,godot,svg}',
  {
    query: '?raw',
    import: 'default',
    eager: true,
  }
) as Record<string, string>;

const QUICK_OPEN_FILES = [
  { path: 'CLAUDE.md', label: 'CLAUDE.md' },
  { path: 'ROADMAP.md', label: 'ROADMAP.md' },
  { path: 'scenes/Main.tscn', label: 'Main.tscn' },
  { path: 'scripts/GameManager.gd', label: 'GameManager.gd' },
];

export default function App() {
  const allFiles = useMemo(() => normalizeGodotFiles(RAW_GODOT_MODULES), []);

  const [selectedPath, setSelectedPath] = useState<string>(() => {
    const preferred = allFiles.find((f) => f.path === 'scripts/CombatSystem.gd');
    return preferred?.path ?? allFiles[0]?.path ?? '';
  });
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [extFilter, setExtFilter] = useState<FileExtensionFilter>('all');
  const [expandedFolders, setExpandedFolders] = useState<Record<string, boolean>>({});
  const [showGuide, setShowGuide] = useState<boolean>(true);
  const [mobileDrawerOpen, setMobileDrawerOpen] = useState<boolean>(false);

  const filteredFiles = useMemo(
    () => filterGodotFiles(allFiles, searchQuery, extFilter),
    [allFiles, searchQuery, extFilter]
  );

  const fileTree = useMemo(() => buildFileTree(filteredFiles), [filteredFiles]);

  const selectedFile = useMemo(
    () => allFiles.find((f) => f.path === selectedPath) ?? filteredFiles[0] ?? null,
    [allFiles, filteredFiles, selectedPath]
  );

  const handleSelectFile = (file: GodotFileEntry) => {
    setSelectedPath(file.path);
    setMobileDrawerOpen(false);
  };

  const handleQuickJump = (targetPath: string) => {
    const found = allFiles.find((f) => f.path === targetPath);
    if (found) {
      setSearchQuery('');
      setExtFilter('all');
      setSelectedPath(found.path);
      setMobileDrawerOpen(false);
    }
  };

  const handleToggleFolder = (folderPath: string) => {
    setExpandedFolders((prev) => ({
      ...prev,
      [folderPath]: prev[folderPath] === false,
    }));
  };

  const handleResetFilters = () => {
    setSearchQuery('');
    setExtFilter('all');
  };

  return (
    <div className="flex h-screen flex-col overflow-hidden bg-slate-950 text-slate-100">
      <header className="flex h-14 shrink-0 items-center justify-between gap-8 border-b border-slate-800 bg-slate-950 px-4 md:px-6">
        <a
          href="/"
          className="text-base font-bold tracking-tight text-slate-100 whitespace-nowrap shrink-0"
        >
          Hero Tale · Godot 4.7
        </a>

        <nav
          aria-label="Быстрый переход к ключевым файлам"
          className="hidden md:flex items-center gap-6 text-sm font-medium text-slate-400"
        >
          {QUICK_OPEN_FILES.map((item) => {
            const active = selectedFile?.path === item.path;
            return (
              <button
                key={item.path}
                type="button"
                onClick={() => handleQuickJump(item.path)}
                className={`transition-colors whitespace-nowrap shrink-0 focus-visible:outline-2 focus-visible:outline-sky-400 ${
                  active
                    ? 'text-sky-400 underline underline-offset-4'
                    : 'hover:text-slate-100'
                }`}
              >
                {item.label}
              </button>
            );
          })}
        </nav>

        <div className="flex items-center gap-3 shrink-0">
          {!showGuide ? (
            <LaunchGuideRestoreButton onClick={() => setShowGuide(true)} />
          ) : (
            <button
              type="button"
              onClick={() => handleQuickJump('project.godot')}
              className="inline-flex h-9 items-center rounded-lg border border-slate-700 bg-slate-900 px-3 text-xs font-medium text-slate-200 transition-colors hover:border-slate-600 hover:bg-slate-800 whitespace-nowrap shrink-0 focus-visible:outline-2 focus-visible:outline-sky-400"
            >
              project.godot
            </button>
          )}
        </div>
      </header>

      <LaunchGuideBanner isOpen={showGuide} onToggle={() => setShowGuide(false)} />

      <div className="flex items-center justify-between border-b border-slate-800 bg-slate-900/40 px-4 py-2 md:hidden">
        <button
          type="button"
          onClick={() => setMobileDrawerOpen((prev) => !prev)}
          aria-expanded={mobileDrawerOpen}
          className="inline-flex h-10 items-center gap-2 rounded-lg border border-slate-700 bg-slate-900 px-3 text-xs font-medium text-slate-100 whitespace-nowrap"
        >
          {mobileDrawerOpen ? (
            <X className="h-4 w-4 text-slate-400" aria-hidden="true" />
          ) : (
            <Menu className="h-4 w-4 text-sky-400" aria-hidden="true" />
          )}
          <span>Файлы проекта ({allFiles.length})</span>
        </button>
        <span className="truncate pl-3 font-mono text-xs text-slate-400">
          {selectedFile?.name ?? ''}
        </span>
      </div>

      <div className="relative flex min-h-0 flex-1 overflow-hidden">
        <aside
          aria-label="Дерево файлов проекта"
          className="hidden w-72 shrink-0 border-r border-slate-800 md:block"
        >
          <FileTreeSidebar
            tree={fileTree}
            selectedPath={selectedFile?.path ?? ''}
            searchQuery={searchQuery}
            extFilter={extFilter}
            totalCount={allFiles.length}
            filteredCount={filteredFiles.length}
            expandedFolders={expandedFolders}
            onSelectFile={handleSelectFile}
            onSearchChange={setSearchQuery}
            onFilterChange={setExtFilter}
            onToggleFolder={handleToggleFolder}
            onResetFilters={handleResetFilters}
          />
        </aside>

        {mobileDrawerOpen && (
          <div className="absolute inset-0 z-30 flex md:hidden">
            <aside className="h-full w-72 max-w-[85vw] border-r border-slate-800 bg-slate-950 shadow-xl">
              <FileTreeSidebar
                tree={fileTree}
                selectedPath={selectedFile?.path ?? ''}
                searchQuery={searchQuery}
                extFilter={extFilter}
                totalCount={allFiles.length}
                filteredCount={filteredFiles.length}
                expandedFolders={expandedFolders}
                onSelectFile={handleSelectFile}
                onSearchChange={setSearchQuery}
                onFilterChange={setExtFilter}
                onToggleFolder={handleToggleFolder}
                onResetFilters={handleResetFilters}
              />
            </aside>
            <button
              type="button"
              aria-label="Закрыть панель файлов"
              onClick={() => setMobileDrawerOpen(false)}
              className="flex-1 bg-black/50"
            />
          </div>
        )}

        <main className="flex min-h-0 min-w-0 flex-1 flex-col">
          <CodeViewer file={selectedFile} />
        </main>
      </div>
    </div>
  );
}
