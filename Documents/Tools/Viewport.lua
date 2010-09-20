
require "vmath"

module(..., package.seeall);

local function AddMembers(classInst, members)
	for funcName, func in pairs(members) do
		classInst[funcName] = func;
	end
end


--2D Viewport.
local View2D = {}

function View2D:Size()
	return self.pixelSize;
end

--Takes points in viewport space, returns points in pixel space.
function View2D:Transform(points)
	if(vmath.vtype(points) == "table") then
		local ret = {};
		for i, realPoint in ipairs(points) do
			ret[i] = self:Transform(realPoint);
		end
		return ret;
	end
	
	local point = vmath.vec2(points);
	if(self.transform) then point = self.transform:Matrix():Transform(point) end;
	
	point = point / self.vpSize;
	point = point * vmath.vec2(1, -1);
	point = point * self.pixelSize;
	point = point + self.pxOrigin;
	
	return point;
end

function View2D:SetTransform(transform)
	self.transform = transform;
end


-- 3D Viewport
local View3D = {}

function View3D:Size()
	return self.pixelSize;
end

--Takes points in 3D viewport space, returns points in 2D pixel space.
function View3D:Transform(points)
	if(vmath.vtype(points) == "table") then
		local ret = {};
		for i, realPoint in ipairs(points) do
			ret[i] = self:Transform(realPoint);
		end
		return ret;
	end
	
	local point = vmath.vec3(points);
	if(self.transform) then point = self.transform:Matrix():Transform(point) end;
	
	point = point / self.vpSize;
	point = point * vmath.vec2(1, -1);
	point = point * self.pixelSize;
	point = point + self.pxOrigin;
	
	return vmath.vec2(point);
end

function View3D:SetTransform(transform)
	self.transform = transform;
end



-- Transform 2D.
local function Identity3()
	return vmath.mat3(vmath.vec3{1, 0, 0}, vmath.vec3{0, 1, 0}, vmath.vec3{0, 0, 1});
end

local Trans2D = {}

function Trans2D:Translate(offset)
	local trans = Identity3();
	trans:SetCol(3, vmath.vec3(offset, 1));
	self.currMatrix = self.currMatrix * trans;
end

function Trans2D:Scale(scale)
	local scaleMat = Identity3();
	scaleMat[1][1] = scale[1];
	scaleMat[2][2] = scale[2];
	self.currMatrix = self.currMatrix * scaleMat;
end

function Trans2D:Rotate(angleDeg)
	local rotation = Identity3();
	angleDeg = math.rad(angleDeg);
	local sinAng, cosAng = math.sin(angleDeg), math.cos(angleDeg);
	
	rotation[1][1] = cosAng; rotation[2][1] = -sinAng;
	rotation[1][2] = sinAng; rotation[2][2] = cosAng;
	
	self.currMatrix = self.currMatrix * rotation;
end

function Trans2D:Push()
	if(not self.stack) then
		self.stack = {};
		self.stack.top = 0;
	end
	
	self.stack[self.stack.top + 1] = self.currMatrix;
	self.stack.top = self.stack.top + 1;
end

function Trans2D:Pop()
	assert(self.stack, "No Push has been called yet.");
	assert(self.stack.top > 0, "Matrix stack underflow.");
	self.currMatrix = self.stack[self.stack.top];
	self.stack.top = self.stack.top - 1;
end

function Trans2D:Identity()
	self.currMatrix = Identity3();
end

function Trans2D:Matrix()
	return self.currMatrix;
end


-- Transform 3D.
local function Identity4()
	return vmath.mat4(
		vmath.vec4{1, 0, 0, 0},
		vmath.vec4{0, 1, 0, 0},
		vmath.vec3{0, 0, 1, 0},
		vmath.vec3{0, 0, 0, 1});
end

local Trans3D = {}

Trans3D.Push = Trans2D.Push;
Trans3D.Pop = Trans2D.Pop;

function Trans3D:Translate(offset)
	local trans = Identity4();
	trans:SetCol(4, vmath.vec4(offset, 1));
	self.currMatrix = self.currMatrix * trans;
end

function Trans3D:Scale(scale)
	local scaleMat = Identity4();
	scaleMat[1][1] = scale[1];
	scaleMat[2][2] = scale[2];
	scaleMat[3][3] = scale[3];
	self.currMatrix = self.currMatrix * scaleMat;
end

function Trans3D:RotateX(angleDeg)
	local rotation = Identity4();
	angleDeg = math.rad(angleDeg);
	local sinAng, cosAng = math.sin(angleDeg), math.cos(angleDeg);
	
	rotation[2][2] = cosAng; rotation[3][2] = -sinAng;
	rotation[2][3] = sinAng; rotation[3][3] = cosAng;
	
	self.currMatrix = self.currMatrix * rotation;
end

function Trans3D:RotateY(angleDeg)
	local rotation = Identity4();
	angleDeg = math.rad(angleDeg);
	local sinAng, cosAng = math.sin(angleDeg), math.cos(angleDeg);
	
	rotation[1][1] = cosAng; rotation[3][1] = sinAng;
	rotation[1][3] = -sinAng; rotation[3][3] = cosAng;
	
	self.currMatrix = self.currMatrix * rotation;
end

function Trans3D:RotateZ(angleDeg)
	local rotation = Identity4();
	angleDeg = math.rad(angleDeg);
	local sinAng, cosAng = math.sin(angleDeg), math.cos(angleDeg);
	
	rotation[1][1] = cosAng; rotation[2][1] = -sinAng;
	rotation[1][2] = sinAng; rotation[2][2] = cosAng;
	
	self.currMatrix = self.currMatrix * rotation;
end

function Trans3D:Identity()
	self.currMatrix = Identity4();
end

function Trans3D:Matrix()
	return self.currMatrix;
end



function Transform2D()
	local transform = {};
	transform.currMatrix = Identity3();
	AddMembers(transform, Trans2D);
	return transform;
end

function Transform3D()
	local transform = {};
	transform.currMatrix = Identity4();
	AddMembers(transform, Trans3D);
	return transform;
end


function Viewport2D(pixelSize, pxOrigin, vpSize)
	local viewport = {};
	
	viewport.pixelSize = vmath.vec2(pixelSize);
	viewport.pxOrigin = vmath.vec2(pxOrigin);
	if(type(vpSize) == "number") then vpSize = vmath.vec2(vpSize, vpSize) end;
	viewport.vpSize = vmath.vec2(vpSize);
	
	AddMembers(viewport, View2D);
	return viewport;
end

function Viewport3D(pixelSize, vpOrigin, vpScale)
	local viewport = {};
	
	viewport.pixelSize = vmath.vec2(pixelSize);
	viewport.vpOrigin = vmath.vec3(vpOrigin);
	if(type(vpScale) == "number") then vpSize = vmath.vec3(vpSize, vpSize, vpSize) end;
	viewport.vpScale = vmath.vec3(vpSize);
	
	AddMembers(viewport, View3D);
	return viewport;
end
