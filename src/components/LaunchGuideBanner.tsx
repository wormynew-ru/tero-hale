import { ChevronDown, ChevronUp } from 'lucide-react';

interface LaunchGuideBannerProps {
  isOpen: boolean;
  onToggle: () => void;
}

export function LaunchGuideBanner({ isOpen, onToggle }: LaunchGuideBannerProps) {
  if (!isOpen) {
    return null;
  }

  return (
    <section
      aria-label="Памятка по запуску в Godot 4.7"
      className="border-b border-slate-800 bg-slate-900/70 px-4 py-2.5 md:px-6"
    >
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0 space-y-1 text-sm text-slate-300">
          <p className="text-xs font-semibold text-slate-100 md:text-sm">
            Запуск стартового MVP в Godot Engine 4.7 (ПК и мобильные устройства)
          </p>
          <ol className="flex flex-col gap-0.5 text-xs text-slate-400 lg:flex-row lg:flex-wrap lg:items-center lg:gap-x-5">
            <li>
              <span className="font-mono text-slate-200">1.</span> Откройте Godot 4.7 →{' '}
              <span className="font-mono text-slate-200">Import</span> →{' '}
              <span className="font-mono text-sky-300">godot_project/project.godot</span>
            </li>
            <li>
              <span className="font-mono text-slate-200">2.</span> Нажмите{' '}
              <span className="font-mono text-slate-200">F5</span> (сцена{' '}
              <span className="font-mono text-sky-300">res://scenes/Main.tscn</span>)
            </li>
            <li>
              <span className="font-mono text-slate-200">3.</span> Правила и карта файлов:{' '}
              <span className="font-mono text-sky-300">CLAUDE.md</span> и{' '}
              <span className="font-mono text-sky-300">ROADMAP.md</span>
            </li>
          </ol>
        </div>
        <button
          type="button"
          onClick={onToggle}
          aria-label="Свернуть памятку по запуску"
          className="inline-flex h-8 shrink-0 items-center gap-1 rounded-md px-2.5 text-xs font-medium text-slate-400 transition-colors hover:bg-slate-800 hover:text-slate-100 focus-visible:outline-2 focus-visible:outline-sky-400 whitespace-nowrap"
        >
          <span>Свернуть</span>
          <ChevronUp className="h-3.5 w-3.5" aria-hidden="true" />
        </button>
      </div>
    </section>
  );
}

export function LaunchGuideRestoreButton({ onClick }: { onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="inline-flex h-9 items-center gap-1.5 rounded-lg border border-slate-700 bg-slate-900 px-3 text-xs font-medium text-slate-200 transition-colors hover:border-slate-600 hover:bg-slate-800 focus-visible:outline-2 focus-visible:outline-sky-400 whitespace-nowrap shrink-0"
    >
      <ChevronDown className="h-3.5 w-3.5 text-sky-400" aria-hidden="true" />
      <span>Памятка запуска</span>
    </button>
  );
}
