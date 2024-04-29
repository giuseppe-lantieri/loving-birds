local IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and arg[2] == "debug"
if IS_DEBUG then
	require("lldebugger").start()

	function love.errorhandler(msg)
		error(msg, 2)
	end
end

function love.load()
	TitleFont = love.graphics.newFont(24, "mono");

	GameState = 0;
	GAP = 100;

	JUMP = 50;

	PointSFX = love.audio.newSource("/assets/point.mp3", "stream");
	SwooshSFX = love.audio.newSource("/assets/swoosh.mp3", "stream");
	BombImage = love.graphics.newImage("/assets/bomb.png");
	CloudImage = love.graphics.newImage("/assets/cloud.png");

	BirdImage = love.graphics.newImage("/assets/sprite.png");
	BirdsFrames = {};
	for i = 0, 3 do
		table.insert(BirdsFrames, love.graphics.newQuad(i * 20, 0, 20, 20, BirdImage:getWidth(), BirdImage:getHeight()));
	end

	Volume = 0.1;
	love.audio.setVolume(Volume);
end

function StartGame()
	Pipes = {};
	Bombs = {};
	Clouds = {};

	GameState = 1;
	LastBomb = 0;
	LastCloud = 0;
	Velocity = 0;
	Points = 0;
	SPEED = 60;
	N_PIPES = 6;

	WWidth, WHeight = love.graphics.getDimensions();

	Bird = {
		x = 2 / 10 * WWidth,
		y = WHeight / 2,
		width = 20,
		height = 20,
		isPlayer = true,
	};

	for i = 1, N_PIPES, 1 do
		CreatePipe((WWidth * (i / N_PIPES)) - (WWidth / 2));
	end

	CurrentFrame = 1
	LastChangeFrame = love.timer.getTime();
end

function love.update(dt)
	if GameState == 1 then
		ApplyGravity(dt);
		MoveObstacle(dt);
		MoveBird(dt);
		DetectCollision();
		CreateCloud();

		if love.timer.getTime() - LastChangeFrame > 0.2 then
			CurrentFrame = ((CurrentFrame + 1) % 3) + 1;
			LastChangeFrame = love.timer.getTime();
		end
	end
end

function SetColor(r, g, b)
	love.graphics.setColor(love.math.colorFromBytes(r, g, b));
end

function love.draw()
	WWidth, WHeight = love.graphics.getDimensions()
	if (GameState >= 1) then
		SetColor(95, 205, 228);
		love.graphics.rectangle("fill", 0, 0, WWidth, WHeight);


		SetColor(255, 255, 255);
		for _, value in ipairs(Clouds) do
			love.graphics.draw(CloudImage, value.x, value.y, 0, (WWidth / 800), (WWidth / 800), 0, 0);
		end

		if GameState == 2 then
			SetColor(255, 115, 115);
		else
			SetColor(115, 255, 115);
		end

		for _, value in ipairs(Pipes) do
			love.graphics.rectangle("fill", value.x, value.y, value.width, value.height);
			love.graphics.rectangle("fill", value.x, (value.height + value.gap), value.width,
				(WHeight - (value.height + value.gap)));
		end

		SetColor(255, 255, 255);
		for _, value in ipairs(Bombs) do
			love.graphics.draw(BombImage, value.x, value.y, 0, (WWidth / 800), (WWidth / 800), 0, 0);
		end



		SetColor(255, 255, 255);
		-- love.graphics.rectangle("fill", Bird.x, Bird.y, Bird.width * (WWidth / 800),
		-- 	Bird.height * (WWidth / 800));
		love.graphics.draw(BirdImage, BirdsFrames[CurrentFrame], Bird.x, Bird.y, 0, (WWidth / 800), (WWidth / 800), 0,
			0);


		love.graphics.print("Points: " .. Points, 0, 0, 0, 1.3, 1.3);
	end
	if (GameState == 0) then
		SetColor(255, 255, 255);
		love.graphics.rectangle("line", WWidth / 2 - 310 / 2, WHeight / 3 - TitleFont:getHeight() / 2 - 35, 310, 210);
		love.graphics.printf("Enter start a new game\n\nSpace to jump\n\nLeft/Right to Dash\n\nEscape to quit", 0,
			WHeight / 3 - TitleFont:getHeight() / 2, WWidth, "center")
	end
	if (GameState == 2) then
		SetColor(255, 255, 255);
		love.graphics.rectangle("fill", WWidth / 2 - 310 / 2, WHeight / 3 - TitleFont:getHeight() / 2 - 35, 310, 110);
		SetColor(0, 0, 0);
		love.graphics.rectangle("fill", WWidth / 2 - 300 / 2, WHeight / 3 - TitleFont:getHeight() / 2 - 30, 300, 100);
		SetColor(255, 255, 255);
		love.graphics.printf("Game Ended\nPoints: " .. Points .. "\n\nPress Enter ...", 0,
			WHeight / 3 - TitleFont:getHeight() / 2, WWidth, "center")
	end
	if (GameState == 3) then
		SetColor(255, 255, 255);
		love.graphics.rectangle("fill", WWidth / 2 - 310 / 2, WHeight / 3 - TitleFont:getHeight() / 2 - 35, 310, 110);
		SetColor(0, 0, 0);
		love.graphics.rectangle("fill", WWidth / 2 - 300 / 2, WHeight / 3 - TitleFont:getHeight() / 2 - 30, 300, 100);
		SetColor(255, 255, 255);
		love.graphics.printf("You Win\nPoints: " .. Points .. "\n\nPress Enter ...", 0,
			WHeight / 3 - TitleFont:getHeight() / 2, WWidth, "center")
	end

	-- love.graphics.draw(Bird.sprite, BirdsFrames[1], 10, Bird.y);
	-- love.graphics.draw(Bird.sprite, BirdsFrames[2], 50, Bird.y);
end

function love.keypressed(key)
	if (key == "space") then
		if (GameState == 1) and Velocity <= 0 then
			Velocity = 10;
			love.audio.play(SwooshSFX);
		end
	end
	if (key == "return") then
		StartGame()
	end
	if key == "escape" then
		love.event.quit(0);
	end
end

function ApplyGravity(dt)
	WWidth, WHeight = love.graphics.getDimensions()
	if Bird.y < (WHeight - Bird.height) then
		Bird.y = Bird.y + SPEED * dt;
	end
	if Bird.y > (WHeight - Bird.height) then
		GameState = 2;
	end
	for index, value in ipairs(Bombs) do
		if value.y < (WHeight - value.height) then
			value.y = value.y + SPEED * dt;
		end
		if value.y > (WHeight - value.height) then
			table.remove(Bombs, index);
		end
	end
end

function CreatePipe(params)
	WWidth, WHeight = love.graphics.getDimensions()
	table.insert(Pipes, {
		x = WWidth - params,
		y = 0,
		height = WHeight / love.math.random(2, 8),
		width = WWidth / 30,
		gap = love.math.random(GAP, math.max(GAP, WHeight - (60 * Points))),
	})
end

function CreateBomb()
	WWidth, WHeight = love.graphics.getDimensions()
	if love.math.random(0, 6) == 0 and
		love.timer.getTime() - LastBomb > 1
	then
		table.insert(Bombs, {
			x = 4 / 10 * WWidth,
			y = 0,
			height = WWidth / 30,
			width = WWidth / 30,
		})
		LastBomb = love.timer.getTime()
	end
end

function CreateCloud()
	WWidth, WHeight = love.graphics.getDimensions()
	if love.timer.getTime() - LastCloud > 2 then
		table.insert(Clouds, {
			x = WWidth,
			y = love.math.random(0, WHeight),
		})
		LastCloud = love.timer.getTime()
	end
end

function MoveObstacle(dt)
	for index, value in ipairs(Pipes) do
		if value.x >= 0 then
			value.x = value.x - SPEED * dt;
		else
			table.remove(Pipes, index);
			if Points < #Pipes or love.math.random(0, 6) > 0 then
				CreatePipe(0);
			end
			CreateBomb();
			Points = Points + 1;
			love.audio.play(PointSFX);
			SPEED = SPEED + (Points / 10);
		end
	end
	for index, value in ipairs(Bombs) do
		if value.x >= 0 then
			value.x = value.x - SPEED * dt;
		else
			table.remove(Bombs, index);
			Points = Points + 1;
			love.audio.play(PointSFX);
			SPEED = SPEED + (Points / 10);
		end
	end

	for index, value in ipairs(Clouds) do
		if value.x >= 0 then
			value.x = value.x - (2 * SPEED) * dt;
		else
			table.remove(Clouds, index);
		end
	end

	if #Pipes == 0 then
		GameState = 3;
	end
end

function MoveBird(dt)
	if Velocity > 0 then
		Bird.y = Bird.y - JUMP * dt * Velocity;
		Velocity = Velocity - 1;
	end
end

function DetectCollision()
	for _, value in ipairs(Pipes) do
		if Bird.x >= value.x and Bird.x + Bird.width <= value.x + value.width and
			Bird.y >= value.y and Bird.y + Bird.height <= value.y + value.height or
			Bird.x >= value.x and Bird.x + Bird.width <= value.x + value.width and
			Bird.y >= (value.height + value.gap) and Bird.y + Bird.height <= ((value.height + value.gap) + (WHeight - (value.height + value.gap)))
		then
			GameState = 2;
		end
	end
	for _, value in ipairs(Bombs) do
		if Bird.x >= value.x and Bird.x + Bird.width <= value.x + value.width and
			Bird.y >= value.y and Bird.y + Bird.height <= value.y + value.height
		then
			GameState = 2;
		end
	end
end
