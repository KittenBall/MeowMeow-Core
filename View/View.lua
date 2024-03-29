PLoop(function()

    namespace "MeowMeow.Layout"

    -- Provide some features to all blz widgets
    -- The android style for wow
    __Sealed__()
    interface "IView"(function()
        require "Frame"

        MIN_NUMBER = -2147483648
        MAX_NUMBER = 2147483647

        local function CreateTransformation(self)
            local transformation = {}
            transformation.alpha = self:GetAlpha()
            transformation.scale = self:GetScale()
            return transformation
        end

        local function OnLayoutParamsChanged(self, layoutParams, parent)
            parent = parent or self:GetParent()
            if parent and ViewGroup.IsViewGroup(parent) and not parent:CheckLayoutParams(layoutParams) then
                error(self:GetName() .. "'s LayoutParams is not valid for its parent", 2)
            end
        end

        local function OnParentChanged(self, parent, oldParent)
            -- remove view from old parent
            if oldParent and ViewGroup.IsViewGroup(oldParent) then
                oldParent:RemoveView(self)
            end

            if not ViewRoot.IsRootView(parent) and (not parent or not IView.IsView(parent)) then
                -- auto add to view root if no parent or parent is not view
                if ViewManager.ViewRoot then
                    ViewManager.ViewRoot:AddView(self)
                end
            end

            OnLayoutParamsChanged(self, self.LayoutParams, parent)
        end

        local function SetWidthInternal(self, width)
            Frame.SetWidth(self, width)
        end

        local function SetHeightInternal(self, height)
            Frame.SetHeight(self, height)
        end

        local function SetSizeInternal(self, width, height)
            Frame.SetSize(self, width, height)
        end

        local function ShowInternal(self)
            Frame.Show(self)
        end

        local function HideInternal(self)
            Frame.Hide(self)
        end

        local function SetShownInternal(self, shown)
            Frame.SetShown(self, shown)
        end

        -- Get child measure spec, copy from Android-ViewGroup
        -- @param measureSpec: The requirements for parent
        -- @param usedSize:Used size for the current dimension for parent
        -- @param childSize:How big the child wants to be in the current dimension
        -- @param maxSize: The max size for the current dimension for child
        __Static__()
        __Arguments__{ Number, NonNegativeNumber, ViewSize, NonNegativeNumber/nil }
        function GetChildMeasureSpec(measureSpec, usedSize, childSize, maxSize)
            local specMode = MeasureSpec.GetMode(measureSpec)
            local specSize = MeasureSpec.GetSize(measureSpec)
            maxSize = (not maxSize or maxSize == 0) and MAX_NUMBER or maxSize

            local size = math.max(specSize - usedSize, 0)

            local resultSize = 0
            local resultMode = 0

            if specMode == MeasureSpec.EXACTLY then
                -- Parent has imposed an exact size on us
                if childSize >= 0 then
                    -- Child wants a specific size... so be it
                    resultSize = childSize
                    resultMode = MeasureSpec.EXACTLY
                elseif childSize == SizeMode.MATCH_PARENT then
                    -- Child wants to be parent's size. So be it.
                    resultSize = math.min(size, maxSize)
                    resultMode = MeasureSpec.EXACTLY
                elseif childSize == SizeMode.WRAP_CONTENT then
                    -- Child wants to determine its own size
                    -- It can't be bigger than us
                    resultSize = math.min(size, maxSize)
                    resultMode = MeasureSpec.AT_MOST
                end
            elseif specMode == MeasureSpec.AT_MOST then
                -- Parent has imposed a maximum size on us
                if childSize >= 0 then
                    -- Child wants a specific size... so be it
                    resultSize = childSize
                    resultMode = MeasureSpec.EXACTLY
                elseif childSize == SizeMode.MATCH_PARENT then
                    -- Child wants to be parent's size, but parent's size is not fixed.
                    -- Constrain child to not be bigger than parent.
                    resultSize = math.min(size, maxSize)
                    resultMode = MeasureSpec.AT_MOST
                elseif childSize == SizeMode.WRAP_CONTENT then
                    -- Child wants to determine its own size
                    -- It can't be bigger than us
                    resultSize = math.min(size, maxSize)
                    resultMode = MeasureSpec.AT_MOST
                end
            elseif specMode == MeasureSpec.UNSPECIFIED then
                -- Parent asked to see how big child want to be
                if childSize >= 0 then
                    -- Child wants a specific size... let him have it
                    resultSize = childSize
                    resultMode = MeasureSpec.EXACTLY
                elseif childSize == SizeMode.MATCH_PARENT then
                    -- Child wants to be parent's size... find out how big it should be
                    resultSize = math.min(size, maxSize)
                    resultMode = MeasureSpec.UNSPECIFIED
                elseif childSize == SizeMode.WRAP_CONTENT then
                    -- Child wants to determine its own size.... 
                    -- find out how big it should be
                    resultSize = math.min(size, maxSize)
                    resultMode = MeasureSpec.UNSPECIFIED
                end
            end

            return MeasureSpec.MakeMeasureSpec(resultMode, resultSize)
        end
        
        -- Measure size
        __Final__()
        function Measure(self, widthMeasureSpec, heightMeasureSpec)
            local specChanged = widthMeasureSpec ~= self.__OldWidthMeasureSpec or heightMeasureSpec ~= self.__OldHeightMeasureSpec
            local isSpecExactly = MeasureSpec.GetMode(widthMeasureSpec) == MeasureSpec.EXACTLY and MeasureSpec.GetMode(widthMeasureSpec) == MeasureSpec.EXACTLY
            local matchesSpecSize = self:GetMeasuredWidth() == MeasureSpec.GetSize(widthMeasureSpec) and self:GetMeasuredHeight() == MeasureSpec.GetSize(heightMeasureSpec)

            if self:IsInLayout() or (specChanged and (not isSpecExactly or not matchesSpecSize)) then
                self:OnMeasure(widthMeasureSpec, heightMeasureSpec)
            end
            
            self.__OldWidthMeasureSpec = widthMeasureSpec
            self.__OldHeightMeasureSpec = heightMeasureSpec
        end

        -- This function should call SetMeasuredSize to store measured width and measured height
        __Abstract__()
        function OnMeasure(self, widthMeasureSpec, heightMeasureSpec)
            self:SetMeasuredSize(IView.GetDefaultMeasureSize(self.MinWidth, widthMeasureSpec),
                IView.GetDefaultMeasureSize(self.MinHeight, heightMeasureSpec))
        end

        -- Utility to return a default size
        __Static__()
        function GetDefaultMeasureSize(size, measureSpec)
            local result = size
            local mode = MeasureSpec.GetMode(measureSpec)
            
            if mode == MeasureSpec.AT_MOST then
                result = math.min(size, MeasureSpec.GetSize(measureSpec))
            elseif mode == MeasureSpec.EXACTLY then
                result = MeasureSpec.GetSize(measureSpec)
            end

            return result
        end

        -- Change size and goto it's location
        __Final__()
        function Layout(self)
            local width, height = self:GetSize()
            local changed =  math.abs(width - self:GetMeasuredWidth()) >= 0.01 or math.abs(height - self:GetMeasuredHeight()) >= 0.01
            if changed or self:IsInLayout() then
                SetSizeInternal(self, self:GetMeasuredWidth(), self:GetMeasuredHeight())
                -- A great opportunity to do something
                self:OnLayout()
            end
            -- layout complete
            self.__LayoutRequested = false
        end

        -- Viewgroup should override this function to call Layout function on each of it's children and place child to it's position
        __Abstract__()
        function OnLayout(self)
        end

        __Final__()
        function Refresh(self)
            self:OnRefresh()
        end
        
        -- Viewgroup should override this function to call Refresh on each of it's children
        __Abstract__()
        function OnRefresh(self)
        end

        __Static__()
        function IsView(view)
            return Class.ValidateValue(IView, view, true) and true or false
        end

        function RequestLayout(self)
            self.__LayoutRequested = true
            local parent = self:GetParent()
            if parent then
                parent:RequestLayout()
            end
        end

        -- ViewGroup can override this function to check child layoutParams
        -- @return true is valid layout params and false otherwise
        __Abstract__()
        function CheckLayoutParams(self, layoutParams)
        end

        -- return whether this view is in layout
        function IsInLayout(self)
            return self.__LayoutRequested
        end

        -- @see ViewGroup.LayoutChild
        function GetLayoutPointAndOffsetSign(self)
            local direction = self.LayoutDirection
            local point, xSign, ySign
            if direction == LayoutDirection.TOPLEFT then
                point = "TOPLEFT"
                xSign = 1
                ySign = -1
            elseif direction == LayoutDirection.TOPRIGHT then
                point = "TOPRIGHT"
                xSign = -1
                ySign = -1
            elseif direction == LayoutDirection.BOTTOMLEFT then
                point = "BOTTOMLEFT"
                xSign = 1
                ySign = 1
            else
                point = "BOTTOMRIGHT"
                xSign = -1
                ySign = 1
            end
            return point, xSign, ySign
        end

        __Final__()
        function GetMeasuredWidth(self)
            return self.__MeasuredWidth or MIN_NUMBER
        end

        __Final__()
        function GetMeasuredHeight(self)
            return self.__MeasuredHeight or MIN_NUMBER
        end

        -- This function only can be called in OnMeasure
        __Final__()
        __Arguments__{ NonNegativeNumber, NonNegativeNumber }
        function SetMeasuredSize(self, width, height)
            self.__MeasuredWidth = width
            self.__MeasuredHeight = height
        end

        __Final__()
        __Arguments__{ ViewSize }
        function SetWidth(self, width)
            self.Width = width
        end

        __Final__()
        __Arguments__{ ViewSize }
        function SetHeight(self, height)
            self.Height = height
        end

        __Final__()
        __Arguments__{ ViewSize, ViewSize }
        function SetSize(self, width, height)
            self.Width = width
            self.Height = height
        end

        __Final__()
        function SetPoint(self, ...)
            local parent = self:GetParent()
            -- only parent is blz's widget can use this api
            if not parent or not IView.IsView(parent) then
                self:SetViewPoint(...)
            end
        end

        -- internal use
        function SetViewPoint(self, ...)
            Frame.SetPoint(self, ...)
        end

        -- internal use
        function SetViewPointByParent(self, point, relativeTo, relativePoint, offsetX, offsetY)
            self.__LayoutPoint = point
            self.__LayoutRelativeTo = relativeTo
            self.__LayoutRelativePoint = relativePoint
            self.__LayoutOffsetX = offsetX
            self.__LayoutOffsetY = offsetY
        end

        -- Only direct children of the root view can set frame strata
        __Final__()
        function SetFrameStrata(self, frameStrata)
            local parent = self:GetParent()
            -- only parent is not view or parent is root view can use this api
            if not parent or not IView.IsView(parent) or ViewRoot.IsRootView(parent) then
                self:SetViewFrameStrata(frameStrata)
            end
        end

        -- internal use
        function SetViewFrameStrata(self, frameStrata)
            Frame.SetFrameStrata(self, frameStrata)
        end

        -- Only direct children of the root view can set frame level
        __Final__()
        function SetFrameLevel(self, level)
            local parent = self:GetParent()
            -- only parent is not view or parent is root view can use this api
            if not parent or not IView.IsView(parent) or ViewRoot.IsRootView(parent) then
                self:SetViewFrameLevel(level)
            end
        end

        -- internal use
        function SetViewFrameLevel(self, level)
            Frame.SetFrameLevel(self, level)
        end

        function OnViewPropertyChanged(self)
            self:RequestLayout()
        end

        __Arguments__{ NonNegativeNumber/0, NonNegativeNumber/0, NonNegativeNumber/0, NonNegativeNumber/0 }
        function SetMargin(self, left, top, right, bottom)
            self.MarginStart = left
            self.MarginEnd = right
            self.MarginTop = top
            self.MarginBottom = bottom
        end

        __Arguments__{ NonNegativeNumber/0, NonNegativeNumber/0, NonNegativeNumber/0, NonNegativeNumber/0 }
        function SetPadding(self, left, top, right, bottom)
            self.PaddingStart = left
            self.PaddingEnd = right
            self.PaddingTop = top
            self.PaddingBottom = bottom
        end

        __Final__()
        function SetShown(self, shown)
            if shown then
                self.Visibility = Visibility.VISIBLE
            else
                self.Visibility = Visibility.GONE
            end
        end

        __Final__()
        function Show(self)
            self.Visibility = Visibility.VISIBLE
        end

        __Final__()
        function Hide(self)
            self.Visibility = Visibility.GONE
        end

        function SetAlpha(self, alpha)
            self.__Transformation.alpha = alpha
            self:SetViewAlpha(alpha)
        end

        -- internal use
        function SetViewAlpha(self, alpha)
            Frame.SetAlpha(self, alpha)
        end

        function SetScale(self, scale)
            self.__Transformation.scale = scale
            self:SetViewScale(scale)
        end

        -- internal use
        function SetViewScale(self, scale)
            Frame.SetScale(self, scale)
        end

        function OnVisibilityChanged(self, visibility, old)
            SetShownInternal(self, visibility == Visibility.VISIBLE)
            self:RequestLayout()
        end

        -- internal use
        function ApplyTransformation(self)
            self:SetViewAlpha(self.__Transformation.alpha)
            self:SetViewScale(self.__Transformation.scale)
        end
        -----------------------------------------
        --              Animation              --
        -----------------------------------------

        -- Set animation to this view
        __Arguments__{ ViewAnimation/nil }
        function SetAnimation(self, animation)
            if self.__ViewAnimation then
                self.__ViewAnimation:Detach()
            end
            
            self.__ViewAnimation = animation

            if animation then
                animation:Attach(self)
            end
        end

        -- Set animation to this view and start animation
        __Arguments__{ ViewAnimation }
        function StartAnimation(self, animation)
            self:SetAnimation(animation)
            animation:Start()
        end

        -- Get animation, may be nil
        function GetAnimation(self)
            return self.__ViewAnimation
        end

        -- internal use
        function GetAnimationTransformation(self)
            if not self.__AnimationTransformation then
                self.__AnimationTransformation = Transformation()
            end

            return self.__AnimationTransformation
        end

        -- internal use
        function ApplyAnimationTransformation(self)
            if self.__AnimationTransformation then
                self:SetAlpha(self.__AnimationTransformation.alpha)
                self:SetScale(self.__AnimationTransformation.scale)
            end
        end

        -----------------------------------------
        --              Propertys              --
        -----------------------------------------

        property "Visibility"       {
            type                    = Visibility,
            default                 = Visibility.VISIBLE,
            handler                 = OnVisibilityChanged
        }

        property "Padding"          {
            type                    = NonNegativeNumber,
            get                     = false,
            set                     = function(self, padding)
                self.PaddingStart = padding
                self.PaddingEnd = padding
                self.PaddingTop = padding
                self.PaddingBottom = padding
            end
        }

        property "PaddingHorizontal"{
            type                    = NonNegativeNumber,
            get                     = false,
            set                     = function(self, paddingHorizontal)
                self.paddingStart = paddingHorizontal
                self.paddingEnd = paddingHorizontal
            end
        }

        property "PaddingVertical"  {
            type                    = NonNegativeNumber,
            get                     = false,
            set                     = function(self, paddingVertical)
                self.paddingStart = paddingVertical
                self.paddingEnd = paddingVertical
            end
        }

        property "PaddingEnd"       {
            type                    = NonNegativeNumber,
            default                 = 0,
            handler                 = OnViewPropertyChanged
        }

        property "PaddingStart"     {
            type                    = NonNegativeNumber,
            default                 = 0,
            handler                 = OnViewPropertyChanged
        }

        property "PaddingTop"       {
            type                    = NonNegativeNumber,
            default                 = 0,
            handler                 = OnViewPropertyChanged
        }

        property "PaddingBottom"    {
            type                    = NonNegativeNumber,
            default                 = 0,
            handler                 = OnViewPropertyChanged
        }

        property "Margin"           {
            type                    = NonNegativeNumber,
            get                     = false,
            set                     = function(self, margin)
                self.MarginStart = margin
                self.MarginEnd = margin
            end
        }

        property "MarginHorizontal" {
            type                    = NonNegativeNumber,
            get                     = false,
            set                     = function(self, marginHorizontal)
                self.MarginStart = marginHorizontal
                self.MarginEnd = marginHorizontal
            end
        }
        
        property "MarginVertical"   {
            type                    = NonNegativeNumber,
            get                     = false,
            set                     = function(self, marginVertical)
                self.MarginTop      = marginVertical
                self.MarginBottom   = marginVertical
            end
        }

        property "MarginEnd"        {
            type                    = NonNegativeNumber,
            default                 = 0,
            handler                 = OnViewPropertyChanged
        }

        property "MarginStart"      {
            type                    = NonNegativeNumber,
            default                 = 0,
            handler                 = OnViewPropertyChanged
        }

        property "MarginTop"        {
            type                    = NonNegativeNumber,
            default                 = 0,
            handler                 = OnViewPropertyChanged
        }

        property "MarginBottom"     {
            type                    = NonNegativeNumber,
            default                 = 0,
            handler                 = OnViewPropertyChanged
        }

        property "MinHeight"        {
            type                    = NonNegativeNumber,
            default                 = 0,
            throwable               = true,
            handler                 = function(self, minHeight)
                if minHeight > self.MaxHeight then
                    throw(self:GetName() + "'s MinHeight can not be larger than MaxHeight")
                end
                self:OnViewPropertyChanged()
            end
        }

        property "MinWidth"         {
            type                    = NonNegativeNumber,
            default                 = 0,
            throwable               = true,
            handler                 = function(self, minWidth)
                if minWidth > self.MaxWidth then
                    throw(self:GetName() + "'s MinWidth can not be larger than MaxWidth")
                end
                self:OnViewPropertyChanged()
            end
        }

        property "MaxWidth"         {
            type                    = NonNegativeNumber,
            default                 = 0,
            throwable               = true,
            handler                 = function(self, maxWidth)
                if maxWidth < self.MinWidth then
                    throw(self:GetName() + "'s MaxWidth can not be lower than MinWidth")
                end
                self:OnViewPropertyChanged()
            end
        }

        property "MaxHeight"        {
            type                    = NonNegativeNumber,
            default                 = 0,
            handler                 = function(self, maxHeight)
                if maxHeight < self.MinHeight then
                    throw(self:GetName() + "'s MaxHeight can not be lower than MinHeight")
                end
                self:OnViewPropertyChanged()
            end
        }

        __Final__()
        property "Width"            {
            type                    = ViewSize,
            default                 = SizeMode.WRAP_CONTENT,
            handler                 = OnViewPropertyChanged
        }

        __Final__()
        property "Height"           {
            type                    = ViewSize,
            default                 = SizeMode.WRAP_CONTENT,
            handler                 = OnViewPropertyChanged
        }

        __Final__()
        property "FrameStrata"      {
            type                    = FrameStrata,
            default                 = "MEDIUM",
            handler                 = SetFrameStrata
        }

        __Final__()
        property "FrameLevel"       {
            type                    = Number,
            default                 = 1,
            handler                 = SetFrameLevel
        }

        property "LayoutParams"     {
            type                    = LayoutParams,
            throwable               = true,
            handler                 = function(self, layoutParams)
                OnLayoutParamsChanged(self, layoutParams)
                self:OnViewPropertyChanged()
            end
        }

        property "LayoutDirection"  {
            type                    = LayoutDirection,
            default                 = LayoutDirection.TOPLEFT,
            handler                 = function(self)
                self:OnViewPropertyChanged()
            end
        }

        -----------------------------------------
        --              Constructor            --
        -----------------------------------------

        function __init(self)
            self.__Transformation = CreateTransformation(self)
            -- default request layout
            self.__LayoutRequested = true
            self.OnParentChanged = self.OnParentChanged + OnParentChanged
            -- check parent valid
            OnParentChanged(self, self:GetParent())
        end

    end)

    -- Frame, implement IView
    class "View" { Frame, IView }

end)