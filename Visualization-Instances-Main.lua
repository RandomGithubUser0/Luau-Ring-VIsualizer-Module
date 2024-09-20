-- || VisualizeV2 ||
-- || by a_very_good_username_here (Discord) / SeasonedRiceFarmer (Roblox) ||

--[[

Since this runs on the client, use playtest instead of run.

** PLEASE CREDIT ME!!! **

]]

--[[

PRESETS: 

local PRESETS = {
	TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine);
	NumSurroundingBars = 5;
	PolynomialDegree = 2.5;
	OriginalSize = Vector3.new(0.5, 0.5, 0.05);
	MaxSize = Vector3.new(15, 0.5, 0.05);
	OriginalColor = Color3.fromRGB(255, 137, 58);
	MaxColor = Color3.fromRGB(255, 255, 255);
	Cooldown = 0.025; -- For Optimization (Keep it at 0.05)
}

]]

-- Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Variables
local tweenInfo = TweenInfo.new(0.15)

local Clamp = math.clamp

-- Functions
local function ScaleTo(Current, Max, To)
	return math.round((Current * To) / Max)
end

local function PolynomialInterpolation(Alpha, Min, Max, Degree)
	return (Max - Min) * (Alpha ^ Degree) + Min
end

-- VisualizerClass
local Visualizer = {}
Visualizer.__index = Visualizer

-- Constructor 
function Visualizer.Create(VisualizeMain, Audio, Presets)
	local self = setmetatable({
		VisualizeInstances = VisualizeMain:GetChildren();
		VisualizeModel = VisualizeMain;
		Audio = Audio;
		Presets = Presets;
		NewScaleValue = Instance.new("NumberValue");
	}, Visualizer)
	self.NewScaleValue.Value = 1
	return self
end

-- Methods
function Visualizer:Start()
	local MaxLoudness = 5
	local OriginalSize, MaxSize = self.Presets.OriginalSize, self.Presets.MaxSize
	local OriginalColor, MaxColor = self.Presets.OriginalColor, self.Presets.MaxColor
	local IsRGB = self.Presets.RGB
	
	local Clock = 0
	self.Main = RunService.Heartbeat:Connect(function(DeltaTime)	
		-- Reduce Calculations
		Clock += DeltaTime; if not (Clock >= self.Presets.Cooldown) then return end; Clock = 0 
		
		if IsRGB then
			OriginalColor = Color3.fromHSV(tick() % 3 / 3, 0.6, 0.9)
		end
		
		-- Update Maximum Loudness
		local CurrentLoudness = self.Audio.PlaybackLoudness
		if CurrentLoudness > MaxLoudness then
			MaxLoudness = CurrentLoudness
		end
		task.spawn(function()
			-- Bars to change
			local ToChange = {}
			
			-- Get the number of the main part 
			local MainNumber = ScaleTo(CurrentLoudness, MaxLoudness, #self.VisualizeInstances) + 1
			ToChange[MainNumber] = 1
			
			-- Gets surrounding bars
			local PolynomialDegree = self.Presets.PolynomialDegree
			for i = 1, self.Presets.NumSurroundingBars do
				local Below, Above = MainNumber - i, MainNumber + i
				if Below < 1 then
					Below = (#self.VisualizeInstances - i) + 1
				end
				if Above > #self.VisualizeInstances then
					Above = i
				end
				-- Convert values via polynomial interpolation
				local Alpha = (self.Presets.NumSurroundingBars - i) / self.Presets.NumSurroundingBars
				local InterpolatedValue = PolynomialInterpolation(Alpha, 0, 1, PolynomialDegree)
				ToChange[Below], ToChange[Above] = InterpolatedValue, InterpolatedValue
			end
			for i = 1, #self.VisualizeInstances do
				local VisualizationBar = self.VisualizeModel:FindFirstChild(i) 
				if not VisualizationBar then continue end
				local Properties = {}
				local Alpha = 0
				if ToChange[i] then
					Alpha = ToChange[i]
				end
				local CurrentSize = OriginalSize:Lerp(MaxSize, Alpha)
				local CurrentColor = OriginalColor:Lerp(MaxColor, Alpha)

				if VisualizationBar.Size ~= CurrentSize then
					Properties.Size = CurrentSize
				end

				if VisualizationBar.Color ~= CurrentColor then
					Properties.Color = CurrentColor
				end

				if Properties.Size or Properties.Color then
					self:PropertyChange(VisualizationBar, Properties)
				end
			end
		end)
		
		-- Adjust Scale
		local Scaled = ScaleTo(CurrentLoudness, self.Presets.ScaleLoudnessMax, 1)
		
		local NewScale = Clamp(0.3 + (Scaled * 0.83), 0.9, 1.5)
		TweenService:Create(self.NewScaleValue, tweenInfo, {Value = NewScale}):Play()
		local CurrentScale = self.NewScaleValue.Value
		self.VisualizeModel:ScaleTo(CurrentScale)
	end)
end

function Visualizer:PropertyChange(VisualizationBar, Properties)
	local Tween = TweenService:Create(VisualizationBar, self.Presets.TweenInfo, Properties)
	Tween:Play()
	Debris:AddItem(Tween, self.Presets.TweenInfo.Time)
end

function Visualizer:SetPreset(NewPreset)
	self.Presets = NewPreset
	self:Refresh()
end

function Visualizer:SetPresetSpecific(Property, Value)
	self.Presets[Property] = Value
	self:Refresh()
end

function Visualizer:Refresh()
	self.Main:Disconnect(); self.Main = nil
	self:Start()
end

return Visualizer