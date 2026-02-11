'use client'

import { useState, useRef, useCallback, type ReactNode, type TouchEvent, type MouseEvent } from 'react'

interface MobileBottomSheetProps {
  children: ReactNode
}

const SNAP_PEEK = 140
const SNAP_FULL_OFFSET = 56

function getSnapPoints() {
  if (typeof window === 'undefined') return [140, 400, 744]
  const vh = window.innerHeight
  return [SNAP_PEEK, vh * 0.5, vh - SNAP_FULL_OFFSET]
}

function closestSnap(y: number): number {
  const snaps = getSnapPoints()
  let closest = snaps[0] ?? SNAP_PEEK
  let minDist = Math.abs(y - closest)
  for (const snap of snaps) {
    const dist = Math.abs(y - snap)
    if (dist < minDist) {
      minDist = dist
      closest = snap
    }
  }
  return closest
}

export function MobileBottomSheet({ children }: MobileBottomSheetProps) {
  const [sheetHeight, setSheetHeight] = useState(SNAP_PEEK)
  const [isDragging, setIsDragging] = useState(false)
  const dragStartRef = useRef<{ y: number; height: number } | null>(null)

  const handleDragStart = useCallback(
    (clientY: number) => {
      setIsDragging(true)
      dragStartRef.current = { y: clientY, height: sheetHeight }
    },
    [sheetHeight]
  )

  const handleDragMove = useCallback((clientY: number) => {
    if (!dragStartRef.current) return
    const delta = dragStartRef.current.y - clientY
    const newHeight = Math.max(SNAP_PEEK, dragStartRef.current.height + delta)
    const maxHeight =
      typeof window !== 'undefined'
        ? window.innerHeight - SNAP_FULL_OFFSET
        : 744
    setSheetHeight(Math.min(newHeight, maxHeight))
  }, [])

  const handleDragEnd = useCallback(() => {
    setIsDragging(false)
    dragStartRef.current = null
    setSheetHeight((h) => closestSnap(h))
  }, [])

  function onTouchStart(e: TouchEvent) {
    const touch = e.touches[0]
    if (touch) handleDragStart(touch.clientY)
  }
  function onTouchMove(e: TouchEvent) {
    const touch = e.touches[0]
    if (touch) handleDragMove(touch.clientY)
  }
  function onTouchEnd() {
    handleDragEnd()
  }

  function onMouseDown(e: MouseEvent) {
    handleDragStart(e.clientY)
    function onMouseMove(ev: globalThis.MouseEvent) {
      handleDragMove(ev.clientY)
    }
    function onMouseUp() {
      handleDragEnd()
      window.removeEventListener('mousemove', onMouseMove)
      window.removeEventListener('mouseup', onMouseUp)
    }
    window.addEventListener('mousemove', onMouseMove)
    window.addEventListener('mouseup', onMouseUp)
  }

  const snaps = getSnapPoints()
  const isExpanded = sheetHeight > (snaps[0] ?? SNAP_PEEK) + 50

  return (
    <>
      {/* Backdrop */}
      <div
        className={`fixed inset-0 z-20 transition-all duration-300 ${
          isExpanded
            ? 'bg-black/20 pointer-events-auto'
            : 'bg-transparent pointer-events-none'
        }`}
        onClick={() => setSheetHeight(SNAP_PEEK)}
      />

      {/* Sheet */}
      <div
        className={`fixed bottom-0 left-0 right-0 bg-white rounded-t-2xl z-30
          border-t border-stone-100
          ${isDragging ? '' : 'transition-[height] duration-300 ease-[cubic-bezier(0.32,0.72,0,1)]'}
          ${isExpanded ? 'shadow-[0_-4px_6px_-1px_rgba(0,0,0,0.05)]' : 'shadow-2xl'}
        `}
        style={{ height: sheetHeight }}
      >
        {/* Drag handle */}
        <div
          className="flex items-center justify-center pt-3 pb-2 cursor-grab active:cursor-grabbing touch-none"
          onTouchStart={onTouchStart}
          onTouchMove={onTouchMove}
          onTouchEnd={onTouchEnd}
          onMouseDown={onMouseDown}
        >
          <div className="w-12 h-1.5 rounded-full bg-stone-300" />
        </div>

        {/* Content */}
        <div
          className="overflow-y-auto"
          style={{ height: sheetHeight - 36 }}
        >
          {children}
        </div>
      </div>
    </>
  )
}
