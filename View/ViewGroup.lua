PLoop(function()

    namespace "MeowMeow.Layout"

    class "ViewGroup"(function()
        inherit "View"

        -- auto add child or remove child
        local function OnChildChanged(self, child, isAdded)
            print(self:GetName(), "OnChildChanged", child:GetName(), isAdded)
            if child then
                if isAdded then
                    self:AddView(child)
                else
                    self:RemoveView(child)
                end
            end
        end
        
        -- Call this function to layout child. This function will automatically calculate the positions corresponding to different layout directions
        __Final__()
        __Arguments__{ IView, Number, Number }
        function LayoutChild(self, child, xOffset, yOffset)
            local point, xSign, ySign = self:GetLayoutPointAndOffsetSign()
            local width, height = child:GetSize()
            xOffset = xSign * xOffset + xSign * width/2
            yOffset = ySign * yOffset + ySign * height/2

            child:ClearAllPoints()
            child:SetViewPoint("CENTER", self, point, xOffset, yOffset)
        end

        -- @Override
        function OnRefresh(self)
            for _, child in self:GetNonGoneChilds() do
                child:Refresh()
            end
        end

        -- @Override
        function SetViewFrameStrata(self, frameStrata)
            super.SetViewFrameStrata(self, frameStrata)
            for _, child in ipairs(self.__ChildViews) do
                child:SetViewFrameStrata(frameStrata)
            end
        end

        -- @Override
        function SetViewFrameLevel(self, level)
            super.SetViewFrameLevel(self, level)
            for _, child in ipairs(self.__ChildViews) do
                child:SetViewFrameLevel(level + 1)
            end
        end

        __Arguments__{ IView }
        function RemoveView(self, view)
            if tContains(self.__ChildViews, view) then
                self:OnChildRemove(view)
                tDeleteItem(self.__ChildViews, view)
                self:OnChildRemoved()
                self:RequestLayout()
            end
        end

        function OnChildRemove(self, child)
            if child:GetParent() == self then
                child:ClearAllPoints()
                child:SetParent(nil)
            end
        end

        __Abstract__()
        function OnChildRemoved(self)
        end

        __Arguments__{ IView, NonNegativeNumber/0 }
        function AddView(self, view, index)
            print(self:GetName(), "AddView", view:GetName())
            if not tContains(self.__ChildViews, view) then
                if index <= 0 then
                    index = #self.__ChildViews + 1
                end
                self:OnChildAdd(view)
                tinsert(self.__ChildViews, index, view)
                self:OnChildAdded()
                self:RequestLayout()
            end
        end

        function OnChildAdd(self, child)
            child:ClearAllPoints()
            child:SetParent(self)
            child:SetViewFrameStrata(self:GetFrameStrata())
            child:SetViewFrameLevel(self:GetFrameLevel() + 1)
        end

        __Abstract__()
        function OnChildAdded(self)
        end

        __Arguments__{ NaturalNumber }
        function GetChildViewAt(self, index)
            return self.__ChildViews[index]
        end

        function GetChildViewCount(self)
            return #self.__ChildViews
        end

        function GetChildViews(self)
            return ipairs(self.__ChildViews)
        end

        -- Internal use, iterator
        function GetNonGoneChilds(self)
            return function(views, index)
                index = (index or 0) + 1
                for i = index, #views do
                    local view = views[i]
                    if view.Visibility ~= Visibility.GONE then
                        return i, view
                    end
                end
            end, self.__ChildViews, 0
        end
        
        __Static__()
        function IsViewGroup(viewGroup)
            return Class.ValidateValue(ViewGroup, viewGroup, true) and true or false
        end

        function __ctor(self)
            self.__ChildViews = {}
            self.OnChildChanged = self.OnChildChanged + OnChildChanged
        end

    end)

end)