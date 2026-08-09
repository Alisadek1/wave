import { useEffect, useRef } from 'react'

/**
 * Register global keyboard shortcuts.
 * Each shortcut: { key, ctrl?, alt?, shift?, allowInInput?, fn }
 * By default shortcuts are suppressed when a text input is focused.
 * Set allowInInput:true to fire regardless.
 */
export function useGlobalShortcuts(shortcuts) {
  const ref = useRef(shortcuts)
  ref.current = shortcuts

  useEffect(() => {
    const handler = (e) => {
      const tag = document.activeElement?.tagName?.toLowerCase()
      const type = document.activeElement?.type?.toLowerCase()
      const isTextInput =
        (tag === 'input' && !['checkbox', 'radio', 'button', 'submit', 'reset'].includes(type)) ||
        tag === 'textarea' ||
        !!document.activeElement?.isContentEditable

      for (const { key, ctrl = false, alt = false, shift = false, allowInInput = false, fn } of ref.current) {
        if (e.key !== key) continue
        if (ctrl !== (e.ctrlKey || e.metaKey)) continue
        if (alt !== e.altKey) continue
        if (shift !== e.shiftKey) continue
        if (!allowInInput && isTextInput) continue
        e.preventDefault()
        fn(e)
        break
      }
    }
    document.addEventListener('keydown', handler)
    return () => document.removeEventListener('keydown', handler)
  }, [])
}
