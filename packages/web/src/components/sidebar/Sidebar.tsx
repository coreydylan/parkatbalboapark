'use client'

import { UserTypeSelector } from './UserTypeSelector'
import { DestinationPicker } from './DestinationPicker'
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
      <RecommendationList />
      <TramInfo />
    </div>
  )

  if (isMobile) {
    return <MobileBottomSheet>{content}</MobileBottomSheet>
  }

  return (
    <aside className="w-[380px] h-full overflow-y-auto border-r border-stone-200 bg-white shrink-0 z-10">
      {content}
    </aside>
  )
}
