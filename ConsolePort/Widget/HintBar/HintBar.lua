local _, db = ...
----------------------------------
-- Hint mixin
----------------------------------
CPHintMixin = {}

function CPHintMixin:OnLoad()
	self.bar = self:GetParent()
	self.Text:SetShadowOffset(2, -2)
end

function CPHintMixin:OnShow()
	self.isActive = true
	db.Alpha.FadeIn(self, 0.2, 0, 1)
end

function CPHintMixin:OnHide()
	self.isActive = false
	self:SetData(nil, nil)
end

function CPHintMixin:UpdateParentWidth()
	if self.bar then
		self.bar:Update()
	end
end

function CPHintMixin:Enable()
	self.Icon:SetVertexColor(1, 1, 1)
	self.Text:SetVertexColor(1, 1, 1)
end

function CPHintMixin:Disable()
	self.Icon:SetVertexColor(0.5, 0.5, 0.5)
	self.Text:SetVertexColor(0.5, 0.5, 0.5)
end

function CPHintMixin:GetText()
	return self.Text:GetText()
end

function CPHintMixin:SetData(icon, text)
	self.Icon:SetTexture(icon and db('Icons/64/'..icon))
	self.Text:SetText(text)
	self:SetWidth(self.Text:GetStringWidth() + 64)
	self:UpdateParentWidth()
end

----------------------------------
-- HintBar mixin
----------------------------------
CPHintBarMixin = {}

function CPHintBarMixin:OnLoad()
	self.Hints = {}
	self:SetAlpha(0)
	self:SetParent(UIParent)
	self:SetIgnoreParentAlpha(true)
	self:SetFrameStrata('FULLSCREEN_DIALOG')
	db:RegisterCallback('Settings/UIscale', self.SetScale, self)
end

function CPHintBarMixin:Show()
	self:SetScale(db('UIscale'))
	getmetatable(self).__index.Show(self)
	db.Alpha.FadeIn(self, 0.1, self:GetAlpha(), 1)
end

function CPHintBarMixin:Hide()
	db.Alpha.FadeOut(self, 0.1, self:GetAlpha(), 0, {
		finishedFunc = getmetatable(self).__index.Hide;
		finishedArg1 = self;
	})
end

function CPHintBarMixin:AdjustWidth(newWidth)
	self:SetScript('OnUpdate', function(self)
		local width = self:GetWidth()
		local diff = newWidth - width
		if abs(newWidth - width) < 1 then
			self:SetWidth(newWidth)
			self:SetScript('OnUpdate', nil)
		else
			self:SetWidth(width + ( diff / 4 ) )
		end
	end)
end

function CPHintBarMixin:Update()
	local width, previousHint = 0
	for _, hint in pairs(self.Hints) do
		if previousHint then
			hint:SetPoint('LEFT', previousHint.Text, 'RIGHT', 16, 0)
		else
			hint:SetPoint('LEFT', self, 'LEFT', 0, 0)
		end
		if hint:IsVisible() then
			width = width + hint:GetWidth()
			previousHint = hint
		end
	end
	self:AdjustWidth(width)
end

function CPHintBarMixin:Reset()
	for _, hint in pairs(self.Hints) do
		hint:Hide()
	end
end

function CPHintBarMixin:GetHintFromPool(key, showBar)
	local hints = self.Hints
	local hint = hints[key]
	if not hint then
		hint = CreateFrame('Frame', '$parentHint'..key, self, 'CPHintTemplate')
		self.Hints[key] = hint
	end
	hint:Show()
	if showBar then
		self:Show()
	end
	return hint
end

function CPHintBarMixin:GetActiveHintForKey(key)
	local hint = self.Hints[key]
	return hint and hint.isActive and hint
end

function CPHintBarMixin:AddHint(key, text)
	local binding = db.UIHandle:GetUIControlBinding(key)
	if binding then
		local hint = self:GetHintFromPool(key)
		hint:SetData(binding, text)
		hint:Enable()
		return hint
	end
end