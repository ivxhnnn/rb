if game:GetService("CoreGui"):FindFirstChild("Frenzy") then
	game:GetService("CoreGui").Frenzy:Destroy();
end
local G2L = {};
G2L["1"] = Instance.new("ScreenGui", game:GetService("CoreGui"));
G2L["1"]['IgnoreGuiInset'] = true;
G2L["1"]['ScreenInsets'] = Enum.ScreenInsets.DeviceSafeInsets;
G2L["1"]['Name'] = [[Frenzy]];
G2L["2"] = Instance.new("TextButton", G2L["1"]);
G2L["2"]['TextWrapped'] = true;
G2L["2"]['TextStrokeTransparency'] = 0;
G2L["2"]['BorderSizePixel'] = 0;
G2L["2"]['TextColor3'] = Color3.fromRGB(255, 255, 255);
G2L["2"]['TextSize'] = 40;
G2L["2"]['TextScaled'] = true;
G2L["2"]['BackgroundColor3'] = Color3.fromRGB(38, 38, 38);
G2L["2"]['FontFace'] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["2"]['AnchorPoint'] = Vector2.new(1, 1);
G2L["2"]['Size'] = UDim2.new(0, 25, 0, 50);
G2L["2"]['Name'] = [[Show]];
G2L["2"]['BorderColor3'] = Color3.fromRGB(0, 0, 0);
G2L["2"]['Text'] = [[>]];
G2L["2"]['Position'] = UDim2.new(1, 27, 1, -30);
G2L["3"] = Instance.new("UITextSizeConstraint", G2L["2"]);
G2L["3"]['MaxTextSize'] = 40;
G2L["4"] = Instance.new("UIStroke", G2L["2"]);
G2L["4"]['ApplyStrokeMode'] = Enum.ApplyStrokeMode.Border;
G2L["4"]['LineJoinMode'] = Enum.LineJoinMode.Miter;
G2L["4"]['Thickness'] = 2;
G2L["5"] = Instance.new("LocalScript", G2L["2"]);
G2L["6"] = Instance.new("ScrollingFrame", G2L["1"]);
G2L["6"]['Active'] = true;
G2L["6"]['BorderSizePixel'] = 0;
G2L["6"]['CanvasSize'] = UDim2.new(0, 0, 0, 0);
G2L["6"]['MidImage'] = [[]];
G2L["6"]['BackgroundColor3'] = Color3.fromRGB(38, 38, 38);
G2L["6"]['Name'] = [[Main]];
G2L["6"]['ScrollBarImageTransparency'] = 1;
G2L["6"]['AnchorPoint'] = Vector2.new(1, 1);
G2L["6"]['AutomaticCanvasSize'] = Enum.AutomaticSize.Y;
G2L["6"]['Size'] = UDim2.new(0, 100, 0, 100);
G2L["6"]['Position'] = UDim2.new(1, 102, 1, -82);
G2L["6"]['BorderColor3'] = Color3.fromRGB(0, 0, 0);
G2L["6"]['ScrollBarThickness'] = 0;
G2L["7"] = Instance.new("UIStroke", G2L["6"]);
G2L["7"]['ApplyStrokeMode'] = Enum.ApplyStrokeMode.Border;
G2L["7"]['LineJoinMode'] = Enum.LineJoinMode.Miter;
G2L["7"]['Thickness'] = 2;
G2L["8"] = Instance.new("UIListLayout", G2L["6"]);
G2L["8"]['SortOrder'] = Enum.SortOrder.LayoutOrder;
G2L["9"] = Instance.new("TextButton", G2L["6"]);
G2L["9"]['TextWrapped'] = true;
G2L["9"]['TextStrokeTransparency'] = 0;
G2L["9"]['BorderSizePixel'] = 0;
G2L["9"]['TextColor3'] = Color3.fromRGB(171, 0, 0);
G2L["9"]['TextSize'] = 20;
G2L["9"]['TextScaled'] = true;
G2L["9"]['BackgroundColor3'] = Color3.fromRGB(38, 38, 38);
G2L["9"]['FontFace'] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["9"]['Size'] = UDim2.new(1, 0, 0, 75);
G2L["9"]['LayoutOrder'] = 1;
G2L["9"]['Name'] = [[Freeze]];
G2L["9"]['BorderColor3'] = Color3.fromRGB(0, 0, 0);
G2L["9"]['Text'] = [[Freeze]];
G2L['a'] = Instance.new("LocalScript", G2L["9"]);
G2L['b'] = Instance.new("UITextSizeConstraint", G2L["9"]);
G2L['b']['MaxTextSize'] = 20;
G2L['c'] = Instance.new("TextButton", G2L["6"]);
G2L['c']['TextWrapped'] = true;
G2L['c']['TextStrokeTransparency'] = 0;
G2L['c']['BorderSizePixel'] = 0;
G2L['c']['TextColor3'] = Color3.fromRGB(255, 255, 255);
G2L['c']['TextSize'] = 20;
G2L['c']['TextScaled'] = true;
G2L['c']['BackgroundColor3'] = Color3.fromRGB(38, 38, 38);
G2L['c']['FontFace'] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L['c']['Size'] = UDim2.new(1, 0, 0, 25);
G2L['c']['LayoutOrder'] = 3;
G2L['c']['Name'] = [[DestroyGUI]];
G2L['c']['BorderColor3'] = Color3.fromRGB(0, 0, 0);
G2L['c']['Text'] = [[Destroy GUI]];
G2L['d'] = Instance.new("LocalScript", G2L['c']);
G2L['e'] = Instance.new("UIStroke", G2L['c']);
G2L['e']['ApplyStrokeMode'] = Enum.ApplyStrokeMode.Border;
G2L['e']['LineJoinMode'] = Enum.LineJoinMode.Miter;
G2L['e']['Thickness'] = 2;
G2L['f'] = Instance.new("UITextSizeConstraint", G2L['c']);
G2L['f']['MaxTextSize'] = 20;
G2L["10"] = Instance.new("LocalScript", G2L["1"]);
G2L["10"]['Name'] = [[SoundSystem]];
G2L["11"] = Instance.new("Sound", G2L["1"]);
G2L["11"]['Name'] = [[hovers]];
G2L["11"]['SoundId'] = [[rbxassetid://18755583152]];
G2L["12"] = Instance.new("Sound", G2L["1"]);
G2L["12"]['Name'] = [[clicking]];
G2L["12"]['SoundId'] = [[rbxassetid://3848738002]];
G2L["13"] = Instance.new("LocalScript", G2L["1"]);
G2L["13"]['Name'] = [[Intro]];

local function C_5()
	local script = G2L["5"];
	local hide = false;
	script.Parent.MouseButton1Click:Connect(function()
		if (hide == false) then
			hide = true;
			script.Parent.Parent.Main:TweenPosition(UDim2.new(1, 102, 1, -82), Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 0.25, true);
			script.Parent.Text = "<";
		else
			hide = false;
			script.Parent.Parent.Main:TweenPosition(UDim2.new(1, -2, 1, -82), Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 0.25, true);
			script.Parent.Text = ">";
		end
	end);
end
task.spawn(C_5);


local function C_a()
	local script = G2L['a'];
	local player = game.Players.LocalPlayer
	local froze = false;

	script.Parent.MouseButton1Click:Connect(function()
		local character = player.Character
		if not character or not character:IsA("Model") then return end
		local animate = character:FindFirstChild("Animate")
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if not humanoid then return end

		froze = not froze
		if froze then
			script.Parent.TextColor3 = Color3.fromRGB(0, 170, 0);
		
			if animate then animate.Disabled = true end
			for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
				track:AdjustSpeed(0)
			end
		else
			script.Parent.TextColor3 = Color3.fromRGB(170, 0, 0);
		
			if animate then animate.Disabled = false end
			for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
				track:AdjustSpeed(1)
			end
		end
	end);
end
task.spawn(C_a);

local function C_d()
	local script = G2L['d'];
	local button = script.Parent;
	local clickTimeThreshold = 0.5;
	local lastClickTime = 0;
	button.MouseButton1Click:Connect(function()
		local currentTime = tick();
		if ((currentTime - lastClickTime) <= clickTimeThreshold) then
			script.Parent.Parent:TweenPosition(UDim2.new(1, 102, 1, -82), Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 0.25);
			script.Parent.Parent.Parent.Show:TweenPosition(UDim2.new(1, 27, 1, -30), Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 0.25);
		end
		lastClickTime = currentTime;
	end);
end
task.spawn(C_d);

local function C_10()
	local script = G2L["10"];
	local function playSound(sound)
		script.Parent[sound]:Play();
	end
	for _, v in pairs(script.Parent:GetDescendants()) do
		if (v:IsA("TextButton") or v:IsA("ImageButton")) then
			v.MouseEnter:Connect(function()
				playSound("hovers");
			end);
			v.MouseButton1Click:Connect(function()
				playSound("clicking");
			end);
		end
	end
end
task.spawn(C_10);

local function C_13()
	local script = G2L["13"];
	script.Parent.Main:TweenPosition(UDim2.new(1, -2, 1, -82), Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 1);
	script.Parent.Show:TweenPosition(UDim2.new(1, -2, 1, -30), Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 1);
end
task.spawn(C_13);

return G2L["1"], require;
-- IGHT
