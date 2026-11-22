import { useEffect, useMemo, useState } from 'react';
import { Check, Copy } from 'lucide-react';
import {
  formatByteSize,
  GodotFileEntry,
  TokenKind,
  tokenizeLine,
} from '../utils/godotFiles';

interface CodeViewerProps {
  file: GodotFileEntry | null;
}

const TOKEN_CLASSES: Record<TokenKind, string> = {
  plain: 'text-slate-200',
  keyword: 'text-sky-400 font-medium',
  type: 'text-emerald-300',
  annotation: 'text-amber-300',
  string: 'text-amber-200',
  number: 'text-violet-300',
  comment: 'text-slate-500 italic',
  section: 'text-sky-300 font-semibold',
  property: 'text-cyan-300',
  heading: 'text-sky-300 font-semibold',
};

export function CodeViewer({ file }: CodeViewerProps) {
  const [copiedPath, setCopiedPath] = useState<string | null>(null);

  useEffect(() => {
    if (!copiedPath) return;
    const timer = window.setTimeout(() => setCopiedPath(null), 1800);
    return () => window.clearTimeout(timer);
  }, [copiedPath]);

  const lines = useMemo(() => {
    if (!file) return [];
    return file.content.split(/\r?\n/);
  }, [file]);

  if (!file) {
    return (
      <div className="flex flex-1 items-center justify-center p-8 text-sm text-slate-400">
        Выберите файл из списка слева для просмотра кода.
      </div>
    );
  }

  const isCopied = copiedPath === file.path;

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(file.content);
      setCopiedPath(file.path);
    } catch {
      const textarea = document.createElement('textarea');
      textarea.value = file.content;
      textarea.setAttribute('readonly', '');
      textarea.style.position = 'fixed';
      textarea.style.opacity = '0';
      document.body.appendChild(textarea);
      textarea.select();
      document.execCommand('copy');
      document.body.removeChild(textarea);
      setCopiedPath(file.path);
    }
  };

  return (
    <div className="flex min-h-0 min-w-0 flex-1 flex-col bg-slate-950">
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-800 bg-slate-900/40 px-4 py-3 md:px-6">
        <div className="min-w-0 space-y-0.5">
          <h2 className="truncate font-mono text-sm font-semibold text-slate-100">
            res://{file.path}
          </h2>
          <div className="flex items-center gap-2 text-xs text-slate-400 tabular-nums">
            <span>{file.languageLabel}</span>
            <span aria-hidden="true">·</span>
            <span>{file.lineCount} строк</span>
            <span aria-hidden="true">·</span>
            <span>{formatByteSize(file.byteSize)}</span>
          </div>
        </div>

        <button
          type="button"
          onClick={handleCopy}
          className={`inline-flex h-10 items-center gap-2 rounded-lg px-4 text-xs font-medium transition-colors whitespace-nowrap shrink-0 focus-visible:outline-2 focus-visible:outline-sky-400 ${
            isCopied
              ? 'bg-emerald-600 text-white'
              : 'bg-sky-500 text-slate-950 hover:bg-sky-400'
          }`}
        >
          {isCopied ? (
            <>
              <Check className="h-3.5 w-3.5" aria-hidden="true" />
              <span>Скопировано</span>
            </>
          ) : (
            <>
              <Copy className="h-3.5 w-3.5" aria-hidden="true" />
              <span>Копировать</span>
            </>
          )}
        </button>
      </div>

      <div className="min-h-0 flex-1 overflow-auto">
        <pre className="min-w-full py-4 font-mono text-[13px] leading-6">
          <code>
            {lines.map((lineText, idx) => {
              const tokens = tokenizeLine(lineText, file.language);
              return (
                <div
                  key={idx}
                  className="flex px-4 hover:bg-slate-900/60 md:px-6"
                >
                  <span
                    aria-hidden="true"
                    className="mr-5 w-9 shrink-0 select-none text-right text-slate-600 tabular-nums"
                  >
                    {idx + 1}
                  </span>
                  <span className="whitespace-pre">
                    {tokens.map((token, tIdx) => (
                      <span key={tIdx} className={TOKEN_CLASSES[token.kind]}>
                        {token.text}
                      </span>
                    ))}
                    {lineText.length === 0 ? ' ' : null}
                  </span>
                </div>
              );
            })}
          </code>
        </pre>
      </div>
    </div>
  );
}
