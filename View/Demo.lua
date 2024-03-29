Scorpio "MeowMeow.View.Demo" ""

import "MeowMeow.Layout"
import "MeowMeow.Layout.Widget"

linearLayout = FrameLayout("TextLinearLayout", UIParent, "BackdropTemplate")
linearLayout:SetBackdrop(BACKDROP_CHARACTER_CREATE_TOOLTIP_32_32)
linearLayout.LayoutParams = { gravity = Gravity.CENTER_HORIZONTAL + Gravity.CENTER_VERTICAL }
linearLayout.Padding = 20
linearLayout.Width = 800
linearLayout.Height = 800
linearLayout.Orientation = Orientation.VERTICAL
linearLayout:SetPoint("TOPLEFT")


textView = TextView("TextView")
textView:SetText("测试测试测试测试")
textView.PaddingStart = 20
textView.MarginStart = 15
-- textView.LayoutParams = { gravity = Gravity.CENTER_HORIZONTAL + Gravity.CENTER_VERTICAL }

textView2 = TextView("TextView2", linearLayout)
textView2:SetText("22222222222222222222222222222222222222")
textView2.Padding = 20
textView2:SetNonSpaceWrap(true)
textView2.MarginStart = 10
textView2.Width = 100
textView2.LayoutParams = { gravity = Gravity.CENTER_HORIZONTAL + Gravity.CENTER_VERTICAL }

textView3 = TextView("TextView3", linearLayout)
textView3:SetText("3333333333333333333333333333333333333")
textView3:SetNonSpaceWrap(true)
textView3.MarginStart = 10
textView3.Width = 100

-- linearLayout:AddView(textView)
-- linearLayout:AddView(textView2)
-- linearLayout:AddView(textView3)

Delay(15, function()
    print(textView:GetLeft(), textView:GetTop(), textView:GetRight(), textView:GetBottom())
end)

-- Delay(20, function()
--     print(imageView:GetFrameStrata(), imageView:GetFrameLevel(), imageView.FrameStrata)
-- end)