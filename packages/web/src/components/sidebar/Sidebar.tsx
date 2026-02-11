'use client'

import { UserTypeSelector } from './UserTypeSelector'
import { DestinationPicker } from './DestinationPicker'
import { VisitDurationPicker } from './VisitDurationPicker'
import { RecommendationList } from './RecommendationList'
import { TramInfo } from './TramInfo'
import { MobileBottomSheet } from './MobileBottomSheet'
import { useMediaQuery } from '@/lib/hooks'

export function Sidebar() {
  const isMobile = useMediaQuery('(max-width: 768px)')

  const content = (
    <div className="flex flex-col gap-4 p-4">
      <UserTypeSelector />
      <DestinationPicker />
      <VisitDurationPicker />
      <RecommendationList />
      <TramInfo />
    </div>
  )

  if (isMobile) {
    return <MobileBottomSheet>{content}</MobileBottomSheet>
  }

  return (
    <aside className="w-[380px] h-full overflow-y-auto border-r border-stone-100 bg-gradient-to-b from-white to-stone-50 shrink-0 z-10 scrollbar-thin scrollbar-thumb-stone-200 scrollbar-track-transparent">
      {content}
    </aside>
  )
}
